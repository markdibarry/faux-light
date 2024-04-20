shader_type canvas_item;
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

    g_q_size = getQuantizeSize(CANVAS_MATRIX);
    mat4 canvas_matrix = mat4(
        vec4(1,0,0,0),
        vec4(0,1,0,0),
        CANVAS_MATRIX[2],
        CANVAS_MATRIX[3]);
    g_model_matrix = MODEL_MATRIX * canvas_matrix;
    g_texture_size = (1. / TEXTURE_PIXEL_SIZE * c_size) * f;
    VERTEX = (VERTEX * c_size) * f;
    g_vertex = VERTEX;
}

void fragment() {
    COLOR = ditherMask(TEXTURE, UV, SCREEN_TEXTURE, SCREEN_UV, true);
}