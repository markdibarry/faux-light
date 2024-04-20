group_uniforms Quantization;
uniform float quantize_size : hint_range(0,100, 1.0) = 1;
uniform bool handle_scale;
uniform bool handle_subpixels = true;
group_uniforms;

varying mat4 g_model_matrix;
varying mat4 g_world_to_clip;
varying vec2 g_texture_size;
varying vec2 g_vertex;
varying flat vec2 g_flat_vertex;
varying float g_q_size;

float getQuantizeSize(mat4 canvas_matrix) {
    vec2 g_zoom = vec2(length(canvas_matrix[0].xyz), length(canvas_matrix[1].xyz));
    float q_size = quantize_size;

    if (handle_subpixels && g_zoom.x < 1.) {
        q_size = round(quantize_size * (1. / g_zoom.x));
    }

    return q_size;
}

vec4 quantizeTexture(
    sampler2D in_texture,
    vec2 in_uv,
    out vec2 out_world_vertex
) {
    if (g_q_size == 0.) {
        out_world_vertex = (g_model_matrix * vec4(in_uv * g_texture_size, 0, 1)).xy;
        return texture(in_texture, in_uv);
    }

    float q_size = g_q_size;

    // gets -1 if not flipped, 1 if flipped
    vec2 flipped = sign(g_flat_vertex - g_vertex);
    // gets the offset of the texture
    // adds 1 when flipped
    vec2 offset = g_flat_vertex / g_texture_size;

    vec2 uv = in_uv;
    // add offset so positioned back at 0,0 locally
    // so grid lines up
    uv *= flipped;
    uv = offset - uv;
    // scale to texture size
    uv *= g_texture_size;

    if (handle_scale) { // convert to world space
        uv = (g_model_matrix * vec4(uv, 0, 1)).xy;
    }

    out_world_vertex = uv;
    // quantize to specified pixel size
    uv /= q_size;
    uv = floor(uv) + 0.5;
    uv *= q_size;

    if (handle_scale) { // convert back to local space
        uv = (inverse(g_model_matrix) * vec4(uv, 0, 1)).xy;
    }

    // normalize
    uv /= g_texture_size;
    // remove offset so pixel taken at correct location
    uv = offset - uv;
    uv *= flipped;
    return texture(in_texture, uv);
}

vec4 quantizeMesh(
    sampler2D in_texture,
    vec2 in_uv,
    out vec2 out_world_vertex
) {
    if (g_q_size == 0.) {
        out_world_vertex = (g_model_matrix * vec4(in_uv * g_texture_size, 0, 1)).xy;
        return texture(in_texture, in_uv);
    }

    vec2 offset = g_vertex / g_texture_size;
    vec2 uv = in_uv;
    offset = uv - offset;
    uv -= offset;
    uv *= g_texture_size;

    if (handle_scale) { // convert to world space
        uv = (g_model_matrix * vec4(uv, 0, 1)).xy;
    }

    float q_size = g_q_size;
    out_world_vertex = uv;
    uv /= q_size;
    uv = floor(uv) + 0.5;
    uv *= q_size;

    if (handle_scale) { // convert back to local space
        uv = (inverse(g_model_matrix) * vec4(uv, 0, 1)).xy;
    }

    uv /= g_texture_size;
    uv += offset;
    return texture(in_texture, uv);
}

vec4 quantizeScreen(
    sampler2D in_screen_texture,
    vec2 in_screen_uv,
    vec2 in_vertex,
    out vec2 out_world_vertex
) {
    out_world_vertex = (g_model_matrix * vec4(in_vertex, 0, 1)).xy;

    if (g_q_size == 0.) {
        return texture(in_screen_texture, in_screen_uv);
    }

    vec2 uv = out_world_vertex;
    uv /= g_q_size;
    uv = floor(uv) + 0.5;
    uv *= g_q_size;
    uv = (g_world_to_clip * vec4(uv, 0, 1)).xy;
    uv = uv * 0.5 + 0.5;
    return texture(in_screen_texture, uv);
}