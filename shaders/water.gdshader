shader_type spatial;
render_mode depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 water_color : source_color = vec4(0.08, 0.52, 0.72, 0.85);
uniform vec4 deep_water_color : source_color = vec4(0.02, 0.25, 0.42, 0.95);
uniform float roughness : hint_range(0.0, 1.0) = 0.02;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.2;
uniform float wave_strength : hint_range(0.0, 0.5) = 0.035;

void vertex() {
	float w1 = sin(VERTEX.x * 3.0 + TIME * wave_speed) * cos(VERTEX.z * 2.8 + TIME * wave_speed);
	float w2 = cos(VERTEX.x * 5.2 - TIME * wave_speed * 0.9) * sin(VERTEX.z * 4.6 + TIME * wave_speed * 1.1);
	VERTEX.y += (w1 + w2) * wave_strength;
}

void fragment() {
	vec3 n = normalize(vec3(
		sin(VERTEX.x * 8.0 + TIME * wave_speed) * 0.18 + cos(VERTEX.z * 12.0 - TIME * wave_speed) * 0.08,
		1.0,
		cos(VERTEX.z * 8.0 + TIME * wave_speed) * 0.18 + sin(VERTEX.x * 12.0 + TIME * wave_speed) * 0.08
	));
	NORMAL = n;
	
	// Fresnel factor
	float fresnel = pow(1.0 - clamp(dot(VIEW, NORMAL), 0.0, 1.0), 3.0);
	
	ALBEDO = mix(water_color.rgb, deep_water_color.rgb, 0.25);
	ROUGHNESS = roughness;
	METALLIC = 0.05;
	SPECULAR = 0.8 + fresnel * 0.2;
	ALPHA = mix(0.80, 0.98, fresnel);
}
