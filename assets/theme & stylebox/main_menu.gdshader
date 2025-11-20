shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_radius : hint_range(0.0, 10.0) = 4.0;

void fragment() {
    // textureSize returns ivec2 → convert to vec2
    vec2 size = vec2(textureSize(SCREEN_TEXTURE, 0));

    vec2 uv = SCREEN_UV;

    vec4 col = vec4(0.0);
    float total = 0.0;

    for (float x = -blur_radius; x <= blur_radius; x++) {
        for (float y = -blur_radius; y <= blur_radius; y++) {
            vec2 offset = vec2(x, y) / size;
            col += texture(SCREEN_TEXTURE, uv + offset);
            total += 1.0;
        }
    }

    col /= total;
    COLOR = col;
}
