shader_type canvas_item;

/**
0 = Texture: For use with Sprite2Ds, TextureRects, and Meshes
1 = Screen: For use with ColorRect
*/
uniform int texture_mode : hint_range(0,1) = 0;

// This file relies on a quantize shader include file.
// The paths must match your file's location.
#include "res://shaders/quantize.gdshaderinc"

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

void vertex() {
    float zoom = length(CANVAS_MATRIX[1].xyz);
    v_quant_size = getQuantizeSize(zoom);
    v_model_matrix = mat2(MODEL_MATRIX[0].xy, MODEL_MATRIX[1].xy);
    v_model_tr = MODEL_MATRIX[3].xy;
    v_vertex = VERTEX;

    if (texture_mode == 0) {
        mat4 alt_mat = inverse(MODEL_MATRIX);
        v_alt_matrix = mat2(alt_mat[0].xy, alt_mat[1].xy);
        v_alt_tr = alt_mat[3].xy;
        v_texture_data.xy = 1. / TEXTURE_PIXEL_SIZE;
    } else {
        mat4 world_to_clip = SCREEN_MATRIX * CANVAS_MATRIX;

        if (snap_to_world) {
            mat4 inv_wtoc = inverse(SCREEN_MATRIX * CANVAS_MATRIX);
            v_alt_matrix = mat2(inv_wtoc[0].xy, inv_wtoc[1].xy);
            v_alt_tr = inv_wtoc[3].xy;
        } else {
            v_alt_matrix = mat2(world_to_clip[0].xy, world_to_clip[1].xy);
            v_alt_tr = world_to_clip[3].xy;
        }

        vec2 local_origin = v_model_matrix * vec2(0) + v_model_tr;
        vec2 clip = (world_to_clip * vec4(local_origin, 0,1)).xy;
        vec2 screen_origin_uv = clip * 0.5 + 0.5;
        vec2 q = vec2(float(v_quant_size) * zoom);
        v_texture_data.xy = screen_origin_uv;
        v_texture_data.zw = q;
    }
}

void fragment() {
    if (texture_mode == 0) {
        vec4 uvResult = getQuantizeTextureUV(UV);
        COLOR = texture(TEXTURE, uvResult.xy);
    } else {
        vec4 uvResult = getQuantizeScreenUV(SCREEN_UV, SCREEN_PIXEL_SIZE);
        COLOR = texture(SCREEN_TEXTURE, uvResult.xy);
    }
}