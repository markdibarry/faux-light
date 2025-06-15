#include "res://shaders/quantize.gdshaderinc"

group_uniforms Dithering;
/**Turns the dithering on or off.*/
uniform bool dither_enabled = false;
/**
The Bayer matrix pattern to use
1 -> 2x2, 2 -> 4x4, 3 -> 8x8
*/
uniform int bayer_pattern : hint_range(1, 3) = 1;
/**
Specifies the number of times each color channel should be split.
The higher the number the more colors are allowed. (not applicable if a palette is used)
1 is 3bpp or 8 colors, 2 is 4bpp or 16 colors, etc.
*/
uniform int divisions : hint_range(1, 16) = 1;
/**Modifies the contrast of the image.*/
uniform float contrast : hint_range(0, 4) = 1.0;
/**Shifts the colors higher or lower.*/
uniform float shift : hint_range (-1, 1) = 0;
/**Turns the resulting image to grayscale.*/
uniform bool grayscale;
/**Switches between arbitrary color reduction and palette based dithering.*/
uniform bool use_palette;
/**
A palette image or a GradientTexture1D for realtime editing.
Make sure the width of the GradientTexture1D matches the number of colors.
*/
uniform sampler2D palette;
group_uniforms;

varying flat int v_bayer_size;
varying flat int v_bayer_squared;
varying float v_inv_bayer_squared;
varying flat int v_divisions;
varying float v_inv_divisions;

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

int getBayerValue(int in_bayer_size, vec2 in_world_vertex) {
    int q_size = max(v_quant_size, 1);
    ivec2 iv = ivec2(mod(in_world_vertex, float(in_bayer_size * q_size)));
    iv /= q_size;
    int index = iv.x + (iv.y * in_bayer_size);

    switch (in_bayer_size) {
        case 2:
            return matrix2[index];
        case 4:
            return matrix4[index];
        default:
            return matrix8[index];
    }
}

int getDivisions() {
    if (use_palette) {
        ivec2 pSize = textureSize(palette, 0);
        pSize /= pSize.y;
        return pSize.x - 1;
    }
    
    return divisions;
}

vec4 _ditherInternal(vec4 in_c, int in_bayer_value, bool in_cut_alpha) {
    if (!dither_enabled) {
        return in_c;
    }

    vec4 c = in_c;

    if (in_cut_alpha) {
        c.rgb = vec3(1. - c.a);
    }

    if (use_palette) {
        c.rgb = vec3((c.r * 0.299) + (c.g * 0.587) + (c.b * 0.114));
    }

    // add contrast and shift
    c = (c - 0.5 + shift) * contrast + 0.5;
    c = clamp(c, 0.0, 1.0);

    // normalize the dither value
    float dN = (float(in_bayer_value) * v_inv_bayer_squared) - 0.5;
    // get the normalizing value for the division gap
    float r = v_inv_divisions;
    float l = r / float(v_bayer_squared * 2);

    c += r * dN + l; // add dither value to color
    // convert normalized color to quantized range
    // round to nearest available color and normalize again
    float div = float(v_divisions);
    c = round(c * div) / div;

    if (use_palette) {
        c.rgb = texture(palette, vec2(c.r, 0.5)).rgb;
    }

    if (grayscale) {
        c.rgb = vec3((c.r + c.g + c.b) / 3.0);
    }

    if (in_cut_alpha) {
        return vec4(vec3(0), 1. - c.r);
    }

    return vec4(c.rgb, c.a);
}

vec4 dither(
    sampler2D in_texture,
    vec2 in_uv,
    sampler2D in_screen_texture,
    vec2 in_screen_uv,
    int in_texture_mode,
    int in_alpha_mode
) {
    vec2 world_vertex;
    vec4 c;
    
    switch (in_texture_mode) {
        case 0:
            c = quantizeTexture(in_texture, in_uv, world_vertex);
            break;
        case 1:
            c = quantizeScreen(in_screen_texture, in_screen_uv, v_vertex, world_vertex);
            break;
        case 2:
            c = quantizeMesh(in_texture, in_uv, world_vertex);
            break;
    }
    
    int bayer_value = getBayerValue(v_bayer_size, world_vertex);
    c = _ditherInternal(c, bayer_value, in_alpha_mode != 0);
    
    if (in_alpha_mode == 2) {
        vec4 bg_c = texture(in_screen_texture, in_screen_uv);
        c = vec4(bg_c.rgb, c.a);
    }
    
    return c;
}
