str_tex_proc = """
//	<https://www.shadertoy.com/view/4dS3Wd>
//	By Morgan McGuire @morgan3d, http://graphicscodex.com
float hash_f(const float n) { return fract(sin(n) * 1e4); }
float hash_f(const vec2 p) { return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }
float hash_f(const vec3 co){ return fract(sin(dot(co.xyz, vec3(12.9898,78.233,52.8265)) * 24.384) * 43758.5453); }

float noise(const vec3 x) {
	const vec3 step = vec3(110, 241, 171);

	vec3 i = floor(x);
	vec3 f = fract(x);
 
	// For performance, compute the base input to a 1D hash from the integer part of the argument and the 
	// incremental change to the 1D based on the 3D -> 1D wrapping
    float n = dot(i, step);

	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix( hash_f(n + dot(step, vec3(0, 0, 0))), hash_f(n + dot(step, vec3(1, 0, 0))), u.x),
                   mix( hash_f(n + dot(step, vec3(0, 1, 0))), hash_f(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
               mix(mix( hash_f(n + dot(step, vec3(0, 0, 1))), hash_f(n + dot(step, vec3(1, 0, 1))), u.x),
                   mix( hash_f(n + dot(step, vec3(0, 1, 1))), hash_f(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
}

//  Shader-code adapted from Blender
//  https://github.com/sobotka/blender/blob/master/source/blender/gpu/shaders/material/gpu_shader_material_tex_wave.glsl & /gpu_shader_material_fractal_noise.glsl
float fractal_noise(const vec3 p, const float o, const float r)
{
  float fscale = 1.0;
  float amp = 1.0;
  float sum = 0.0;
  float octaves = clamp(o, 0.0, 16.0);
  int n = int(octaves);
  
  for (int i = 0; i <= n; i++) {
    float t = noise(fscale * p);
    sum += t * amp;
    amp *= r; 
    fscale *= 2.0;
  }
  
  float rmd = octaves - floor(octaves);
  if (rmd != 0.0) {
    float t = noise(fscale * p);
    float sum2 = sum + t * amp;
    
    float max_amp1 = (1.0 - pow(r, float(n + 1))) / (1.0 - r);
    float max_amp2 = (1.0 - pow(r, float(n + 2))) / (1.0 - r);
    
    if (abs(r - 1.0) < 0.0001) {
        max_amp1 = float(n + 1);
        max_amp2 = float(n + 2);
    }

    sum /= max_amp1;
    sum2 /= max_amp2;
    
    return (1.0 - rmd) * sum + rmd * sum2;
  }
  else {
    float max_amp = (1.0 - pow(r, float(n + 1))) / (1.0 - r);
    if (abs(r - 1.0) < 0.0001) max_amp = float(n + 1);
    
    sum /= max_amp;
    return sum;
  }
}
"""

str_tex_checker = """
vec3 tex_checker(const vec3 co, const vec3 col1, const vec3 col2, const float scale) {
    // Prevent precision issues on unit coordinates
    vec3 p = (co + 0.000001 * 0.999999) * scale;
    float xi = abs(floor(p.x));
    float yi = abs(floor(p.y));
    float zi = abs(floor(p.z));
    bool check = ((mod(xi, 2.0) == mod(yi, 2.0)) == bool(mod(zi, 2.0)));
    return check ? col1 : col2;
}
float tex_checker_f(const vec3 co, const float scale) {
    vec3 p = (co + 0.000001 * 0.999999) * scale;
    float xi = abs(floor(p.x));
    float yi = abs(floor(p.y));
    float zi = abs(floor(p.z));
    return float((mod(xi, 2.0) == mod(yi, 2.0)) == bool(mod(zi, 2.0)));
}
"""

