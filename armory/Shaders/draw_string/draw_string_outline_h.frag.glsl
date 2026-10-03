#version 450

uniform sampler2D tex;
in vec2 texCoord;
in vec4 color;
out vec4 FragColor;

void main() {
	vec2 texel = 1.0 / vec2(textureSize(tex, 0));
	float radius = color.r * 64.0;
	float scaleX = color.g * 4.0;
	float bestAbsX = 65.0;
	float bestX = 0.0;
	float bestAlpha = 0.0;
	int maxSteps = int(ceil(radius / scaleX));
	for (int x = -33; x <= 33; ++x) {
		if (abs(x) <= maxSteps) {
			float alpha = textureLod(tex, texCoord + vec2(float(x) * scaleX * texel.x, 0.0), 0.0).a;
			if (alpha >= 0.5 && abs(float(x)) < bestAbsX) {
				bestAbsX = abs(float(x));
				bestX = float(x);
				bestAlpha = alpha;
			}
		}
	}
	float encodedX = (bestX + 64.0) / 255.0;
	FragColor = vec4(encodedX, bestAlpha, bestAbsX < 65.0 ? 1.0 : 0.0, 1.0);
}
