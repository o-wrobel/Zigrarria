#version 330

in vec2 fragTexCoord;

uniform float radius1;
uniform float radius2;
uniform vec2 center = vec2(1, 0);
uniform vec3 coolColor;

uniform vec2 res;
uniform sampler2D texture0;

out vec4 finalColor;

vec3 coolDotProductThing(vec3 col1, vec3 col2) {
	return vec3(
		dot(col1.r, col2.r),
		dot(col1.g, col2.g),
		dot(col1.b, col2.b)
	);
}

void main() {
	vec2 uv = 2*fragTexCoord - 1;
	uv.x *= res.x/res.y;

	vec4 texelColor = texture(texture0, fragTexCoord);
	vec3 my_color = coolColor;

	float dist = distance(center, uv);
	// float dist = length(uv);

	float vignette_radius1 = 0.;
	float vignette_radius2 = 1.8;

	float vignette = smoothstep(radius1, radius2, dist);

	vec4 redColor = vec4(coolDotProductThing(texelColor.rgb, my_color), 1);

	finalColor = mix(redColor, redColor* 0.02, vignette);
}
