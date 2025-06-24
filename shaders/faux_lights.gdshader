shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

#include "res://shaders/quantize.gdshaderinc"
#include "res://shaders/dither.gdshaderinc"

float triangle(float time, float speed) {
    return abs(mod(time / speed, 2.0) - 1.0);
}

void vertex() {
    // Change to adjust FPS
    float fps = 1. / 10.0;
    float time = floor(TIME / fps) * fps;
    float c_speed = INSTANCE_CUSTOM.r;
    float c_size = INSTANCE_CUSTOM.g;
    float f = 1.;

    if (c_speed != 0.) {
        f -= triangle(time, c_speed) * 0.07;
    }

    float zoom = length(CANVAS_MATRIX[1].xyz);
    v_quant_size = getQuantizeSize(zoom);
    v_model_matrix = MODEL_MATRIX;
    v_alt_matrix = inverse(MODEL_MATRIX);

    VERTEX = (VERTEX * c_size) * f;
    v_vertex = VERTEX;
    v_texture_data.xy = (1. / TEXTURE_PIXEL_SIZE * c_size) * f;
    // Is texture flipped
    v_texture_data.zw = max(-sign((UV - 0.5) * VERTEX), 0.);
}

void fragment() {
    vec4 uvResult = getQuantizeTextureUV(UV);
    vec4 color = texture(TEXTURE, uvResult.xy);
    // Set alpha as color
    color.rgb = vec3(1. - color.a);
    color = dither(color, uvResult.zw, v_quant_size);
    // Set color as alpha
    color = vec4(0, 0, 0, 1. - color.r);
    // Show background in cutout
    color = vec4(texture(SCREEN_TEXTURE, SCREEN_UV).rgb, color.a);
    COLOR = color;
}