group_uniforms Dithering;
/**Turns the dithering on or off.*/
uniform bool dither_enabled = false;
/**
The Bayer matrix pattern to use
1 -> 2x2, 2 -> 4x4, 3 -> 8x8
*/
uniform int bayer_pattern : hint_range(0, 3) = 1;
/**
Specifies the number of times each color channel should be split.
The higher the number the more colors are allowed. (not applicable if a palette is used)
1 is 3bpp or 8 colors, 2 is 4bpp or 16 colors, etc.
*/
uniform int levels : hint_range(1, 128) = 2;

group_uniforms;

varying flat ivec2 v_bayer_data;
varying flat float v_inv_bayer_data;

const int matrix2[4] = {
    0, 2,
    3, 1
};
const int matrix4[16] = {
    0,  8,  2,  10,
    12, 4,  14, 6,
    3,  11, 1,  9,
    15, 7,  13, 5
};
const int matrix8[64] = {
    0,  32, 8,  40, 2,  34, 10, 42,
    48, 16, 56, 24, 50, 18, 58, 26,
    12, 44, 4,  36, 14, 46, 6,  38,
    60, 28, 52, 20, 62, 30, 54, 22,
    3,  35, 11, 43, 1,  33, 9,  41,
    51, 19, 59, 27, 49, 17, 57, 25,
    15, 47, 7,  39, 13, 45, 5,  37,
    63, 31, 55, 23, 61, 29, 53, 21
};

int getBayerValue(vec2 in_world_vertex, int in_quant_size) {
    int bayer_size = v_bayer_data.x;
    int q_size = max(in_quant_size, 1);
    ivec2 cell = ivec2(floor(in_world_vertex / float(q_size)));
    ivec2 iv = ivec2(cell.x % bayer_size, cell.y % bayer_size);
    int index = iv.x + iv.y * bayer_size;

    switch (bayer_size) {
        case 2:
            return matrix2[index];
        case 4:
            return matrix4[index];
        default:
            return matrix8[index];
    }
}

vec4 _ditherInternal(vec4 in_c, int in_bayer_value) {
    vec3 c = in_c.rgb;
    float a = in_c.a;

    int bayer_squared = v_bayer_data.y;
    float inv_bayer_squared = v_inv_bayer_data;
    float levels_f = max(float(levels) - 1., 1.);

    // normalize the dither value
    float dN = (float(in_bayer_value) * inv_bayer_squared) - 0.5;
    // get the normalizing value for the division gap
    float r = 1. / levels_f;
    float l = r / float(bayer_squared * 2);
    // add dither value to color
    c += r * dN + l;
    // convert normalized color to quantized range
    c *= levels_f;
    return vec4(round(c) / levels_f, a);
}

vec4 dither(vec4 in_color, vec2 in_world_vertex, int in_quant_size) {
    if (!dither_enabled) {
        return in_color;
    }

    int bayer_value = getBayerValue(in_world_vertex, in_quant_size);
    vec4 color = _ditherInternal(in_color, bayer_value);

    return color;
}
