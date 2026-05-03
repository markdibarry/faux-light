shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    vec4 sc_color = texture(SCREEN_TEXTURE, SCREEN_UV);
    COLOR = vec4(sc_color.rgb, color.a);
}
