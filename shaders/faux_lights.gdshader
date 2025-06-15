shader_type canvas_item;

/**
0 = Texture: For use with Sprite2Ds and TextureRects
1 = Screen: For use with ColorRect
2 = Mesh: For use with Mesh textures.
*/
uniform int texture_mode : hint_range(0,2) = 0;
/**
0 = Normal: No alpha change
1 = Alpha black: Outputs alpha as black
2 = Alpha cut: Cuts textures as a mask. Use with CanvasGroup node.
*/
uniform int alpha_mode : hint_range(0,2) = 0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

#include "res://shaders/dither.gdshaderinc"

float triangle(float time, float speed) {
    return abs(mod(time / speed, 2.0) - 1.0);
}

void vertex() {
    float c_speed = INSTANCE_CUSTOM.r;
    float c_size = INSTANCE_CUSTOM.g;
    float f = 1.;

    if (c_speed != 0.) {
        f = 1. - triangle(TIME, c_speed) * 0.07;
    }

    v_quant_size = getQuantizeSize(CANVAS_MATRIX);
    mat4 canvas_matrix = mat4(
        vec4(1,0,0,0),
        vec4(0,1,0,0),
        CANVAS_MATRIX[2],
        CANVAS_MATRIX[3]);
    v_model_matrix = MODEL_MATRIX * canvas_matrix;
    v_inv_model_matrix = inverse(v_model_matrix);
    v_texture_size = (1. / TEXTURE_PIXEL_SIZE * c_size) * f;
    v_world_to_clip = SCREEN_MATRIX * CANVAS_MATRIX;
    VERTEX = (VERTEX * c_size) * f;
    v_vertex = VERTEX;
    v_flat_vertex = VERTEX;
    v_flip = getFlippedSign(MODEL_MATRIX);
    v_bayer_size = 1 << bayer_pattern;
    v_bayer_squared = v_bayer_size * v_bayer_size;
    v_inv_bayer_squared = 1.0 / float(v_bayer_squared);
    v_divisions = getDivisions();
    v_inv_divisions = 1.0 / float(v_divisions);
}

void fragment() {
    COLOR = dither(TEXTURE, UV, SCREEN_TEXTURE, SCREEN_UV, texture_mode, alpha_mode);
}