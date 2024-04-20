shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

uniform float quantize_size : hint_range(0,100, 1.0) = 1;
uniform bool handle_scale;

varying mat4 g_model_matrix;
varying mat4 g_world_to_clip;
varying vec2 g_texture_size;
varying vec2 g_vertex;
varying flat vec2 g_flat_vertex;
varying vec2 g_zoom;


float triangle(float time, float speed) {
    return abs(mod(time / speed, 2.0) - 1.0);
}

vec4 quantizeMesh(
    sampler2D in_texture,
    vec2 in_uv
) {
    if (quantize_size == 0.) {
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

    //float q_size = g_zoom.x < 1. ? quantize_size * (1. / g_zoom.x) : quantize_size;
    float q_size = quantize_size;

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

void vertex() {
    float c_speed = 1.;
    float c_size = .8;
    float f = 1. - triangle(TIME, c_speed) * 0.07;
    //f = 1.;
    g_zoom = vec2(length(CANVAS_MATRIX[0].xyz), length(CANVAS_MATRIX[1].xyz));

    mat4 canvas_matrix = mat4(
        //g_zoom.x < 1. ? CANVAS_MATRIX[0] : vec4(1, 0, 0, 0),
        //g_zoom.y < 1. ? CANVAS_MATRIX[1] : vec4(0, 1, 0, 0),
        vec4(1,0,0,0),
        vec4(0,1,0,0),
        CANVAS_MATRIX[2],
        CANVAS_MATRIX[3]);
    g_model_matrix = MODEL_MATRIX * canvas_matrix;

    g_texture_size = (1. / TEXTURE_PIXEL_SIZE * c_size) * f;
    VERTEX = (VERTEX * c_size) * f;
    g_vertex = VERTEX;
    g_flat_vertex = VERTEX;
}

void fragment() {
    COLOR = quantizeMesh(TEXTURE, UV);
}