str_tex_voronoi = """
/* SPDX-FileCopyrightText: 2013 Inigo Quilez
 * SPDX-FileCopyrightText: 2019-2023 Blender Authors
 *
 * SPDX-License-Identifier: MIT AND GPL-2.0-or-later */

/*
 * Smooth Voronoi:
 *
 * - https://wiki.blender.org/wiki/User:OmarSquircleArt/GSoC2019/Documentation/Smooth_Voronoi
 *
 * Distance To Edge based on:
 *
 * - https://www.iquilezles.org/www/articles/voronoilines/voronoilines.htm
 * - https://www.shadertoy.com/view/ldl3W8
 *
 * With optimization to change -2..2 scan window to -1..1 for better performance,
 * as explained in https://www.shadertoy.com/view/llG3zy.
 */

#define SHD_VORONOI_EUCLIDEAN 0
#define SHD_VORONOI_MANHATTAN 1
#define SHD_VORONOI_CHEBYCHEV 2
#define SHD_VORONOI_MINKOWSKI 3

#define SHD_VORONOI_F1 0
#define SHD_VORONOI_F2 1
#define SHD_VORONOI_SMOOTH_F1 2
#define SHD_VORONOI_DISTANCE_TO_EDGE 3
#define SHD_VORONOI_N_SPHERE_RADIUS 4

struct VoronoiParams {
  float scale;
  float detail;
  float roughness;
  float lacunarity;
  float smoothness;
  float exponent;
  float randomness;
  float max_distance;
  bool normalize;
  int feature;
  int metric;
};

struct VoronoiOutput {
  float Distance;
  vec3 Color;
  vec4 Position;
};

/* **** Distance Functions **** */

float voronoi_distance(vec3 a, vec3 b, VoronoiParams params)
{
  if (params.metric == SHD_VORONOI_EUCLIDEAN) {
    return distance(a, b);
  }
  else if (params.metric == SHD_VORONOI_MANHATTAN) {
    return abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z);
  }
  else if (params.metric == SHD_VORONOI_CHEBYCHEV) {
    return max(abs(a.x - b.x), max(abs(a.y - b.y), abs(a.z - b.z)));
  }
  else if (params.metric == SHD_VORONOI_MINKOWSKI) {
    return pow(pow(abs(a.x - b.x), params.exponent) + pow(abs(a.y - b.y), params.exponent) +
                   pow(abs(a.z - b.z), params.exponent),
               1.0 / params.exponent);
  }
  else {
    return 0.0;
  }
}

/* **** 3D Voronoi **** */

vec4 voronoi_position(vec3 coord)
{
  return vec4(coord.x, coord.y, coord.z, 0.0);
}

VoronoiOutput voronoi_f1(VoronoiParams params, vec3 coord)
{
  vec3 cellPosition_f = floor(coord);
  vec3 localPosition = coord - cellPosition_f;

  float minDistance = 8.0;
  vec3 targetOffset = vec3(0.0);
  vec3 targetPosition = vec3(0.0);
  for (int k = -1; k <= 1; k++) {
    for (int j = -1; j <= 1; j++) {
      for (int i = -1; i <= 1; i++) {
        vec3 cellOffset = vec3(float(i), float(j), float(k));
        vec3 pointPosition = cellOffset +
                               vec3(hash_f(cellPosition_f + cellOffset), hash_f(cellPosition_f + cellOffset + 972.37), hash_f(cellPosition_f + cellOffset + 342.48)) * params.randomness;
        float distanceToPoint = voronoi_distance(pointPosition, localPosition, params);
        if (distanceToPoint < minDistance) {
          targetOffset = cellOffset;
          minDistance = distanceToPoint;
          targetPosition = pointPosition;
        }
      }
    }
  }

  VoronoiOutput octave;
  octave.Distance = minDistance;
  octave.Color = vec3(hash_f(cellPosition_f + targetOffset), hash_f(cellPosition_f + targetOffset + 972.37), hash_f(cellPosition_f + targetOffset + 342.48));
  octave.Position = voronoi_position(targetPosition + cellPosition_f);
  return octave;
}

VoronoiOutput voronoi_smooth_f1(VoronoiParams params, vec3 coord)
{
  vec3 cellPosition_f = floor(coord);
  vec3 localPosition = coord - cellPosition_f;

  float smoothDistance = 0.0;
  vec3 smoothColor = vec3(0.0);
  vec3 smoothPosition = vec3(0.0);
  float h = -1.0;
  for (int k = -2; k <= 2; k++) {
    for (int j = -2; j <= 2; j++) {
      for (int i = -2; i <= 2; i++) {
        vec3 cellOffset = vec3(float(i), float(j), float(k));
        vec3 pointPosition = cellOffset +
                               vec3(hash_f(cellPosition_f + cellOffset), hash_f(cellPosition_f + cellOffset + 972.37), hash_f(cellPosition_f + cellOffset + 342.48)) * params.randomness;
        float distanceToPoint = voronoi_distance(pointPosition, localPosition, params);
        h = h == -1.0 ?
                1.0 :
                smoothstep(0.0,
                           1.0,
                           0.5 + 0.5 * (smoothDistance - distanceToPoint) / params.smoothness);
        float correctionFactor = params.smoothness * h * (1.0 - h);
        smoothDistance = mix(smoothDistance, distanceToPoint, h) - correctionFactor;
        correctionFactor /= 1.0 + 3.0 * params.smoothness;
        vec3 cellColor = vec3(hash_f(cellPosition_f + cellOffset), hash_f(cellPosition_f + cellOffset + 972.37), hash_f(cellPosition_f + cellOffset + 342.48));
        smoothColor = mix(smoothColor, cellColor, h) - correctionFactor;
        smoothPosition = mix(smoothPosition, pointPosition, h) - correctionFactor;
      }
    }
  }

  VoronoiOutput octave;
  octave.Distance = smoothDistance;
  octave.Color = smoothColor;
  octave.Position = voronoi_position(cellPosition_f + smoothPosition);
  return octave;
}

VoronoiOutput voronoi_f2(VoronoiParams params, vec3 coord)
{
  vec3 cellPosition_f = floor(coord);
  vec3 localPosition = coord - cellPosition_f;

  float distanceF1 = 8.0;
  float distanceF2 = 8.0;
  vec3 offsetF1 = vec3(0.0);
  vec3 positionF1 = vec3(0.0);
  vec3 offsetF2 = vec3(0.0);
  vec3 positionF2 = vec3(0.0);
  for (int k = -1; k <= 1; k++) {
    for (int j = -1; j <= 1; j++) {
      for (int i = -1; i <= 1; i++) {
        vec3 cellOffset = vec3(float(i), float(j), float(k));
        vec3 pointPosition = cellOffset +
                               vec3(hash_f(cellPosition_f + cellOffset), hash_f(cellPosition_f + cellOffset + 972.37), hash_f(cellPosition_f + cellOffset + 342.48)) * params.randomness;
        float distanceToPoint = voronoi_distance(pointPosition, localPosition, params);
        if (distanceToPoint < distanceF1) {
          distanceF2 = distanceF1;
          distanceF1 = distanceToPoint;
          offsetF2 = offsetF1;
          offsetF1 = cellOffset;
          positionF2 = positionF1;
          positionF1 = pointPosition;
        }
        else if (distanceToPoint < distanceF2) {
          distanceF2 = distanceToPoint;
          offsetF2 = cellOffset;
          positionF2 = pointPosition;
        }
      }
    }
  }

  VoronoiOutput octave;
  octave.Distance = distanceF2;
  octave.Color = vec3(hash_f(cellPosition_f + offsetF2), hash_f(cellPosition_f + offsetF2 + 972.37), hash_f(cellPosition_f + offsetF2 + 342.48));
  octave.Position = voronoi_position(positionF2 + cellPosition_f);
  return octave;
}

float voronoi_distance_to_edge(VoronoiParams params, vec3 coord)
{
  vec3 cellPosition_f = floor(coord);
  vec3 localPosition = coord - cellPosition_f;

  vec3 vectorToClosest = vec3(0.0);
  float minDistance = 8.0;
  for (int k = -1; k <= 1; k++) {
    for (int j = -1; j <= 1; j++) {
      for (int i = -1; i <= 1; i++) {
        vec3 cellOffset = vec3(float(i), float(j), float(k));
        vec3 vectorToPoint = cellOffset +
                               vec3(hash_f(cellPosition_f + cellOffset), hash_f(cellPosition_f + cellOffset + 972.37), hash_f(cellPosition_f + cellOffset + 342.48)) * params.randomness -
                               localPosition;
        float distanceToPoint = dot(vectorToPoint, vectorToPoint);
        if (distanceToPoint < minDistance) {
          minDistance = distanceToPoint;
          vectorToClosest = vectorToPoint;
        }
      }
    }
  }

  minDistance = 8.0;
  for (int k = -1; k <= 1; k++) {
    for (int j = -1; j <= 1; j++) {
      for (int i = -1; i <= 1; i++) {
        vec3 cellOffset = vec3(float(i), float(j), float(k));
        vec3 vectorToPoint = cellOffset +
                               vec3(hash_f(cellPosition_f + cellOffset), hash_f(cellPosition_f + cellOffset + 972.37), hash_f(cellPosition_f + cellOffset + 342.48)) * params.randomness -
                               localPosition;
        vec3 perpendicularToEdge = vectorToPoint - vectorToClosest;
        if (dot(perpendicularToEdge, perpendicularToEdge) > 0.0001) {
          float distanceToEdge = dot((vectorToClosest + vectorToPoint) / 2.0,
                                     normalize(perpendicularToEdge));
          minDistance = min(minDistance, distanceToEdge);
        }
      }
    }
  }

  return minDistance;
}

float voronoi_n_sphere_radius(VoronoiParams params, vec3 coord)
{
  vec3 cellPosition_f = floor(coord);
  vec3 localPosition = coord - cellPosition_f;

  vec3 closestPoint = vec3(0.0);
  vec3 closestPointOffset = vec3(0.0);
  float minDistance = 8.0;
  for (int k = -1; k <= 1; k++) {
    for (int j = -1; j <= 1; j++) {
      for (int i = -1; i <= 1; i++) {
        vec3 cellOffset = vec3(float(i), float(j), float(k));
        vec3 pointPosition = cellOffset +
                               vec3(hash_f(cellPosition_f + cellOffset), hash_f(cellPosition_f + cellOffset + 972.37), hash_f(cellPosition_f + cellOffset + 342.48)) * params.randomness;
        float distanceToPoint = distance(pointPosition, localPosition);
        if (distanceToPoint < minDistance) {
          minDistance = distanceToPoint;
          closestPoint = pointPosition;
          closestPointOffset = cellOffset;
        }
      }
    }
  }

  minDistance = 8.0;
  vec3 closestPointToClosestPoint = vec3(0.0);
  for (int k = -1; k <= 1; k++) {
    for (int j = -1; j <= 1; j++) {
      for (int i = -1; i <= 1; i++) {
        if (i == 0 && j == 0 && k == 0) {
          continue;
        }
        vec3 cellOffset = vec3(float(i), float(j), float(k)) + closestPointOffset;
        vec3 pointPosition = cellOffset +
                               vec3(hash_f(cellPosition_f + cellOffset), hash_f(cellPosition_f + cellOffset + 972.37), hash_f(cellPosition_f + cellOffset + 342.48)) * params.randomness;
        float distanceToPoint = distance(closestPoint, pointPosition);
        if (distanceToPoint < minDistance) {
          minDistance = distanceToPoint;
          closestPointToClosestPoint = pointPosition;
        }
      }
    }
  }

  return distance(closestPointToClosestPoint, closestPoint) / 2.0;
}

/* The fractalization logic is the same as for fBM Noise, except that some additions are replaced
 * by lerps. */
float fractal_voronoi_distance_to_edge(VoronoiParams params, vec3 coord)
{
  float amplitude = 1.0;
  float max_amplitude = params.max_distance;
  float scale = 1.0;
  float dist = 8.0;

  bool zero_input = params.detail == 0.0 || params.roughness == 0.0;

  for (int i = 0; i <= int(ceil(params.detail)); ++i) {
    float octave_distance = voronoi_distance_to_edge(params, coord * scale);

    if (zero_input) {
      dist = octave_distance;
      break;
    }
    else if (float(i) <= params.detail) {
      max_amplitude = mix(max_amplitude, params.max_distance / scale, amplitude);
      dist = mix(dist, min(dist, octave_distance / scale), amplitude);
      scale *= params.lacunarity;
      amplitude *= params.roughness;
    }
    else {
      float remainder = params.detail - floor(params.detail);
      if (remainder != 0.0) {
        float lerp_amplitude = mix(max_amplitude, params.max_distance / scale, amplitude);
        max_amplitude = mix(max_amplitude, lerp_amplitude, remainder);
        float lerp_distance = mix(dist, min(dist, octave_distance / scale), amplitude);
        dist = mix(dist, min(dist, lerp_distance), remainder);
      }
    }
  }

  if (params.normalize) {
    dist /= max_amplitude;
  }

  return dist;
}

/* The fractalization logic is the same as for fBM Noise, except that some additions are replaced
 * by lerps. */
VoronoiOutput fractal_voronoi_3d(VoronoiParams params, vec3 coord)
{
  float amplitude = 1.0;
  float max_amplitude = 0.0;
  float scale = 1.0;

  VoronoiOutput Output;
  Output.Distance = 0.0;
  Output.Color = vec3(0.0, 0.0, 0.0);
  Output.Position = vec4(0.0, 0.0, 0.0, 0.0);
  bool zero_input = params.detail == 0.0 || params.roughness == 0.0;

  for (int i = 0; i <= int(ceil(params.detail)); ++i) {
    VoronoiOutput octave;
    if (params.feature == SHD_VORONOI_F2) {
      octave = voronoi_f2(params, coord * scale);
    }
    else if (params.feature == SHD_VORONOI_SMOOTH_F1 && params.smoothness != 0.0) {
      octave = voronoi_smooth_f1(params, coord * scale);
    }
    else {
      octave = voronoi_f1(params, coord * scale);
    }

    if (zero_input) {
      max_amplitude = 1.0;
      Output = octave;
      break;
    }
    else if (float(i) <= params.detail) {
      max_amplitude += amplitude;
      Output.Distance += octave.Distance * amplitude;
      Output.Color += octave.Color * amplitude;
      Output.Position = mix(Output.Position, octave.Position / scale, amplitude);
      scale *= params.lacunarity;
      amplitude *= params.roughness;
    }
    else {
      float remainder = params.detail - floor(params.detail);
      if (remainder != 0.0) {
        max_amplitude = mix(max_amplitude, max_amplitude + amplitude, remainder);
        Output.Distance = mix(
            Output.Distance, Output.Distance + octave.Distance * amplitude, remainder);
        Output.Color = mix(Output.Color, Output.Color + octave.Color * amplitude, remainder);
        Output.Position = mix(
            Output.Position, mix(Output.Position, octave.Position / scale, amplitude), remainder);
      }
    }
  }

  if (params.normalize) {
    Output.Distance /= max_amplitude * params.max_distance;
    Output.Color /= max_amplitude;
  }

  Output.Position = Output.Position / params.scale;

  return Output;
}

vec3 tex_voronoi_3d(vec3 coord, float randomness, int metric, int outp, float scale, float exp, float w, float detail, float roughness, float lacunarity, float smoothness, int feature, int normalize)
{
  VoronoiParams params;
  params.feature = feature;
  params.metric = metric;
  params.scale = scale;
  params.detail = clamp(detail, 0.0, 15.0);
  params.roughness = clamp(roughness, 0.0, 1.0);
  params.lacunarity = lacunarity;
  params.smoothness = clamp(smoothness / 2.0, 0.0, 0.5);
  params.exponent = exp;
  params.randomness = clamp(randomness, 0.0, 1.0);
  
  if (feature == SHD_VORONOI_F2) {
      params.max_distance = (0.5 + 0.5 * params.randomness) * 2.0;
  } else {
      params.max_distance = 0.5 + 0.5 * params.randomness;
  }
  
  params.normalize = normalize == 1;

  vec3 scaledCoord = coord * scale;

  if (feature == SHD_VORONOI_DISTANCE_TO_EDGE) {
      float dist = fractal_voronoi_distance_to_edge(params, scaledCoord);
      if (outp == 0) return vec3(dist);
      return vec3(0.0);
  } 
  else if (feature == SHD_VORONOI_N_SPHERE_RADIUS) {
      float radius = voronoi_n_sphere_radius(params, scaledCoord);
      if (outp == 0) return vec3(radius);
      return vec3(0.0);
  } 
  else {
      VoronoiOutput Output = fractal_voronoi_3d(params, scaledCoord);
      if (outp == 0) return vec3(Output.Distance);
      else if (outp == 1) return Output.Color;
      return Output.Position.xyz;
  }
}

vec3 tex_voronoi_1d(vec3 coord, float randomness, int metric, int outp, float scale, float exp, float w, float detail, float roughness, float lacunarity, float smoothness, int feature, int normalize) {
  return tex_voronoi_3d(vec3(w, 0.0, 0.0), randomness, metric, outp, scale, exp, 0.0, detail, roughness, lacunarity, smoothness, feature, normalize);
}

vec3 tex_voronoi_2d(vec3 coord, float randomness, int metric, int outp, float scale, float exp, float w, float detail, float roughness, float lacunarity, float smoothness, int feature, int normalize) {
  return tex_voronoi_3d(vec3(coord.x, coord.y, 0.0), randomness, metric, outp, scale, exp, 0.0, detail, roughness, lacunarity, smoothness, feature, normalize);
}

vec3 tex_voronoi_4d(vec3 coord, float randomness, int metric, int outp, float scale, float exp, float w, float detail, float roughness, float lacunarity, float smoothness, int feature, int normalize) {
  return tex_voronoi_3d(coord, randomness, metric, outp, scale, exp, w, detail, roughness, lacunarity, smoothness, feature, normalize);
}
"""

