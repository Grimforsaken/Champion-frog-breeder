shader_type canvas_item;

uniform float hue_degrees : hint_range(0.0, 359.0) = 120.0;
uniform float saturation : hint_range(0.0, 1.0) = 0.72;
uniform float color_strength : hint_range(0.0, 1.0) = 0.88;
uniform bool fluorescent = false;

vec3 hsv_to_rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    vec4 src = texture(TEXTURE, UV);
    float luminance = dot(src.rgb, vec3(0.299, 0.587, 0.114));
    vec3 hue_color = hsv_to_rgb(vec3(hue_degrees / 360.0, saturation, 1.0));

    // Keep the grayscale asset's highlights and shadows while replacing its hue.
    vec3 tinted = hue_color * luminance;
    tinted += vec3(max(luminance - 0.72, 0.0)) * 0.65;
    vec3 final_rgb = mix(src.rgb, tinted, color_strength);

    // Fluorescence is a layer on top of inherited base hue, not a replacement hue.
    if (fluorescent) {
        final_rgb += hue_color * pow(luminance, 1.7) * 0.38;
    }

    COLOR = vec4(final_rgb, src.a);
}
