shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform float noise_intensity: hint_range(0.0, 1.0) = 0.05;
uniform float color_bleed: hint_range(0.0, 0.02) = 0.003;
uniform float vignette_strength: hint_range(0.0, 1.0) = 0.3;
uniform float lens_dirt_strength: hint_range(0.0, 1.0) = 0.2;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float t = TIME;
	vec2 uv = SCREEN_UV;

	// Sample screen with RGB color bleed
	vec4 color;
	color.r = texture(SCREEN_TEXTURE, uv + vec2(color_bleed, 0.0)).r;
	color.g = texture(SCREEN_TEXTURE, uv).g;
	color.b = texture(SCREEN_TEXTURE, uv - vec2(color_bleed, 0.0)).b;
	color.a = 1.0;

	// 80s/90s chunky grain
	float grain = rand(vec2(floor(uv.x * 320.0), floor(uv.y * 240.0)) + floor(t * 20.0));
	color.rgb += (grain - 0.5) * noise_intensity;

	// Vignette darkening edges
	vec2 vig = uv * (1.0 - uv);
	float vignette = pow(vig.x * vig.y * 16.0, vignette_strength);
	color.rgb *= vignette;

	// White lens dirt spots
	float dirt = rand(vec2(floor(uv.x * 8.0), floor(uv.y * 5.0)) + 42.0);
	color.rgb += smoothstep(0.96, 1.0, dirt) * lens_dirt_strength;

	// Soft white center glow like old lens
	float glow = 1.0 - length(uv - vec2(0.5)) * 1.5;
	color.rgb += clamp(glow, 0.0, 1.0) * 0.05;

	COLOR = color;
}