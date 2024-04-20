shader_type canvas_item;
#include "res://shaders/dither.gdshaderinc"
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

void vertex() {
    g_q_size = getQuantizeSize(CANVAS_MATRIX);
    g_model_matrix = MODEL_MATRIX;
    g_world_to_clip = SCREEN_MATRIX * CANVAS_MATRIX;
    g_vertex = VERTEX;
}

void fragment() {
    COLOR = ditherScreen(SCREEN_TEXTURE, SCREEN_UV, g_vertex);
}