str_tex_noise = """
//https://github.com/blender/blender/blob/main/source/blender/gpu/shaders/material/gpu_shader_material_tex_noise.glsl
uint rot(uint x, int k) {
    return (x << k) | (x >> (32 - k));
}

void mix_hash(inout uint a, inout uint b, inout uint c) {
    a -= c; a ^= rot(c, 4); c += b;
    b -= a; b ^= rot(a, 6); a += c;
    c -= b; c ^= rot(b, 8); b += a;
    a -= c; a ^= rot(c, 16); c += b;
    b -= a; b ^= rot(a, 19); a += c;
    c -= b; c ^= rot(b, 4); b += a;
}

void final_hash(inout uint a, inout uint b, inout uint c) {
    c ^= b; c -= rot(b, 14);
    a ^= c; a -= rot(c, 11);
    b ^= a; b -= rot(a, 25);
    c ^= b; c -= rot(b, 16);
    a ^= c; a -= rot(c, 4);
    b ^= a; b -= rot(a, 14);
    c ^= b; c -= rot(b, 24);
}

uint hash_uint(uint kx) {
    uint a = 0xdeadbeefu + 17u + kx;
    uint b = 0xdeadbeefu + 17u;
    uint c = 0xdeadbeefu + 17u;
    final_hash(a, b, c);
    return c;
}

uint hash_uint2(uint kx, uint ky) {
    uint a = 0xdeadbeefu + 21u + kx;
    uint b = 0xdeadbeefu + 21u + ky;
    uint c = 0xdeadbeefu + 21u;
    final_hash(a, b, c);
    return c;
}

uint hash_uint3(uint kx, uint ky, uint kz) {
    uint a = 0xdeadbeefu + 25u + kx;
    uint b = 0xdeadbeefu + 25u + ky;
    uint c = 0xdeadbeefu + 25u + kz;
    final_hash(a, b, c);
    return c;
}

uint hash_uint4(uint kx, uint ky, uint kz, uint kw) {
    uint a = 0xdeadbeefu + 29u + kx;
    uint b = 0xdeadbeefu + 29u + ky;
    uint c = 0xdeadbeefu + 29u + kz;
    mix_hash(a, b, c);
    a += kw;
    final_hash(a, b, c);
    return c;
}

float hash_float_to_float(float k) {
    return float(hash_uint(floatBitsToUint(k))) / 4294967295.0;
}

float hash_vec2_to_float(vec2 k) {
    return float(hash_uint2(floatBitsToUint(k.x), floatBitsToUint(k.y))) / 4294967295.0;
}

float hash_vec3_to_float(vec3 k) {
    return float(hash_uint3(floatBitsToUint(k.x), floatBitsToUint(k.y), floatBitsToUint(k.z))) / 4294967295.0;
}

float hash_vec4_to_float(vec4 k) {
    return float(hash_uint4(floatBitsToUint(k.x), floatBitsToUint(k.y), floatBitsToUint(k.z), floatBitsToUint(k.w))) / 4294967295.0;
}

float fade(float t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float negate_if(float val, uint cond) {
    return (cond != 0u) ? -val : val;
}

float noise_grad(uint hash, float x) {
    uint h = hash & 15u;
    float g = 1.0 + float(h & 7u);
    return negate_if(g, h & 8u) * x;
}

float noise_grad(uint hash, float x, float y) {
    uint h = hash & 7u;
    float u = h < 4u ? x : y;
    float v = 2.0 * (h < 4u ? y : x);
    return negate_if(u, h & 1u) + negate_if(v, h & 2u);
}

float noise_grad(uint hash, float x, float y, float z) {
    uint h = hash & 15u;
    float u = h < 8u ? x : y;
    float vt = ((h == 12u) || (h == 14u)) ? x : z;
    float v = h < 4u ? y : vt;
    return negate_if(u, h & 1u) + negate_if(v, h & 2u);
}

float noise_grad(uint hash, float x, float y, float z, float w) {
    uint h = hash & 31u;
    float u = h < 24u ? x : y;
    float v = h < 16u ? y : z;
    float s = h < 8u ? z : w;
    return negate_if(u, h & 1u) + negate_if(v, h & 2u) + negate_if(s, h & 4u);
}

float noise_perlin(float x) {
    float x_floor = floor(x);
    int X = int(x_floor);
    float fx = x - x_floor;
    float u = fade(fx);
    return mix(noise_grad(hash_uint(uint(X)), fx), noise_grad(hash_uint(uint(X + 1)), fx - 1.0), u);
}

float noise_perlin(vec2 vec) {
    vec2 vec_floor = floor(vec);
    ivec2 I = ivec2(vec_floor);
    vec2 f = vec - vec_floor;
    vec2 u = vec2(fade(f.x), fade(f.y));
    float v00 = noise_grad(hash_uint2(uint(I.x), uint(I.y)), f.x, f.y);
    float v10 = noise_grad(hash_uint2(uint(I.x + 1), uint(I.y)), f.x - 1.0, f.y);
    float v01 = noise_grad(hash_uint2(uint(I.x), uint(I.y + 1)), f.x, f.y - 1.0);
    float v11 = noise_grad(hash_uint2(uint(I.x + 1), uint(I.y + 1)), f.x - 1.0, f.y - 1.0);
    return mix(mix(v00, v10, u.x), mix(v01, v11, u.x), u.y);
}

float noise_perlin(vec3 vec) {
    vec3 vec_floor = floor(vec);
    ivec3 I = ivec3(vec_floor);
    vec3 f = vec - vec_floor;
    vec3 u = vec3(fade(f.x), fade(f.y), fade(f.z));
    float v000 = noise_grad(hash_uint3(uint(I.x), uint(I.y), uint(I.z)), f.x, f.y, f.z);
    float v100 = noise_grad(hash_uint3(uint(I.x + 1), uint(I.y), uint(I.z)), f.x - 1.0, f.y, f.z);
    float v010 = noise_grad(hash_uint3(uint(I.x), uint(I.y + 1), uint(I.z)), f.x, f.y - 1.0, f.z);
    float v110 = noise_grad(hash_uint3(uint(I.x + 1), uint(I.y + 1), uint(I.z)), f.x - 1.0, f.y - 1.0, f.z);
    float v001 = noise_grad(hash_uint3(uint(I.x), uint(I.y), uint(I.z + 1)), f.x, f.y, f.z - 1.0);
    float v101 = noise_grad(hash_uint3(uint(I.x + 1), uint(I.y), uint(I.z + 1)), f.x - 1.0, f.y, f.z - 1.0);
    float v011 = noise_grad(hash_uint3(uint(I.x), uint(I.y + 1), uint(I.z + 1)), f.x, f.y - 1.0, f.z - 1.0);
    float v111 = noise_grad(hash_uint3(uint(I.x + 1), uint(I.y + 1), uint(I.z + 1)), f.x - 1.0, f.y - 1.0, f.z - 1.0);
    return mix(mix(mix(v000, v100, u.x), mix(v010, v110, u.x), u.y), mix(mix(v001, v101, u.x), mix(v011, v111, u.x), u.y), u.z);
}

float noise_perlin(vec4 vec) {
    vec4 vec_floor = floor(vec);
    ivec4 I = ivec4(vec_floor);
    vec4 f = vec - vec_floor;
    vec4 u = vec4(fade(f.x), fade(f.y), fade(f.z), fade(f.w));
    float v0 = mix(mix(mix(noise_grad(hash_uint4(uint(I.x), uint(I.y), uint(I.z), uint(I.w)), f.x, f.y, f.z, f.w), noise_grad(hash_uint4(uint(I.x + 1), uint(I.y), uint(I.z), uint(I.w)), f.x - 1.0, f.y, f.z, f.w), u.x), mix(noise_grad(hash_uint4(uint(I.x), uint(I.y + 1), uint(I.z), uint(I.w)), f.x, f.y - 1.0, f.z, f.w), noise_grad(hash_uint4(uint(I.x + 1), uint(I.y + 1), uint(I.z), uint(I.w)), f.x - 1.0, f.y - 1.0, f.z, f.w), u.x), u.y), mix(mix(noise_grad(hash_uint4(uint(I.x), uint(I.y), uint(I.z + 1), uint(I.w)), f.x, f.y, f.z - 1.0, f.w), noise_grad(hash_uint4(uint(I.x + 1), uint(I.y), uint(I.z + 1), uint(I.w)), f.x - 1.0, f.y, f.z - 1.0, f.w), u.x), mix(noise_grad(hash_uint4(uint(I.x), uint(I.y + 1), uint(I.z + 1), uint(I.w)), f.x, f.y - 1.0, f.z - 1.0, f.w), noise_grad(hash_uint4(uint(I.x + 1), uint(I.y + 1), uint(I.z + 1), uint(I.w)), f.x - 1.0, f.y - 1.0, f.z - 1.0, f.w), u.x), u.y), u.z);
    float v1 = mix(mix(mix(noise_grad(hash_uint4(uint(I.x), uint(I.y), uint(I.z), uint(I.w + 1)), f.x, f.y, f.z, f.w - 1.0), noise_grad(hash_uint4(uint(I.x + 1), uint(I.y), uint(I.z), uint(I.w + 1)), f.x - 1.0, f.y, f.z, f.w - 1.0), u.x), mix(noise_grad(hash_uint4(uint(I.x), uint(I.y + 1), uint(I.z), uint(I.w + 1)), f.x, f.y - 1.0, f.z, f.w - 1.0), noise_grad(hash_uint4(uint(I.x + 1), uint(I.y + 1), uint(I.z), uint(I.w + 1)), f.x - 1.0, f.y - 1.0, f.z, f.w - 1.0), u.x), u.y), mix(mix(noise_grad(hash_uint4(uint(I.x), uint(I.y), uint(I.z + 1), uint(I.w + 1)), f.x, f.y, f.z - 1.0, f.w - 1.0), noise_grad(hash_uint4(uint(I.x + 1), uint(I.y), uint(I.z + 1), uint(I.w + 1)), f.x - 1.0, f.y, f.z - 1.0, f.w - 1.0), u.x), mix(noise_grad(hash_uint4(uint(I.x), uint(I.y + 1), uint(I.z + 1), uint(I.w + 1)), f.x, f.y - 1.0, f.z - 1.0, f.w - 1.0), noise_grad(hash_uint4(uint(I.x + 1), uint(I.y + 1), uint(I.z + 1), uint(I.w + 1)), f.x - 1.0, f.y - 1.0, f.z - 1.0, f.w - 1.0), u.x), u.y), u.z);
    return mix(v0, v1, u.w);
}

float compatible_mod(float a, float b) {
    return (b != 0.0) ? (a - float(int(a / b)) * b) : 0.0;
}
vec2 compatible_mod(vec2 a, float b) { return vec2(compatible_mod(a.x, b), compatible_mod(a.y, b)); }
vec3 compatible_mod(vec3 a, float b) { return vec3(compatible_mod(a.x, b), compatible_mod(a.y, b), compatible_mod(a.z, b)); }
vec4 compatible_mod(vec4 a, float b) { return vec4(compatible_mod(a.x, b), compatible_mod(a.y, b), compatible_mod(a.z, b), compatible_mod(a.w, b)); }

float snoise(float p) {
    float precision_correction = 0.5 * float(abs(p) >= 1000000.0);
    p = compatible_mod(p, 100000.0) + precision_correction;
    return 0.25 * noise_perlin(p);
}
float snoise(vec2 p) {
    vec2 precision_correction = 0.5 * vec2(float(abs(p.x) >= 1000000.0), float(abs(p.y) >= 1000000.0));
    p = compatible_mod(p, 100000.0) + precision_correction;
    return 0.6616 * noise_perlin(p);
}
float snoise(vec3 p) {
    vec3 precision_correction = 0.5 * vec3(float(abs(p.x) >= 1000000.0), float(abs(p.y) >= 1000000.0), float(abs(p.z) >= 1000000.0));
    p = compatible_mod(p, 100000.0) + precision_correction;
    return 0.9820 * noise_perlin(p);
}
float snoise(vec4 p) {
    vec4 precision_correction = 0.5 * vec4(float(abs(p.x) >= 1000000.0), float(abs(p.y) >= 1000000.0), float(abs(p.z) >= 1000000.0), float(abs(p.w) >= 1000000.0));
    p = compatible_mod(p, 100000.0) + precision_correction;
    return 0.8344 * noise_perlin(p);
}

#define DEFINE_NOISE_FRACTAL(T) \
float noise_fbm(T co, float detail, float roughness, float lacunarity, float offset, float gain, bool normalize) { \
    T p = co; \
    float fscale = 1.0; \
    float amp = 1.0; \
    float maxamp = 0.0; \
    float sum = 0.0; \
    for (int i = 0; i <= int(detail); i++) { \
        float t = snoise(fscale * p); \
        sum += t * amp; \
        maxamp += amp; \
        amp *= roughness; \
        fscale *= lacunarity; \
    } \
    float rmd = detail - floor(detail); \
    if (rmd != 0.0) { \
        float t = snoise(fscale * p); \
        float sum2 = sum + t * amp; \
        return normalize ? mix(0.5 * sum / maxamp + 0.5, 0.5 * sum2 / (maxamp + amp) + 0.5, rmd) : mix(sum, sum2, rmd); \
    } else { \
        return normalize ? 0.5 * sum / maxamp + 0.5 : sum; \
    } \
} \
float noise_multi_fractal(T co, float detail, float roughness, float lacunarity, float offset, float gain, bool normalize) { \
    T p = co; \
    float value = 1.0; \
    float pwr = 1.0; \
    for (int i = 0; i <= int(detail); i++) { \
        value *= (pwr * snoise(p) + 1.0); \
        pwr *= roughness; \
        p *= lacunarity; \
    } \
    float rmd = detail - floor(detail); \
    if (rmd != 0.0) { \
        value *= (rmd * pwr * snoise(p) + 1.0); \
    } \
    return value; \
} \
float noise_hetero_terrain(T co, float detail, float roughness, float lacunarity, float offset, float gain, bool normalize) { \
    T p = co; \
    float pwr = roughness; \
    float value = offset + snoise(p); \
    p *= lacunarity; \
    for (int i = 1; i <= int(detail); i++) { \
        float increment = (snoise(p) + offset) * pwr * value; \
        value += increment; \
        pwr *= roughness; \
        p *= lacunarity; \
    } \
    float rmd = detail - floor(detail); \
    if (rmd != 0.0) { \
        float increment = (snoise(p) + offset) * pwr * value; \
        value += rmd * increment; \
    } \
    return value; \
} \
float noise_hybrid_multi_fractal(T co, float detail, float roughness, float lacunarity, float offset, float gain, bool normalize) { \
    T p = co; \
    float pwr = 1.0; \
    float value = 0.0; \
    float weight = 1.0; \
    for (int i = 0; (weight > 0.001) && (i <= int(detail)); i++) { \
        if (weight > 1.0) weight = 1.0; \
        float signal = (snoise(p) + offset) * pwr; \
        pwr *= roughness; \
        value += weight * signal; \
        weight *= gain * signal; \
        p *= lacunarity; \
    } \
    float rmd = detail - floor(detail); \
    if ((rmd != 0.0) && (weight > 0.001)) { \
        if (weight > 1.0) weight = 1.0; \
        float signal = (snoise(p) + offset) * pwr; \
        value += rmd * weight * signal; \
    } \
    return value; \
} \
float noise_ridged_multi_fractal(T co, float detail, float roughness, float lacunarity, float offset, float gain, bool normalize) { \
    T p = co; \
    float pwr = roughness; \
    float signal = offset - abs(snoise(p)); \
    signal *= signal; \
    float value = signal; \
    float weight = 1.0; \
    for (int i = 1; i <= int(detail); i++) { \
        p *= lacunarity; \
        weight = clamp(signal * gain, 0.0, 1.0); \
        signal = offset - abs(snoise(p)); \
        signal *= signal; \
        signal *= weight; \
        value += signal * pwr; \
        pwr *= roughness; \
    } \
    return value; \
}

DEFINE_NOISE_FRACTAL(float)
DEFINE_NOISE_FRACTAL(vec2)
DEFINE_NOISE_FRACTAL(vec3)
DEFINE_NOISE_FRACTAL(vec4)

float random_float_offset(float seed) { return 100.0 + hash_float_to_float(seed) * 100.0; }
vec2 random_vec2_offset(float seed) { return vec2(100.0 + hash_vec2_to_float(vec2(seed, 0.0)) * 100.0, 100.0 + hash_vec2_to_float(vec2(seed, 1.0)) * 100.0); }
vec3 random_vec3_offset(float seed) { return vec3(100.0 + hash_vec2_to_float(vec2(seed, 0.0)) * 100.0, 100.0 + hash_vec2_to_float(vec2(seed, 1.0)) * 100.0, 100.0 + hash_vec2_to_float(vec2(seed, 2.0)) * 100.0); }
vec4 random_vec4_offset(float seed) { return vec4(100.0 + hash_vec2_to_float(vec2(seed, 0.0)) * 100.0, 100.0 + hash_vec2_to_float(vec2(seed, 1.0)) * 100.0, 100.0 + hash_vec2_to_float(vec2(seed, 2.0)) * 100.0, 100.0 + hash_vec2_to_float(vec2(seed, 3.0)) * 100.0); }

vec3 hash_float_to_vec3(float k) {
    return vec3(hash_float_to_float(k), hash_vec2_to_float(vec2(k, 1.0)), hash_vec2_to_float(vec2(k, 2.0)));
}

vec3 hash_vec2_to_vec3(vec2 k) {
    return vec3(hash_vec2_to_float(k), hash_vec3_to_float(vec3(k, 1.0)), hash_vec3_to_float(vec3(k, 2.0)));
}

vec3 hash_vec3_to_vec3(vec3 k) {
    return vec3(hash_vec3_to_float(k), hash_vec4_to_float(vec4(k, 1.0)), hash_vec4_to_float(vec4(k, 2.0)));
}

vec3 hash_vec4_to_vec3(vec4 k) {
    return vec3(hash_vec4_to_float(k.xyzw), hash_vec4_to_float(k.zxwy), hash_vec4_to_float(k.wzyx));
}
"""

