shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform float noise_intensity: hint_range(0.0, 1.0) = 0.12;
uniform float glitch_interval: hint_range(5.0, 60.0) = 20.0;
uniform float glitch_duration: hint_range(0.0, 2.0) = 0.4;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float t = TIME;
	vec2 uv = SCREEN_UV;

	float cycle = mod(t, glitch_interval);
	bool in_glitch = cycle < glitch_duration;
	float glitch_strength = in_glitch ? 1.0 : 0.0;

	float wobble = sin(uv.y * 80.0 + t * 1.5) * 0.0008;
	uv.x += wobble;

	if (in_glitch) {
		float band = floor(uv.y * 12.0 + t * 20.0);
		float shift = (rand(vec2(band, floor(t * 10.0))) - 0.5) * 0.06;
		uv.x += shift;
	}

	uv = clamp(uv, 0.0, 1.0);

	float bleed = 0.002 + glitch_strength * 0.012;
	vec4 color;
	color.r = texture(SCREEN_TEXTURE, uv + vec2(bleed, 0.0)).r;
	color.g = texture(SCREEN_TEXTURE, uv).g;
	color.b = texture(SCREEN_TEXTURE, uv - vec2(bleed, 0.0)).b;
	color.a = 1.0;

	float noise_scale = in_glitch ? 0.25 : noise_intensity;
	float grain = rand(vec2(floor(uv.x * 320.0), floor(uv.y * 240.0)) + floor(t * 24.0));
	color.rgb += (grain - 0.5) * noise_scale;

	float band_noise = rand(vec2(0.0, floor(uv.y * 60.0) + floor(t * 8.0)));
	color.rgb += (band_noise - 0.5) * 0.05;

	float tracking = sin(uv.y * 400.0 + t * 0.3) * 0.5 + 0.5;
	color.rgb *= 1.0 - tracking * 0.04;

	if (in_glitch) {
		float inv_band = floor(uv.y * 10.0 + t * 20.0);
		if (rand(vec2(inv_band, floor(t * 8.0))) > 0.88) {
			color.rgb = 1.0 - color.rgb;
		}
	}

	color.r *= 0.9;
	color.g *= 0.88;
	color.b *= 1.05;

	vec2 vig = uv * (1.0 - uv);
	float vignette = pow(vig.x * vig.y * 16.0, 0.35);
	color.rgb *= vignette;

	color.rgb *= 0.96;

	vec4 original = texture(SCREEN_TEXTURE, SCREEN_UV);
	color.rgb = mix(original.rgb, color.rgb, 0.25);

	COLOR = color;
}