/*
https://github.com/JonasFolletete/glsl-triplanar-mapping

MIT License

Copyright (c) 2018 Jonas Folletête

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

vec3 blendNormal(vec3 normal) {
	vec3 blending = abs(normal);
	blending = normalize(max(blending, 0.00001));
	blending /= vec3(blending.x + blending.y + blending.z);
	return blending;
}

vec3 triplanarMapping (sampler2D ImageTexture, vec3 normal, vec3 position) {
  	vec3 normalBlend = blendNormal(normal);
	vec3 xColor = texture(ImageTexture, position.yz).rgb;
	vec3 yColor = texture(ImageTexture, position.xz).rgb;
	vec3 zColor = texture(ImageTexture, position.xy).rgb;

  return (xColor * normalBlend.x + yColor * normalBlend.y + zColor * normalBlend.z);
}

vec2 sphericalMapping(vec3 coord) {
	float len = length(coord);
	if (len == 0.0) {
		return vec2(0.5, 0.5);
	}
	vec3 n = coord / len;
	float theta = atan(-n.x, n.y) + PI;
	float u = theta / PI2;
	float v = acos(clamp(n.z, -1.0, 1.0)) / PI;
	return vec2(u, v);
}

vec2 tubeMapping(vec3 coord) {
	float u = 1.0 - (atan(coord.x, coord.y) + PI) / PI2;
	float v = 1.0 - (coord.z + 1.0) * 0.5;
	return vec2(u, v);
}
