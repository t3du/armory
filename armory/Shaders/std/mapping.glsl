vec3 blendNormal(vec3 normal) {
	vec3 blending = abs(normal);
	blending = normalize(max(blending, 0.00001));
	blending /= vec3(blending.x + blending.y + blending.z);
	return blending;
}

vec4 boxProjection(sampler2D image, vec3 normal, vec3 coord) {
	vec3 n = normalize(normal);
	vec3 absN = abs(n);
	vec4 color1, color2, color3;

	vec2 uv = coord.yz;
	if (n.x < 0.0) {
		uv.x = 1.0 - uv.x;
	}
	color1 = texture(image, uv);

	uv = coord.xz;
	if (n.y > 0.0) {
		uv.x = 1.0 - uv.x;
	}
	color2 = texture(image, uv);

	uv = vec2(coord.y, 1.0 - coord.x);
	if (n.z > 0.0) {
	    uv.x = 1.0 - uv.x;
	}
	color3 = texture(image, uv);

	vec3 weight = absN;
	weight /= max(dot(weight, vec3(1.0)), 1e-8);
	return color1 * weight.x + color2 * weight.y + color3 * weight.z;
}

vec2 sphericalMapping(vec3 coord) {
	vec3 vin = coord * 2.0 - vec3(1.0);
	float len = length(vin);
	float v, u;
	if (len > 0.0) {
		if (vin.x == 0.0 && vin.y == 0.0) {
			u = 0.0;
		}
		else {
			u = (1.0 - atan(vin.x, vin.y) / PI) * 0.5;
		}
		v = acos(clamp(vin.z / len, -1.0, 1.0)) / PI;
	}
	else {
		v = u = 0.0;
	}
	return vec2(u, v);
}

vec2 tubeMapping(vec3 coord) {
	vec3 vin = coord * 2.0 - vec3(1.0);
	float u, v;
	v = - (vin.z + 1.0) * 0.5;
	float len = sqrt(vin.x * vin.x + vin.y * vin.y);
	if (len > 0.0) {
		u = (1.0 - (atan(vin.x / len, vin.y / len) / PI)) * 0.5;
	}
	else {
		v = u = 0.0;
	}
	return vec2(u, v);
}
