shader_type canvas_item;

uniform float time_scale: hint_range(0.1, 5.0) = 1.0;
uniform float distortion_strength: hint_range(0.0, 0.05) = 0.01;
uniform float scanline_intensity: hint_range(0.0, 1.0) = 0.3;
uniform float noise_intensity: hint_range(0.0, 1.0) = 0.1;
uniform float color_bleed: hint_range(0.0, 0.02) = 0.005;
uniform float vignette_strength: hint_range(0.0, 1.0) = 0.4;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float t = TIME * time_scale;
	vec2 uv = UV;

	// Horizontal glitch distortion
	float glitch = rand(vec2(floor(uv.y * 80.0), floor(t * 8.0)));
	if (glitch > 0.92) {
		uv.x += (rand(vec2(t, uv.y)) - 0.5) * distortion_strength * 8.0;
	}

	// Subtle wavy distortion
	uv.x += sin(uv.y * 40.0 + t * 3.0) * distortion_strength;
	uv.y += sin(uv.x * 20.0 + t * 2.0) * distortion_strength * 0.5;

	// Color bleed (RGB shift)
	vec4 color;
	color.r = texture(TEXTURE, uv + vec2(color_bleed, 0.0)).r;
	color.g = texture(TEXTURE, uv).g;
	color.b = texture(TEXTURE, uv - vec2(color_bleed, 0.0)).b;
	color.a = texture(TEXTURE, uv).a;

	// Scanlines
	float scanline = sin(uv.y * 800.0) * 0.5 + 0.5;
	color.rgb -= scanline * scanline_intensity;

	// Film grain noise
	float noise = rand(uv + vec2(t, t)) * noise_intensity;
	color.rgb += noise - noise_intensity * 0.5;

	// Vignette
	vec2 vig_uv = uv * (1.0 - uv.yx);
	float vignette = vig_uv.x * vig_uv.y * 15.0;
	vignette = pow(vignette, vignette_strength);
	color.rgb *= vignette;

	// Occasional horizontal line tear
	float tear = rand(vec2(floor(t * 12.0), 0.0));
	if (abs(uv.y - tear) < 0.002) {
		color.rgb = 1.0 - color.rgb;
	}

	COLOR = color;
}
