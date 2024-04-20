#include "res://shaders/quantize.gdshaderinc"
group_uniforms Dithering;
uniform bool dither_enabled = false;
// The Bayer matrix pattern to use
// 1 -> 2x2, 2 -> 4x4, 3 -> 8x8
uniform float bayer_pattern : hint_range(1, 3, 1.0) = 1;
uniform float divisions : hint_range(1, 16, 1.0) = 1.0;
uniform float contrast : hint_range(0, 4) = 1.0;
uniform float shift : hint_range (-1, 1) = 0;
uniform bool grayscale;
uniform bool use_palette;
uniform sampler2D palette;
group_uniforms;

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

int getBayerValue(float dSize, vec2 in_world_vertex) {
    int iDSize = int(dSize);
    float q_size = max(g_q_size, 1.);
    ivec2 iv = ivec2(mod(in_world_vertex, dSize * q_size));
    iv /= int(q_size);
    int index = iv.x + (iv.y * iDSize);

    switch (iDSize) {
        case 2:
            return matrix2[index];
        case 4:
            return matrix4[index];
        default:
            return matrix8[index];
    }
}

vec4 dither_internal(vec4 in_c, vec2 in_world_vertex, bool in_cut_alpha) {
    if (!dither_enabled) {
        return in_c;
    }

    vec4 c = in_c;

    if (in_cut_alpha) {
        c.rgb = vec3(1. - c.a);
    }

    // Get dither size based on matrix selected
    float dSize = pow(2.0, bayer_pattern);
    float dSquared = dSize * dSize;
    // Get space between divisions
    float div = divisions;

    if (use_palette) {
        ivec2 pSize = textureSize(palette, 0);
        pSize /= pSize.y;
        div = float(pSize.x) - 1.0;

        c.rgb = vec3((c.r * 0.299) + (c.g * 0.587) + (c.b * 0.114));
    }

    // add contrast and shift
    c = (c - 0.5 + shift) * contrast + 0.5;
    c = clamp(c, 0.0, 1.0);

    // get dither value
    int d = getBayerValue(dSize, in_world_vertex);

    // normalize the dither value
    float dN = (float(d) / dSquared) - 0.5;
    // get the normalizing value for the division gap
    float r = 1.0 / div;
    float l = r / (dSquared * 2.);

    c += r * dN + l; // add dither value to color
    c *= div; // convert normalized color to quantized range
    c = round(c); // round to nearest available color
    c /= div; // normalize again

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

vec4 ditherScreen(sampler2D in_texture, vec2 in_uv, vec2 in_vertex) {
    vec2 world_vertex;
    vec4 c = quantizeScreen(in_texture, in_uv, in_vertex, world_vertex);
    return dither_internal(c, world_vertex, false);
}

vec4 ditherTexture(sampler2D in_texture, vec2 in_uv) {
    vec2 world_vertex;
    vec4 c = quantizeTexture(in_texture, in_uv, world_vertex);
    return dither_internal(c, world_vertex, false);
}

vec4 ditherMesh(sampler2D in_texture, vec2 in_uv) {
    vec2 world_vertex;
    vec4 c = quantizeMesh(in_texture, in_uv, world_vertex);
    return dither_internal(c, world_vertex, false);
}

vec4 ditherMaskOnly(sampler2D in_texture, vec2 in_uv, bool is_mesh) {
    vec2 world_vertex;
    vec4 c;

    if (is_mesh) {
        c = quantizeMesh(in_texture, in_uv, world_vertex);
    } else {
        c = quantizeTexture(in_texture, in_uv, world_vertex);
    }

    return dither_internal(c, world_vertex, true);
}

vec4 ditherMask(
    sampler2D in_texture,
    vec2 in_uv,
    sampler2D in_screen_texture,
    vec2 in_screen_uv,
    bool is_mesh
) {
    vec4 c = ditherMaskOnly(in_texture, in_uv, is_mesh);

    //if (!dither_enabled) {
        //return c;
    //}

    vec4 bg_c = texture(in_screen_texture, in_screen_uv);
    return vec4(bg_c.rgb, c.a);
}