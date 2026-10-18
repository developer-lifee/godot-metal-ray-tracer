shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D mirror_texture : source_color, filter_linear_mipmap;
uniform float tint_reflectivity : hint_range(0.0, 1.0) = 0.96;
uniform vec4 mirror_tint : source_color = vec4(0.95, 0.97, 1.0, 1.0);

void fragment() {
    // Horizontally mirrored screen coordinates match the reflected camera viewpoint
    vec2 uv = vec2(1.0 - SCREEN_UV.x, SCREEN_UV.y);
    vec3 ref_color = texture(mirror_texture, uv).rgb;
    
    // Slight silver metallic reflection tint
    ALBEDO = mix(ref_color, ref_color * mirror_tint.rgb, 0.2);
}
