shader_type canvas_item;

/**
0 = Texture: For use with Sprite2Ds, TextureRects, and Meshes
1 = Screen: For use with ColorRect
*/
uniform int texture_mode : hint_range(0,1) = 0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

#include "res://shaders/dither.gdshaderinc"

float triangle(float time, float speed) {
    return abs(mod(time / speed, 2.0) - 1.0);
}

void vertex() {
    float fps = 1. / 12.0;
    float time = floor(TIME / fps) * fps;
    float c_speed = INSTANCE_CUSTOM.r;
    float c_size = INSTANCE_CUSTOM.g;
    float f = 1.;

    if (c_speed != 0.) {
        f -= triangle(time, c_speed) * 0.07;
    }

    float zoom = length(CANVAS_MATRIX[1].xyz);
    v_quant_size = getQuantizeSize(zoom);
    v_model_matrix = MODEL_MATRIX;

    if (texture_mode == 1) {
        v_alt_matrix = SCREEN_MATRIX * CANVAS_MATRIX;

        if (snap_to_world) {
            v_alt_matrix = inverse(v_alt_matrix);
        }
    } else {
        v_alt_matrix = inverse(v_model_matrix);
    }


    VERTEX = (VERTEX * c_size) * f;
    v_vertex = VERTEX;
    v_texture_data.xy = (1. / TEXTURE_PIXEL_SIZE * c_size) * f;
    v_texture_data.zw = max(-sign((UV - 0.5) * VERTEX), 0.);

    int bayer_size = 1 << bayer_pattern;
    int bayer_squared = bayer_size * bayer_size;
    int adj_divisions = getDivisions();
    v_bayer_data.x = bayer_size;
    v_bayer_data.y = bayer_squared;
    v_bayer_data.z = adj_divisions;
    v_inv_bayer_data.x = 1.0 / float(bayer_squared);
    v_inv_bayer_data.y = 1.0 / float(adj_divisions);
}

void fragment() {
    COLOR = dither(TEXTURE, UV, SCREEN_TEXTURE, SCREEN_UV, texture_mode, alpha_mode);
}