str_tex_musgrave = """
vec3 random3(const vec3 c) {
    float j = 4096.0 * sin(dot(c, vec3(17.0, 59.4, 15.0)));
    vec3 r;
    r.z = fract(512.0 * j);
    j *= 0.125;
    r.x = fract(512.0 * j);
    j *= 0.125;
    r.y = fract(512.0 * j);
    return r - 0.5;
}

float noise_tex(const vec3 p) {
    const float F3 = 0.3333333;
    const float G3 = 0.1666667;

    vec3 s = floor(p + dot(p, vec3(F3)));
    vec3 x = p - s + dot(s, vec3(G3));
    vec3 e = step(vec3(0.0), x - x.yzx);
    vec3 i1 = e * (1.0 - e.zxy);
    vec3 i2 = 1.0 - e.zxy * (1.0 - e);

    vec3 x1 = x - i1 + G3;
    vec3 x2 = x - i2 + 2.0 * G3;
    vec3 x3 = x - 1.0 + 3.0 * G3;

    vec4 w;
    w.x = max(0.6 - dot(x, x), 0.0);
    w.y = max(0.6 - dot(x1, x1), 0.0);
    w.z = max(0.6 - dot(x2, x2), 0.0);
    w.w = max(0.6 - dot(x3, x3), 0.0);

    w = w * w;
    w = w * w;

    vec4 d;
    d.x = dot(random3(s), x);
    d.y = dot(random3(s + i1), x1);
    d.z = dot(random3(s + i2), x2);
    d.w = dot(random3(s + 1.0), x3);

    d *= w;
    return clamp(dot(d, vec4(52.0)), 0.0, 1.0);
}

float tex_musgrave_f(const vec3 p, float detail, float distortion) {
    // Apply distortion to the input coordinates smoothly with noise_tex
    vec3 distorted_p = p + distortion * vec3(
        noise_tex(p + vec3(5.2, 1.3, 7.1)),
        noise_tex(p + vec3(1.7, 9.2, 3.8)),
        noise_tex(p + vec3(8.3, 2.8, 4.5))
    );

    float value = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;

    // Use 'detail' as number of octaves, clamped between 1 and 8
    int octaves = int(clamp(detail, 1.0, 8.0));

    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise_tex(distorted_p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }

    return clamp(value, 0.0, 1.0);
}

"""

