shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform bool mask;
uniform int fps = 10;
instance uniform float speed : hint_range(0.0, 5.0);

#include "res://shaders/quantize.gdshaderinc"
#include "res://shaders/dither.gdshaderinc"

float triangle(float in_time, float in_speed) {
    return abs(mod(in_time / in_speed, 2.0) - 1.0);
}

void vertex() {
    // Change to adjust FPS
    float fps_f = 1. / float(fps);
    float time = floor(TIME / fps_f) * fps_f;
    float f = 1.;

    if (speed != 0.) {
        f -= triangle(time, speed) * 0.07;
    }

    float zoom = length(CANVAS_MATRIX[1].xyz);
    v_quant_size = getQuantizeSize(zoom);
    v_model_matrix = MODEL_MATRIX;
    v_alt_matrix = inverse(MODEL_MATRIX);

    VERTEX = VERTEX * f;
    v_vertex = VERTEX;
    v_texture_data.xy = (1. / TEXTURE_PIXEL_SIZE) * f;
    // Is texture flipped
    v_texture_data.zw = max(-sign((UV - 0.5) * VERTEX), 0.);
}

void fragment() {
    vec4 uvResult = getQuantizeTextureUV(UV);
    vec4 color = texture(TEXTURE, uvResult.xy);
    // Set alpha as color
    if (mask) {
        color.rgb = vec3(1. - color.a);
    }

    color = dither(color, uvResult.zw, v_quant_size);

    if (mask) {
        // Set color as alpha
        color = vec4(0, 0, 0, 1. - color.r);
        // Show background in cutout
        color = vec4(texture(SCREEN_TEXTURE, SCREEN_UV).rgb, color.a);
    }

    COLOR = color;
}