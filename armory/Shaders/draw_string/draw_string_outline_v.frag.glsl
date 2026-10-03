#version 450

uniform sampler2D tex;
in vec2 texCoord;
in vec4 color;
out vec4 FragColor;

void main() {
	vec2 texel = 1.0 / vec2(textureSize(tex, 0));
	float radius = color.r * 64.0;
	float scaleX = color.g * 4.0;
	float scaleY = color.b * 4.0;
	float minDistance = 1000.0;
	float edgeAlpha = 0.0;
	int maxSteps = int(ceil(radius / scaleY));
	for (int y = -33; y <= 33; ++y) {
		if (abs(y) <= maxSteps) {
			vec3 sampleMask = textureLod(tex, texCoord + vec2(0.0, float(y) * texel.y), 0.0).rgb;
			if (sampleMask.b > 0.5) {
				float x = (sampleMask.r * 255.0 - 64.0) * scaleX;
				float distance = length(vec2(x, float(y) * scaleY));
				if (distance < minDistance) {
					minDistance = distance;
					edgeAlpha = sampleMask.g;
				}
			}
		}
	}
	float coverage;
	float edgeSoftness = max(0.5 * min(scaleX, scaleY), 0.5);
	coverage = 1.0 - smoothstep(radius - edgeSoftness, radius + edgeSoftness, minDistance);
	FragColor = vec4(coverage * edgeAlpha);
}
