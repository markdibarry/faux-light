group_uniforms Palette;
/**
0 = No palette: Simple color reduction
1 = Color reduction palette
2 = Palette lookup based on luminence
*/
uniform int palette_mode : hint_range(0,2) = 0;

/**
A palette image or a GradientTexture1D for realtime editing.
Make sure the width of the GradientTexture1D matches the number of colors.
*/
uniform sampler2D palette : filter_nearest, repeat_disable;
group_uniforms;

vec4 paletteSwap(vec4 in_c, float in_levels) {
    if (palette_mode == 0) {
        return in_c;
    }

    vec3 c = in_c.rgb;
    float a = in_c.a;
    float levels_f = float(in_levels) - 1.;
    int index;
    ivec2 palette_size = textureSize(palette, 0);
    int palette_total = palette_size.x * palette_size.y - 1;
    c *= levels_f;

    if (palette_mode == 1) {
        levels_f = levels_f + 1.;
        float levels_f2 = levels_f * levels_f;
        index = int(c.b + (c.g * levels_f) + (c.r * levels_f2));
    } else {
        c.r = (c.r + c.g + c.b) * 0.3333;
        c.r = clamp(c.r / levels_f, 0.0, 1.0);
        index = int(round(c.r * float(palette_total)));
    }

    // handle any height palette
    index = clamp(index, 0, palette_total);
    int col = index % palette_size.x;
    int row = index / palette_size.x ;
    vec2 uv = (vec2(ivec2(col, row)) + 0.5) / vec2(palette_size);
    return texture(palette, uv);
}