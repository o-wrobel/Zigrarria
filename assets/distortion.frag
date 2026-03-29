#version 330

in vec2 fragTexCoord;

uniform vec2 resolution;
uniform sampler2D texture0;

out vec4 finalColor;

void main() {
	float aspect_ratio = resolution.x/resolution.y;
	vec2 uv = 2*fragTexCoord - 1;
	uv.x *= aspect_ratio;

	float freq = 12.5;
	float amp = 0.05;
	float offset = amp * sin(freq * fragTexCoord.y);
	vec4 texelColor = texture(texture0, fragTexCoord + vec2(offset, 0));

	finalColor = texelColor;
}
