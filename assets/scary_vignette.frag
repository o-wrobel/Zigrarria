#version 330

in vec2 fragTexCoord;

uniform float radius1;
uniform float radius2;
uniform vec2 center = vec2(1, 0);
uniform vec3 coolColor;

uniform vec2 resolution;
uniform sampler2D texture0;

out vec4 finalColor;

void main() {
	float aspect_ratio = resolution.x/resolution.y;

	vec2 uv = 2*fragTexCoord - 1;
	uv.x *= aspect_ratio;

	vec4 texelColor = texture(texture0, fragTexCoord);
	vec4 my_color = vec4(coolColor, 1);

	float dist = distance(center, uv);

	float vignette_radius1 = 0.;
	float vignette_radius2 = 1.8;

	float vignette = smoothstep(radius1, radius2, dist);

	vec4 redColor = texelColor * my_color;

	finalColor = mix(redColor, redColor* 0.02, vignette);
}
