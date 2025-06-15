group_uniforms Quantization;
/**Pixel resolution scale (0 is bypass)*/
uniform int quantize_size : hint_range(0,100) = 1;
/**Ignores scale when determining pixel size*/
uniform bool ignore_scale;
/**Auto-scales the quantize size when zoom is < 1, preventing subpixel artifacts*/
uniform bool limit_subpixels = true;
group_uniforms;

varying mat4 v_model_matrix;
varying mat4 v_inv_model_matrix;
varying mat4 v_world_to_clip;
varying vec2 v_texture_size;
varying vec2 v_vertex;
varying flat vec2 v_flat_vertex;
varying flat int v_quant_size;
varying flat vec2 v_flip;

// gets -1 if not flipped, 1 if flipped
vec2 getFlippedSign(mat4 in_model_matrix) {
    float sign_x = sign(dot(in_model_matrix[0].xyz, vec3(1,0,0)));
    float sign_y = sign(dot(in_model_matrix[1].xyz, vec3(0,1,0)));
    return vec2(sign_x, sign_y) * vec2(-1);
}

int getQuantizeSize(mat4 in_canvas_matrix) {
    float zoom = length(in_canvas_matrix[1].xyz);
    int q_size = quantize_size;

    if (limit_subpixels && zoom < 1.) {
        q_size = int(round(float(quantize_size) * (1. / zoom)));
    }

    return q_size;
}

vec2 snap(vec2 in_uv, float in_q_size) {
    return (floor(in_uv / in_q_size) + 0.5) * in_q_size;
}

vec4 quantizeScreen(
    sampler2D in_screen_texture,
    vec2 in_screen_uv,
    vec2 in_vertex,
    out vec2 out_world_vertex
) {
    out_world_vertex = (v_model_matrix * vec4(in_vertex, 0, 1)).xy;

    if (v_quant_size == 0) {
        return texture(in_screen_texture, in_screen_uv);
    }

    vec2 uv = out_world_vertex;
    uv = snap(uv, float(v_quant_size));
    uv = (v_world_to_clip * vec4(uv, 0, 1)).xy;
    uv = uv * 0.5 + 0.5;
    return texture(in_screen_texture, uv);
}

vec4 quantizeTexture(
    sampler2D in_texture,
    vec2 in_uv,
    out vec2 out_world_vertex
) {
    if (v_quant_size == 0) {
        out_world_vertex = (v_model_matrix * vec4(in_uv * v_texture_size, 0, 1)).xy;
        return texture(in_texture, in_uv);
    }

    vec2 offset = v_flat_vertex / v_texture_size;
    vec2 uv = in_uv;
    // add offset so positioned back at 0,0 locally
    // so grid lines up
    uv *= v_flip;
    uv = offset - uv;
    // scale to texture size
    uv *= v_texture_size;

    if (ignore_scale) { // convert to world space
        uv = (v_model_matrix * vec4(uv, 0, 1)).xy;
    }

    out_world_vertex = uv;
    uv = snap(uv, float(v_quant_size));

    if (ignore_scale) { // convert back to local space
        uv = (v_inv_model_matrix * vec4(uv, 0, 1)).xy;
    }

    // normalize
    uv /= v_texture_size;
    // remove offset so pixel taken at correct location
    uv = offset - uv;
    uv *= v_flip;
    return texture(in_texture, uv);
}

vec4 quantizeMesh(
    sampler2D in_texture,
    vec2 in_uv,
    out vec2 out_world_vertex
) {
    if (v_quant_size == 0) {
        out_world_vertex = (v_model_matrix * vec4(in_uv * v_texture_size, 0, 1)).xy;
        return texture(in_texture, in_uv);
    }

    vec2 offset = v_vertex / v_texture_size;
    vec2 uv = in_uv;
    offset = uv - offset;
    uv -= offset;
    // scale to texture size
    uv *= v_texture_size;

    if (ignore_scale) { // convert to world space
        uv = (v_model_matrix * vec4(uv, 0, 1)).xy;
    }

    out_world_vertex = uv;
    uv = snap(uv, float(v_quant_size));

    if (ignore_scale) { // convert back to local space
        uv = (v_inv_model_matrix * vec4(uv, 0, 1)).xy;
    }

    // normalize
    uv /= v_texture_size;
    // remove offset so pixel taken at correct location
    uv += offset;
    return texture(in_texture, uv);
}