shader_type canvas_item;
#include "res://shaders/dither.gdshaderinc"

void vertex() {
    g_q_size = getQuantizeSize(CANVAS_MATRIX);
    g_model_matrix = MODEL_MATRIX;
    g_texture_size = 1. / TEXTURE_PIXEL_SIZE;
    g_vertex = VERTEX;
    g_flat_vertex = VERTEX;
}

void fragment() {
    COLOR = ditherTexture(TEXTURE, UV);
}
