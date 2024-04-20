shader_type canvas_item;
#include "res://shaders/dither.gdshaderinc"
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

void vertex() {
    g_q_size = getQuantizeSize(CANVAS_MATRIX);
    g_model_matrix = MODEL_MATRIX;
    g_texture_size = 1. / TEXTURE_PIXEL_SIZE;
    g_vertex = VERTEX;
}

void fragment() {
    COLOR = ditherMask(TEXTURE, UV, SCREEN_TEXTURE, SCREEN_UV, false);
}
