#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform vec3 coolColor;
uniform sampler2D texture0;

out vec4 finalColor;

void main()
{
    vec4 texelColor = texture(texture0, fragTexCoord);
    vec3 my_color = coolColor;

    float gray = dot(texelColor.rgb, vec3(0.299, 0.587, 0.114));

    finalColor = vec4(
    	dot(texelColor.r, my_color.r),
    	dot(texelColor.g, my_color.g),
    	dot(texelColor.b, my_color.b),
       	texelColor.a
    );
}
