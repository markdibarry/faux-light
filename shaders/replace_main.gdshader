shader_type canvas_item;

// the rendered scene is available through the special SCREEN_TEXTURE
uniform sampler2D palette;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;
varying flat ivec2 v_p_size;

void vertex() {
    v_p_size = textureSize(palette, 0);
}

void fragment() {
    vec4 src_color = texture(SCREEN_TEXTURE, SCREEN_UV);
    vec3 c = src_color.rgb;

    int N = v_p_size.x;
    float fN = float(N);
    float invN = 1.0 / fN;
    float halfTex = 0.5 * invN;
    float bestD = 1e20;
    vec3 bestCol = vec3(0.0);

    for (int i = 0; i < N; i++) {
        float u = float(i) * invN + halfTex;
        vec3  p = texture(palette, vec2(u, 0.5)).rgb;

        vec3 diff = p - c;
        float d = dot(diff, diff);

        if (d < bestD) {
            bestD = d;
            bestCol = p;
        }
    }

    COLOR = vec4(bestCol, src_color.a);
}