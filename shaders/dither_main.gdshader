shader_type canvas_item;

/**
0 = Texture: For use with Sprite2Ds, TextureRects, and Meshes
1 = Screen: For use with ColorRect
*/
uniform int texture_mode : hint_range(0,1) = 0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

#include "res://shaders/dither.gdshaderinc"

void vertex() {
    float zoom = length(CANVAS_MATRIX[1].xyz);
    v_quant_size = getQuantizeSize(zoom);
    v_model_matrix = MODEL_MATRIX;

    if (texture_mode == 1) {
        v_alt_matrix = SCREEN_MATRIX * CANVAS_MATRIX;

        if (!snap_to_world) {
            v_alt_matrix = inverse(v_alt_matrix);
        }
    } else {
        v_alt_matrix = inverse(MODEL_MATRIX);
    }

    v_vertex = VERTEX;
    v_texture_data.xy = 1. / TEXTURE_PIXEL_SIZE;
    v_texture_data.zw = max(-sign((UV - 0.5) * VERTEX), 0.);

    int bayer_size = 1 << bayer_pattern;
    int bayer_squared = bayer_size * bayer_size;
    int adj_divisions = getDivisions();
    v_bayer_data.x = bayer_size;
    v_bayer_data.y = bayer_squared;
    v_bayer_data.z = adj_divisions;
    v_inv_bayer_data.x = 1.0 / float(bayer_squared);
    v_inv_bayer_data.y = 1.0 / float(adj_divisions);

    vec2 local_origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0, 1)).xy;
    vec2 clip = (SCREEN_MATRIX * CANVAS_MATRIX * vec4(local_origin, 0,1)).xy;
    vec2 screen_origin_uv = clip * 0.5 + 0.5;
    vec2 screen_size = vec2(textureSize(SCREEN_TEXTURE, 0));
    vec2 screen_pixel_size = 1. / screen_size * zoom;
    vec2 quant_pixel_size = screen_pixel_size * float(v_quant_size);
    v_screen_data.xy = screen_origin_uv;
    v_screen_data.zw = quant_pixel_size;
}

void fragment() {
    COLOR = dither(TEXTURE, UV, SCREEN_TEXTURE, SCREEN_UV, texture_mode, alpha_mode);
}