# col: the incoming color
# shift: a vector containing the hue shift, the saturation modificator, the value modificator and the mix factor in this order
# this does the following:
# make rgb col to hsv
# apply hue shift through addition, sat/val through multiplication
# return an rgb color, mixed with the original one
str_hue_sat = """
vec3 hsv_to_rgb(const vec3 c) {
  const vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
vec3 rgb_to_hsv(const vec3 c) {
    const vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hue_sat(const vec3 col, const vec4 shift) {
    vec3 hsv = rgb_to_hsv(col);
    hsv.x += shift.x;
    hsv.y *= shift.y;
    hsv.z *= shift.z;
    return mix(hsv_to_rgb(hsv), col, shift.w);
}
"""

# https://twitter.com/Donzanoid/status/903424376707657730
str_wavelength_to_rgb = """
vec3 wavelength_to_rgb(const float t) {
    vec3 r = t * 2.1 - vec3(1.8, 1.14, 0.3);
    return 1.0 - r * r;
}
"""

str_tex_magic = """
//https://github.com/blender/blender/blob/main/source/blender/gpu/shaders/material/gpu_shader_material_tex_magic.glsl
vec3 tex_magic(vec3 p, float distortion, int depth) {
    p = mod(p, 6.2831853f);

    float x = sin((p.x + p.y + p.z) * 5.0f);
    float y = cos((-p.x + p.y - p.z) * 5.0f);
    float z = -cos((-p.x - p.y + p.z) * 5.0f);

    if (depth > 0) {
        x *= distortion;
        y *= distortion;
        z *= distortion;
        y = -cos(x - y + z);
        y *= distortion;
        if (depth > 1) {
            x = cos(x - y - z);
            x *= distortion;
            if (depth > 2) {
                z = sin(-x - y - z);
                z *= distortion;
                if (depth > 3) {
                    x = -cos(-x + y - z);
                    x *= distortion;
                    if (depth > 4) {
                        y = -sin(-x + y + z);
                        y *= distortion;
                        if (depth > 5) {
                            y = -cos(-x + y + z);
                            y *= distortion;
                            if (depth > 6) {
                                x = cos(x + y + z);
                                x *= distortion;
                                if (depth > 7) {
                                    z = sin(x + y - z);
                                    z *= distortion;
                                    if (depth > 8) {
                                        x = -cos(-x - y + z);
                                        x *= distortion;
                                        if (depth > 9) {
                                            y = -sin(x - y + z);
                                            y *= distortion;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (distortion != 0.0f) {
        distortion *= 2.0f;
        x /= distortion;
        y /= distortion;
        z /= distortion;
    }

    return vec3(0.5f - x, 0.5f - y, 0.5f - z);
}

float tex_magic_f(vec3 p, float distortion, int depth) {
    vec3 c = tex_magic(p, distortion, depth);
    return (c.x + c.y + c.z) / 3.0f;
}
"""

