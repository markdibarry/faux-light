shader_type canvas_item;

/**
0 = Texture: For use with Sprite2Ds and TextureRects
1 = Screen: For use with ColorRect
2 = Mesh: For use with Mesh textures
*/
uniform int texture_mode : hint_range(0,2) = 0;
/**
0 = Normal: No alpha change
1 = Alpha black: Outputs alpha as black
2 = Alpha cut: Cuts textures as a mask. Use with CanvasGroup node.
*/
uniform int alpha_mode : hint_range(0,2) = 0;

#include "res://shaders/dither.gdshaderinc"

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

void vertex() {
    v_quant_size = getQuantizeSize(CANVAS_MATRIX);
    v_model_matrix = MODEL_MATRIX;
    v_inv_model_matrix = inverse(MODEL_MATRIX);
    v_texture_size = 1. / TEXTURE_PIXEL_SIZE;
    v_world_to_clip = SCREEN_MATRIX * CANVAS_MATRIX;
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