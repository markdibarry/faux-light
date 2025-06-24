group_uniforms Adjustment;
/**Modifies the contrast of the image.*/
uniform float contrast : hint_range(0, 4) = 1.0;
/**Shifts the colors higher or lower.*/
uniform float brightness : hint_range (-1, 1) = 0;
/**
When Levels is 1 (black and white), or if Palette mode is 1, the colors are averaged.
This slider mixes between a luminance average, or a normal average.
0 = luminance average
1 = average
*/
uniform float average : hint_range(0.,1.) = 0;
group_uniforms;

const vec3 lum = vec3(0.2126, 0.7152, 0.0722);

float _getAverage(vec3 in_color) {
    float avg = (in_color.r + in_color.g + in_color.b) * 0.3333;
    float lum_avg = dot(in_color, lum);
    return mix(lum_avg, avg, average);
}

vec3 adjust(vec3 in_c, bool in_average) {
    vec3 c = in_c;

    if (in_average) {
        c = vec3(_getAverage(c));
    }

    return (c - 0.5 + brightness) * contrast + 0.5;
}