shader_type spatial;
// FARR terrain shader (edit freely).
//  - Flat ground uses `ground_*` (+ optional `accent_*` blended in patches by noise to hide tiling).
//  - Steep slopes automatically switch to `cliff_albedo` (triplanar, no stretching).
//  - Optional glowing cracks below `emission_height` (lava, Farr fissures, etc).
// Everything is in world space, so textures never stretch when you sculpt the heightmap.

uniform sampler2D ground_albedo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D ground_normal : hint_normal, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D accent_albedo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D cliff_albedo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;

uniform vec4 ground_tint : source_color = vec4(1.0);
uniform vec4 accent_tint : source_color = vec4(1.0);
uniform vec4 cliff_tint : source_color = vec4(1.0);

uniform float ground_scale = 7.0;   // metres per texture tile
uniform float cliff_scale = 9.0;
uniform float accent_amount : hint_range(0.0, 1.0) = 0.35;
uniform float accent_noise_scale = 0.045;
uniform float slope_start : hint_range(0.0, 1.0) = 0.60; // normal.y below this = full cliff
uniform float slope_end : hint_range(0.0, 1.0) = 0.82;   // normal.y above this = full ground
uniform float roughness_value : hint_range(0.0, 1.0) = 0.92;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.9;

uniform vec4 emission_color : source_color = vec4(1.0, 0.35, 0.05, 1.0);
uniform float emission_height = -999.0;   // world Y below which cracks glow (-999 = off)
uniform float emission_strength = 0.0;
uniform float crack_scale = 0.09;

varying vec3 wpos;
varying vec3 wnrm;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec3 tri_cliff(vec3 p, vec3 n) {
	vec3 bw = pow(abs(n), vec3(4.0));
	bw /= (bw.x + bw.y + bw.z + 0.0001);
	vec2 sx = p.zy / cliff_scale;
	vec2 sy = p.xz / cliff_scale;
	vec2 sz = p.xy / cliff_scale;
	return texture(cliff_albedo, sx).rgb * bw.x + texture(cliff_albedo, sy).rgb * bw.y + texture(cliff_albedo, sz).rgb * bw.z;
}

void fragment() {
	vec2 gp = wpos.xz / ground_scale;
	// two samples at different scale/offset blended by noise = no visible tiling
	float tn = vnoise(wpos.xz * 0.05);
	vec3 g1 = texture(ground_albedo, gp).rgb;
	vec3 g2 = texture(ground_albedo, gp * 0.31 + vec2(0.37, 0.71)).rgb;
	vec3 ground = mix(g1, g2, smoothstep(0.25, 0.75, tn)) * ground_tint.rgb;

	float accent_mask = smoothstep(0.48, 0.62, fbm(wpos.xz * accent_noise_scale));
	vec3 accent = texture(accent_albedo, gp * 1.3 + vec2(0.13, 0.57)).rgb * accent_tint.rgb;
	ground = mix(ground, accent, accent_mask * accent_amount * 2.0);

	// large-scale colour variation
	float macro = 0.80 + 0.40 * fbm(wpos.xz * 0.012);
	ground *= macro;

	vec3 cliff = tri_cliff(wpos, normalize(wnrm)) * cliff_tint.rgb * (0.85 + 0.3 * fbm(wpos.xz * 0.03));

	float cliff_w = 1.0 - smoothstep(slope_start, slope_end, normalize(wnrm).y);
	ALBEDO = mix(ground, cliff, cliff_w);
	ROUGHNESS = roughness_value;
	SPECULAR = 0.25;

	NORMAL_MAP = texture(ground_normal, gp).rgb;
	NORMAL_MAP_DEPTH = normal_strength * (1.0 - cliff_w);

	if (emission_strength > 0.0) {
		float below = 1.0 - smoothstep(emission_height, emission_height + 0.8, wpos.y);
		float c = abs(fbm(wpos.xz * crack_scale) - 0.5);
		float crack = 1.0 - smoothstep(0.0, 0.07, c);
		EMISSION = emission_color.rgb * crack * below * emission_strength;
	}
}