str_tex_brick = """
vec3 tex_brick(vec3 p, const vec3 c1, const vec3 c2, const vec3 c3) {
    p /= vec3(0.9, 0.49, 0.49) / 2;
    if (fract(p.y * 0.5) > 0.5) p.x += 0.5;   
    p = fract(p);
    vec3 b = step(p, vec3(0.95, 0.9, 0.9));
    return mix(c3, c1, b.x * b.y * b.z);
}
float tex_brick_f(vec3 p) {
    p /= vec3(0.9, 0.49, 0.49) / 2;
    if (fract(p.y * 0.5) > 0.5) p.x += 0.5;   
    p = fract(p);
    vec3 b = step(p, vec3(0.95, 0.9, 0.9));
    return mix(1.0, 0.0, b.x * b.y * b.z);
}
"""

#https://github.com/blender/blender/blob/main/source/blender/gpu/shaders/material/gpu_shader_material_tex_brick.glsl
str_tex_brick_blender = """
float integer_noise(int n)
{
  /* Integer bit-shifts for these calculations can cause precision problems on macOS.
   * Using uint resolves these issues. */
  uint nn;
  nn = (uint(n) + 1013u) & 0x7fffffffu;
  nn = (nn >> 13u) ^ nn;
  nn = (uint(nn * (nn * nn * 60493u + 19990303u)) + 1376312589u) & 0x7fffffffu;
  return 0.5f * (float(nn) / 1073741824.0f);
}

vec2 calc_brick_texture(vec3 p,
                          float mortar_size,
                          float mortar_smooth,
                          float bias,
                          float brick_width,
                          float row_height,
                          float offset_amount,
                          int offset_frequency,
                          float squash_amount,
                          int squash_frequency)
{
  int bricknum, rownum;
  float offset = 0.0f;
  float x, y;

  rownum = int(floor(p.y / row_height));

  if (offset_frequency != 0 && squash_frequency != 0) {
    brick_width *= (rownum % squash_frequency != 0) ? 1.0f : squash_amount;           /* squash */
    offset = (rownum % offset_frequency != 0) ? 0.0f : (brick_width * offset_amount); /* offset */
  }

  bricknum = int(floor((p.x + offset) / brick_width));

  x = (p.x + offset) - brick_width * bricknum;
  y = p.y - row_height * rownum;

  float tint = clamp((integer_noise((rownum << 16) + (bricknum & 0xFFFF)) + bias), 0.0f, 1.0f);

  float min_dist = min(min(x, y), min(brick_width - x, row_height - y));
  if (min_dist >= mortar_size) {
    return vec2(tint, 0.0f);
  }
  else if (mortar_smooth == 0.0f) {
    return vec2(tint, 1.0f);
  }
  else {
    min_dist = 1.0f - min_dist / mortar_size;
    return vec2(tint, smoothstep(0.0f, mortar_smooth, min_dist));
  }
}

vec3 tex_brick_blender(vec3 co,
                    vec3 color1,
                    vec3 color2,
                    vec3 mortar,
                    float scale,
                    float mortar_size,
                    float mortar_smooth,
                    float bias,
                    float brick_width,
                    float row_height,
                    float offset_amount,
                    float offset_frequency,
                    float squash_amount,
                    float squash_frequency)
{
  vec2 f2 = calc_brick_texture(co * scale,
                                 mortar_size,
                                 mortar_smooth,
                                 bias,
                                 brick_width,
                                 row_height,
                                 offset_amount,
                                 int(offset_frequency),
                                 squash_amount,
                                 int(squash_frequency));
  float tint = f2.x;
  float f = f2.y;
  if (f != 1.0f) {
    float facm = 1.0f - tint;
    color1 = facm * color1 + tint * color2;
  }
    return mix(color1, mortar, f);
}

float tex_brick_blender_f(vec3 co,
                    vec3 color1,
                    vec3 color2,
                    vec3 mortar,
                    float scale,
                    float mortar_size,
                    float mortar_smooth,
                    float bias,
                    float brick_width,
                    float row_height,
                    float offset_amount,
                    float offset_frequency,
                    float squash_amount,
                    float squash_frequency)
{
  vec2 f2 = calc_brick_texture(co * scale,
                                 mortar_size,
                                 mortar_smooth,
                                 bias,
                                 brick_width,
                                 row_height,
                                 offset_amount,
                                 int(offset_frequency),
                                 squash_amount,
                                 int(squash_frequency));
  float tint = f2.x;
  float f = f2.y;
  if (f != 1.0f) {
    float facm = 1.0f - tint;
    color1 = facm * color1 + tint * color2;
  }
    return f;
}
"""

str_tex_wave = """
float tex_wave_f(const vec3 p, const int type, const int d, const int profile, const float dist, const float detail, const float detail_scale, const float phase_offset, const float detail_roughness) {
    float n;
    
    if (type == 0) {
        float co;
        if (d == 0) co = p.x;
        else if (d == 1) co = p.y;
        else if (d == 2) co = p.z;
        else co = (p.x + p.y + p.z) * 0.577;
        n = co * 20.0;
    }
    else {
        n = length(p) * 20.0;
    }

    if (dist != 0.0) {
        n += dist * fractal_noise(p * detail_scale, detail, detail_roughness) * 2.0 - 1.0;
    }

    n += phase_offset;

    if (profile == 0) {
        return 0.5 + 0.5 * sin(n - PI);
    }
    else if (profile == 1) {
        n /= 2.0 * PI;
        return n - floor(n);
    }
    else {
        n /= 2.0 * PI;
        return abs(2.0 * (n - floor(n + 0.5)));
    }
}
"""

