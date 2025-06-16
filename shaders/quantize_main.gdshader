shader_type canvas_item;

/**
0 = Texture: For use with Sprite2Ds and TextureRects
1 = Screen: For use with ColorRect
2 = Mesh: For use with Mesh textures
*/
uniform int texture_mode : hint_range(0,2) = 0;

#include "res://shaders/quantize.gdshaderinc"

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
}

void fragment() {
    vec2 world_vertex;
    vec4 c;
    
    switch (texture_mode) {
        case 0:
            c = quantizeTexture(TEXTURE, UV, world_vertex);
            break;
        case 1:
            c = quantizeScreen(SCREEN_TEXTURE, SCREEN_UV, v_vertex, world_vertex);
            break;
        case 2:
            c = quantizeMesh(TEXTURE, UV, world_vertex);
            break;
    }
    
    COLOR = c;
}