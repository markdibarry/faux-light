group_uniforms Quantization;
/**Pixel resolution scale (0 is bypass)*/
uniform int quantize_size : hint_range(0,100) = 1;
/**Pixels are snapped based on world coordinates vs local coordinates.*/
uniform bool snap_to_world;
/**Auto-scales the quantize size when zoom is < 1, preventing subpixel artifacts*/
uniform bool limit_subpixels = true;
group_uniforms;

varying mat4 v_model_matrix;
varying mat4 v_alt_matrix;
varying flat vec4 v_texture_data;
varying vec2 v_vertex;
varying flat int v_quant_size;
varying flat vec4 v_screen_data;

const float EPSILON = 0.0001;

int getQuantizeSize(float zoom) {
    int q_size = quantize_size;

    if (limit_subpixels && zoom < 1.) {
        q_size = int(round(float(quantize_size) * (1. / zoom)));
    }

    return q_size;
}

vec2 snap(vec2 in_uv, float in_q_size) {
    return (floor(in_uv / in_q_size) + 0.5) * in_q_size;
}

vec4 getQuantizeScreenUV(vec2 in_screen_uv) {
    vec4 result;

    if (v_quant_size == 0) {
        result.xy = in_screen_uv;
        result.zw = (v_model_matrix * vec4(v_vertex, 0, 1)).xy;
        return result;
    }

    vec2 uv;

    if (snap_to_world) {
        vec2 world_uv = (v_model_matrix * vec4(v_vertex, 0, 1)).xy;
        result.zw = world_uv;
        world_uv = snap(world_uv, float(v_quant_size));
        vec2 clip = (v_alt_matrix * vec4(world_uv, 0,1)).xy;
        uv = clip * 0.5 + 0.5;
    } else {
        vec2 origin_uv = v_screen_data.xy;
        vec2 quant_pixel_size = v_screen_data.zw;
        vec2 shifted = in_screen_uv - origin_uv;
        vec2 stepped = (floor(shifted / quant_pixel_size) + 0.5) * quant_pixel_size;
        uv = stepped + origin_uv;
        vec2 clipXY = uv * 2.0 - 1.;
        vec2 world_pos = (v_alt_matrix * vec4(clipXY, 0.0, 1.0)).xy;
        result.zw = world_pos + EPSILON;
    }

    result.xy = uv;
    return result;
}

vec4 getQuantizeTextureUV(vec2 in_uv) {
    vec4 result;
    vec2 texture_size = v_texture_data.xy;
    vec2 flip = v_texture_data.zw;

    if (v_quant_size == 0) {
        result.xy = in_uv;
        result.zw = (v_model_matrix * vec4(in_uv * texture_size, 0, 1)).xy;
        return result;
    }

    vec2 offset;
    float q = float(v_quant_size);
    vec2 uv = in_uv;
    uv = mix(uv, 1.0 - uv, flip);

    if (snap_to_world) {
        offset = v_vertex / texture_size;
        offset = uv - offset;
        uv -= offset;
        uv *= texture_size;
        uv = (v_model_matrix * vec4(uv, 0, 1)).xy;
    } else {
        uv *= texture_size;
    }

    result.zw = uv;
    uv = (floor(uv / q) + 0.5) * q;

    if (snap_to_world) {
        uv = (inverse(v_model_matrix) * vec4(uv, 0, 1)).xy;
        uv /= texture_size;
        uv = offset + uv;
    } else {
        uv /= texture_size;
    }

    uv = mix(uv, 1.0 - uv, flip);
    result.xy = uv + EPSILON;
    return result;
}
