shader_type canvas_item;
group_uniforms Main;
/**
0 = Texture: For use with Sprite2Ds, TextureRects, and Meshes
1 = Screen: For use with ColorRect
*/
uniform int texture_mode : hint_range(0, 1) = 0;
/**
0 = Normal: No alpha change
1 = Alpha black: Outputs alpha as black
2 = Alpha cut: Cuts textures as a mask. Use within CanvasGroup node.
*/
uniform int alpha_mode : hint_range(0, 2) = 0;
group_uniforms;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

#include "res://shaders/quantize.gdshaderinc"
#include "res://shaders/dither.gdshaderinc"
#include "res://shaders/adjustment.gdshaderinc"
#include "res://shaders/palette.gdshaderinc"

void vertex() {
    float zoom = length(CANVAS_MATRIX[1].xyz);
    v_quant_size = getQuantizeSize(zoom);
    v_model_matrix = MODEL_MATRIX;
    mat4 world_to_clip = SCREEN_MATRIX * CANVAS_MATRIX;

    if (texture_mode == 1) {
        v_alt_matrix = world_to_clip;

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
    v_bayer_data.x = bayer_size;
    v_bayer_data.y = bayer_squared;
    v_inv_bayer_data = 1.0 / float(bayer_squared);

    vec2 local_origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0, 1)).xy;
    vec2 clip = (world_to_clip * vec4(local_origin, 0,1)).xy;
    vec2 screen_origin_uv = clip * 0.5 + 0.5;
    vec2 screen_size = vec2(textureSize(SCREEN_TEXTURE, 0));
    vec2 screen_pixel_size = 1. / screen_size * zoom;
    vec2 quant_pixel_size = screen_pixel_size * float(v_quant_size);
    v_screen_data.xy = screen_origin_uv;
    v_screen_data.zw = quant_pixel_size;
}

void fragment() {
    vec4 color;
    vec4 uvResult;

    if (texture_mode == 0) {
        uvResult = getQuantizeTextureUV(UV);
        color = texture(TEXTURE, uvResult.xy);
    } else {
        uvResult = getQuantizeScreenUV(SCREEN_UV);
        color = texture(SCREEN_TEXTURE, uvResult.xy);
    }

    // Set alpha as color
    if (alpha_mode != 0) {
        color.rgb = vec3(1. - color.a);
    }

    // Grayscale for palette
    if (palette_mode == 2 || levels == 1) {
        color.rgb = vec3(getAverage(color.rgb));
    }

    color.rgb = adjust(color.rgb);
    color = dither(color, uvResult.zw, v_quant_size);
    color = paletteSwap(color, float(levels));

    if (alpha_mode != 0) {
        // Set color as alpha
        color = vec4(0, 0, 0, 1. - color.r);

        if (alpha_mode == 2) {
            color = vec4(texture(SCREEN_TEXTURE, SCREEN_UV).rgb, color.a);
        }
    }

    COLOR = color;
}