str_tex_gabor = """
uint hash_uint3(uint kx, uint ky, uint kz) {
    uint a, b, c;
    a = b = c = 0xdeadbeefu + (3u << 2u) + 13u;
    c += kz;
    b += ky;
    a += kx;
    c ^= b; c -= (b << 14u) | (b >> 18u);
    a ^= c; a -= (c << 11u) | (c >> 21u);
    b ^= a; b -= (a << 25u) | (a >> 7u);
    c ^= b; c -= (b << 16u) | (b >> 16u);
    a ^= c; a -= (c << 4u) | (c >> 28u);
    b ^= a; b -= (a << 14u) | (a >> 18u);
    c ^= b; c -= (b << 24u) | (b >> 8u);
    return c;
}

uint hash_uint4(uint kx, uint ky, uint kz, uint kw) {
    uint a, b, c;
    a = b = c = 0xdeadbeefu + (4u << 2u) + 13u;
    a += kx; b += ky; c += kz;
    a -= c; a ^= (c << 4u) | (c >> 28u); c += b;
    b -= a; b ^= (a << 6u) | (a >> 26u); a += c;
    c -= b; c ^= (b << 8u) | (b >> 24u); b += a;
    a -= c; a ^= (c << 16u) | (c >> 16u); c += b;
    b -= a; b ^= (a << 19u) | (a >> 13u); a += c;
    c -= b; c ^= (b << 4u) | (b >> 28u); b += a;
    a += kw;
    c ^= b; c -= (b << 14u) | (b >> 18u);
    a ^= c; a -= (c << 11u) | (c >> 21u);
    b ^= a; b -= (a << 25u) | (a >> 7u);
    c ^= b; c -= (b << 16u) | (b >> 16u);
    a ^= c; a -= (c << 4u) | (c >> 28u);
    b ^= a; b -= (a << 14u) | (a >> 18u);
    c ^= b; c -= (b << 24u) | (b >> 8u);
    return c;
}

float hash_vec3_to_float(vec3 k) {
    return float(hash_uint3(floatBitsToUint(k.x), floatBitsToUint(k.y), floatBitsToUint(k.z))) / float(0xFFFFFFFFu);
}

float hash_vec4_to_float(vec4 k) {
    return float(hash_uint4(floatBitsToUint(k.x), floatBitsToUint(k.y), floatBitsToUint(k.z), floatBitsToUint(k.w))) / float(0xFFFFFFFFu);
}

vec2 hash_vec3_to_vec2(vec3 k) {
    return vec2(hash_vec3_to_float(k.xyz), hash_vec3_to_float(k.zxy));
}

vec2 hash_vec4_to_vec2(vec4 k) {
    return vec2(hash_vec4_to_float(k.xyzw), hash_vec4_to_float(k.zxwy));
}

vec3 hash_vec4_to_vec3(vec4 k) {
    return vec3(hash_vec4_to_float(k.xyzw), hash_vec4_to_float(k.zxwy), hash_vec4_to_float(k.wzyx));
}

vec2 compute_2d_gabor_kernel(vec2 position, float frequency, float orientation) {
    float distance_squared = dot(position, position);
    float hann_window = 0.5 + 0.5 * cos(3.14159265359 * distance_squared);
    float gaussian_envelop = exp(-3.14159265359 * distance_squared);
    vec2 frequency_vector = frequency * vec2(cos(orientation), sin(orientation));
    float angle = 6.28318530718 * dot(position, frequency_vector);
    return gaussian_envelop * hann_window * vec2(cos(angle), sin(angle));
}

float compute_2d_gabor_standard_deviation() {
    return sqrt(8.0 * 0.5 * 0.25);
}

vec2 compute_2d_gabor_noise_cell(vec2 cell, vec2 position, float frequency, float isotropy, float base_orientation) {
    vec2 noise = vec2(0.0);
    for (int i = 0; i < 8; ++i) {
        vec3 seed_for_orientation = vec3(cell, float(i * 3));
        vec3 seed_for_kernel_center = vec3(cell, float(i * 3 + 1));
        vec3 seed_for_weight = vec3(cell, float(i * 3 + 2));
        float random_orientation = (hash_vec3_to_float(seed_for_orientation) - 0.5) * 3.14159265359;
        float orientation = base_orientation + random_orientation * isotropy;
        vec2 kernel_center = hash_vec3_to_vec2(seed_for_kernel_center);
        vec2 position_in_kernel_space = position - kernel_center;
        if (dot(position_in_kernel_space, position_in_kernel_space) >= 1.0) continue;
        float weight = hash_vec3_to_float(seed_for_weight) < 0.5 ? -1.0 : 1.0;
        noise += weight * compute_2d_gabor_kernel(position_in_kernel_space, frequency, orientation);
    }
    return noise;
}

vec2 compute_2d_gabor_noise(vec2 coordinates, float frequency, float isotropy, float base_orientation) {
    vec2 cell_position = floor(coordinates);
    vec2 local_position = coordinates - cell_position;
    vec2 sum = vec2(0.0);
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 cell_offset = vec2(float(i), float(j));
            sum += compute_2d_gabor_noise_cell(cell_position + cell_offset, local_position - cell_offset, frequency, isotropy, base_orientation);
        }
    }
    return sum;
}

vec2 compute_3d_gabor_kernel(vec3 position, float frequency, vec3 orientation) {
    float distance_squared = dot(position, position);
    float hann_window = 0.5 + 0.5 * cos(3.14159265359 * distance_squared);
    float gaussian_envelop = exp(-3.14159265359 * distance_squared);
    vec3 frequency_vector = frequency * orientation;
    float angle = 6.28318530718 * dot(position, frequency_vector);
    return gaussian_envelop * hann_window * vec2(cos(angle), sin(angle));
}

float compute_3d_gabor_standard_deviation() {
    return sqrt(8.0 * 0.5 * (1.0 / (4.0 * 1.41421356237)));
}

vec3 compute_3d_orientation(vec3 orientation, float isotropy, vec4 seed) {
    if (isotropy == 0.0) return orientation;
    float inclination = acos(clamp(orientation.z, -1.0, 1.0));
    float azimuth = sign(orientation.y) * acos(orientation.x / length(orientation.xy));
    vec2 random_angles = hash_vec4_to_vec2(seed) * 3.14159265359;
    inclination += random_angles.x * isotropy;
    azimuth += random_angles.y * isotropy;
    return vec3(sin(inclination) * cos(azimuth), sin(inclination) * sin(azimuth), cos(inclination));
}

vec2 compute_3d_gabor_noise_cell(vec3 cell, vec3 position, float frequency, float isotropy, vec3 base_orientation) {
    vec2 noise = vec2(0.0);
    for (int i = 0; i < 8; ++i) {
        vec4 seed_for_orientation = vec4(cell, float(i * 3));
        vec4 seed_for_kernel_center = vec4(cell, float(i * 3 + 1));
        vec4 seed_for_weight = vec4(cell, float(i * 3 + 2));
        vec3 orientation = compute_3d_orientation(base_orientation, isotropy, seed_for_orientation);
        vec3 kernel_center = hash_vec4_to_vec3(seed_for_kernel_center);
        vec3 position_in_kernel_space = position - kernel_center;
        if (dot(position_in_kernel_space, position_in_kernel_space) >= 1.0) continue;
        float weight = hash_vec4_to_float(seed_for_weight) < 0.5 ? -1.0 : 1.0;
        noise += weight * compute_3d_gabor_kernel(position_in_kernel_space, frequency, orientation);
    }
    return noise;
}

vec2 compute_3d_gabor_noise(vec3 coordinates, float frequency, float isotropy, vec3 base_orientation) {
    vec3 cell_position = floor(coordinates);
    vec3 local_position = coordinates - cell_position;
    vec2 sum = vec2(0.0);
    for (int k = -1; k <= 1; k++) {
        for (int j = -1; j <= 1; j++) {
            for (int i = -1; i <= 1; i++) {
                vec3 cell_offset = vec3(float(i), float(j), float(k));
                sum += compute_3d_gabor_noise_cell(cell_position + cell_offset, local_position - cell_offset, frequency, isotropy, base_orientation);
            }
        }
    }
    return sum;
}

vec3 tex_gabor_core(vec3 coordinates, float scale, float frequency, float anisotropy, float orientation_2d, vec3 orientation_3d, float type) {
    vec3 scaled_coordinates = coordinates * scale;
    float isotropy = 1.0 - clamp(anisotropy, 0.0, 1.0);
    frequency = max(0.001, frequency);
    vec2 phasor = vec2(0.0);
    float standard_deviation = 1.0;
    if (type == 0.0) {
        phasor = compute_2d_gabor_noise(scaled_coordinates.xy, frequency, isotropy, orientation_2d);
        standard_deviation = compute_2d_gabor_standard_deviation();
    }
    else if (type == 1.0) {
        float len = length(orientation_3d);
        vec3 orientation = len > 0.0 ? orientation_3d / len : vec3(0.0, 0.0, 1.0);
        phasor = compute_3d_gabor_noise(scaled_coordinates, frequency, isotropy, orientation);
        standard_deviation = compute_3d_gabor_standard_deviation();
    }
    float normalization_factor = 6.0 * standard_deviation;
    float output_value = (phasor.y / normalization_factor) * 0.5 + 0.5;
    float output_phase = (atan(phasor.y, phasor.x) + 3.14159265359) / 6.28318530718;
    float output_intensity = length(phasor) / normalization_factor;
    return vec3(output_value, output_phase, output_intensity);
}

float tex_gabor_value(vec3 coordinates, float scale, float frequency, float anisotropy, float orientation_2d, vec3 orientation_3d, float type) {
    return tex_gabor_core(coordinates, scale, frequency, anisotropy, orientation_2d, orientation_3d, type).x;
}

float tex_gabor_phase(vec3 coordinates, float scale, float frequency, float anisotropy, float orientation_2d, vec3 orientation_3d, float type) {
    return tex_gabor_core(coordinates, scale, frequency, anisotropy, orientation_2d, orientation_3d, type).y;
}

float tex_gabor_intensity(vec3 coordinates, float scale, float frequency, float anisotropy, float orientation_2d, vec3 orientation_3d, float type) {
    return tex_gabor_core(coordinates, scale, frequency, anisotropy, orientation_2d, orientation_3d, type).z;
}
"""

str_brightcontrast = """
vec3 brightcontrast(const vec3 col, const float bright, const float contr) {
    float a = 1.0 + contr;
    float b = bright - contr * 0.5;
    return max(a * col + b, 0.0);
}
"""

# https://seblagarde.wordpress.com/2013/04/29/memo-on-fresnel-equations/
# dielectric-dielectric
# approx pow(1.0 - dotNV, 7.25 / ior)
str_fresnel = """
float fresnel(float eta, float c) {
    float g = eta * eta - 1.0 + c * c;
    if (g < 0.0) return 1.0;
    g = sqrt(g);
    float a = (g - c) / (g + c);
    float b = ((g + c) * c - 1.0) / ((g - c) * c + 1.0);
    return 0.5 * a * a * (1.0 + b * b);
}
"""

# Save division like Blender does it. If dividing by 0, the result is 0.
# https://github.com/blender/blender/blob/df1e9b662bd6938f74579cea9d30341f3b6dd02b/intern/cycles/kernel/shaders/node_vector_math.osl
str_safe_divide = """
vec3 safe_divide(const vec3 a, const vec3 b) {
\treturn vec3((b.x != 0.0) ? a.x / b.x : 0.0,
\t            (b.y != 0.0) ? a.y / b.y : 0.0,
\t            (b.z != 0.0) ? a.z / b.z : 0.0);
}
"""

