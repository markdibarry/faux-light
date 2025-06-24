shader_type canvas_item;

uniform sampler2D palette;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;
varying flat ivec2 v_palette_size;
varying flat vec2 v_palette_pixel;

void vertex() {
    v_palette_size = textureSize(palette, 0);
    v_palette_pixel = 1. / vec2(v_palette_size);
}

void fragment() {
    vec4 src_color = texture(SCREEN_TEXTURE, SCREEN_UV);
    vec3 c = src_color.rgb;

    vec2 half_tex = 0.5 * v_palette_pixel;
    float best_dis = 1e20;
    vec3 best_col = vec3(0.0);
    vec2 uv = half_tex;
    vec2 p_size = vec2(v_palette_size);

    while (uv.y < p_size.y) {
        while (uv.x < p_size.x) {
            vec3 palette_color = texture(palette, uv).rgb;

            vec3 diff = palette_color - c;
            float dis = dot(diff, diff);

            if (dis < best_dis) {
                best_dis = dis;
                best_col = palette_color;
            }

            uv.x += v_palette_pixel.x;
        }

        uv.x = half_tex.x;
        uv.y += v_palette_pixel.y;
    }

    COLOR = vec4(best_col, src_color.a);
}