# https://github.com/blender/blender/blob/df1e9b662bd6938f74579cea9d30341f3b6dd02b/intern/cycles/kernel/shaders/node_vector_math.osl
str_project = """
vec3 project(const vec3 v, const vec3 v_proj) {
\tfloat lenSquared = dot(v_proj, v_proj);
\treturn (lenSquared != 0.0) ? (dot(v, v_proj) / lenSquared) * v_proj : vec3(0);
}
"""

# Adapted from godot engine math_funcs.h
str_wrap = """
float wrap(const float value, const float max, const float min) {
\tfloat range = max - min;
\treturn (range != 0.0) ? value - (range * floor((value - min) / range)) : min;
}
vec3 wrap(const vec3 value, const vec3 max, const vec3 min) {
\treturn vec3(wrap(value.x, max.x, min.x),
\t            wrap(value.y, max.y, min.y),
\t            wrap(value.z, max.z, min.z));
}
"""

str_blackbody = """
vec3 blackbody(const float temperature){

  vec3 rgb = vec3(0.0, 0.0, 0.0);

  vec3 r = vec3(0.0, 0.0, 0.0);
  vec3 g = vec3(0.0, 0.0, 0.0);
  vec3 b = vec3(0.0, 0.0, 0.0);

  float t_inv = float(1.0 / temperature);

  if (temperature >= 12000.0) {

    rgb = vec3(0.826270103, 0.994478524, 1.56626022);

  } else if(temperature < 965.0) {

    rgb = vec3(4.70366907, 0.0, 0.0);

  } else {

    if (temperature >= 6365.0) {
      vec3 r = vec3(3.78765709e+03, 9.36026367e-06, 3.98995841e-01);
      vec3 g = vec3(-5.00279505e+02, -4.59745390e-06, 1.09090465e+00);
      vec4 b = vec4(6.72595954e-13, -2.73059993e-08, 4.24068546e-04, -7.52204323e-01);

      rgb = vec3(r.r * t_inv + r.g * temperature + r.b, g.r * t_inv + g.g * temperature + g.b, ((b.r * temperature + b.g) * temperature + b.b) * temperature + b.a );

    } else if (temperature >= 3315.0) {
      vec3 r = vec3(4.60124770e+03, 2.89727618e-05, 1.48001316e-01);
      vec3 g = vec3(-1.18134453e+03, -2.18913373e-05, 1.30656109e+00);
      vec4 b = vec4(-2.22463426e-13, -1.55078698e-08, 3.81675160e-04, -7.30646033e-01);

      rgb = vec3(r.r * t_inv + r.g * temperature + r.b, g.r * t_inv + g.g * temperature + g.b, ((b.r * temperature + b.g) * temperature + b.b) * temperature + b.a );

    } else if (temperature >= 1902.0) {
      vec3 r = vec3(4.66849800e+03, 2.85655028e-05, 1.29075375e-01);
      vec3 g = vec3(-1.42546105e+03, -4.01730887e-05, 1.44002695e+00);
      vec4 b = vec4(-2.02524603e-11, 1.79435860e-07, -2.60561875e-04, -1.41761141e-02);

      rgb = vec3(r.r * t_inv + r.g * temperature + r.b, g.r * t_inv + g.g * temperature + g.b, ((b.r * temperature + b.g) * temperature + b.b) * temperature + b.a );

    } else if (temperature >= 1449.0) {
      vec3 r = vec3(4.10671449e+03, -8.61949938e-05, 6.41423749e-01);
      vec3 g = vec3(-1.22075471e+03, 2.56245413e-05, 1.20753416e+00);
      vec4 b = vec4(0.0, 0.0, 0.0, 0.0);

      rgb = vec3(r.r * t_inv + r.g * temperature + r.b, g.r * t_inv + g.g * temperature + g.b, ((b.r * temperature + b.g) * temperature + b.b) * temperature + b.a );

    } else if (temperature >= 1167.0) {
      vec3 r = vec3(3.37763626e+03, -4.34581697e-04, 1.64843306e+00);
      vec3 g = vec3(-1.00402363e+03, 1.29189794e-04, 9.08181524e-01);
      vec4 b = vec4(0.0, 0.0, 0.0, 0.0);

      rgb = vec3(r.r * t_inv + r.g * temperature + r.b, g.r * t_inv + g.g * temperature + g.b, ((b.r * temperature + b.g) * temperature + b.b) * temperature + b.a );

    } else {
      vec3 r = vec3(2.52432244e+03, -1.06185848e-03, 3.11067539e+00);
      vec3 g = vec3(-7.50343014e+02, 3.15679613e-04, 4.73464526e-01);
      vec4 b = vec4(0.0, 0.0, 0.0, 0.0);

      rgb = vec3(r.r * t_inv + r.g * temperature + r.b, g.r * t_inv + g.g * temperature + g.b, ((b.r * temperature + b.g) * temperature + b.b) * temperature + b.a );

    }
  }

  return rgb;

}
"""

# Adapted from https://github.com/blender/blender/blob/594f47ecd2d5367ca936cf6fc6ec8168c2b360d0/source/blender/gpu/shaders/material/gpu_shader_material_map_range.glsl
str_map_range_linear = """
float map_range_linear(const float value, const float fromMin, const float fromMax, const float toMin, const float toMax) {
  if (fromMax != fromMin) {
    return float(toMin + ((value - fromMin) / (fromMax - fromMin)) * (toMax - toMin));
  }
  else {
    return float(0.0);
  }
}
"""

str_map_range_stepped = """
float map_range_stepped(const float value, const float fromMin, const float fromMax, const float toMin, const float toMax, const float steps) {
  if (fromMax != fromMin) {
    float factor = (value - fromMin) / (fromMax - fromMin);
    factor = (steps > 0.0) ? floor(factor * (steps + 1.0)) / steps : 0.0;
    return float(toMin + factor * (toMax - toMin));
  }
  else {
    return float(0.0);
  }
}
"""

str_map_range_smoothstep = """
float map_range_smoothstep(const float value, const float fromMin, const float fromMax, const float toMin, const float toMax)
{
  if (fromMax != fromMin) {
    float factor = (fromMin > fromMax) ? 1.0 - smoothstep(fromMax, fromMin, value) :
                                         smoothstep(fromMin, fromMax, value);
    return float(toMin + factor * (toMax - toMin));
  }
  else {
    return float(0.0);
  }
}
"""

str_map_range_smootherstep = """
float safe_divide(float a, float b)
{
  return (b != 0.0) ? a / b : 0.0;
}

float smootherstep(float edge0, float edge1, float x)
{
  x = clamp(safe_divide((x - edge0), (edge1 - edge0)), 0.0, 1.0);
  return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
}

float map_range_smootherstep(const float value, const float fromMin, const float fromMax, const float toMin, const float toMax) {
  if (fromMax != fromMin) {
    float factor = (fromMin > fromMax) ? 1.0 - smootherstep(fromMax, fromMin, value) :
                                         smootherstep(fromMin, fromMax, value);
    return float(toMin + factor * (toMax - toMin));
  }
  else {
    return float(0.0);
  }
}
"""

str_rotate_around_axis = """
vec3 rotate_around_axis(const vec3 p, const vec3 axis, const float angle)
{
  float costheta = cos(angle);
  float sintheta = sin(angle);
  vec3 r;

  r.x = ((costheta + (1.0 - costheta) * axis.x * axis.x) * p.x) +
        (((1.0 - costheta) * axis.x * axis.y - axis.z * sintheta) * p.y) +
        (((1.0 - costheta) * axis.x * axis.z + axis.y * sintheta) * p.z);

  r.y = (((1.0 - costheta) * axis.x * axis.y + axis.z * sintheta) * p.x) +
        ((costheta + (1.0 - costheta) * axis.y * axis.y) * p.y) +
        (((1.0 - costheta) * axis.y * axis.z - axis.x * sintheta) * p.z);

  r.z = (((1.0 - costheta) * axis.x * axis.z - axis.y * sintheta) * p.x) +
        (((1.0 - costheta) * axis.y * axis.z + axis.x * sintheta) * p.y) +
        ((costheta + (1.0 - costheta) * axis.z * axis.z) * p.z);

  return r;
}
"""

str_euler_to_mat3 = """
mat3 euler_to_mat3(vec3 euler)
{
  float cx = cos(euler.x);
  float cy = cos(euler.y);
  float cz = cos(euler.z);
  float sx = sin(euler.x);
  float sy = sin(euler.y);
  float sz = sin(euler.z);

  mat3 mat;
  mat[0][0] = cy * cz;
  mat[0][1] = cy * sz;
  mat[0][2] = -sy;

  mat[1][0] = sy * sx * cz - cx * sz;
  mat[1][1] = sy * sx * sz + cx * cz;
  mat[1][2] = cy * sx;

  mat[2][0] = sy * cx * cz + sx * sz;
  mat[2][1] = sy * cx * sz - sx * cz;
  mat[2][2] = cy * cx;
  return mat;
}
"""
