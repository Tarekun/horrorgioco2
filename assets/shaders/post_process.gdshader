// Full-screen film grain and vignette, applied over the rendered 3D scene.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

// Strength of the grain, 0 = none.
uniform float grain_intensity : hint_range(0.0, 0.5) = 0.06;
// How many times per second the grain pattern changes.
uniform float grain_rate : hint_range(1.0, 60.0) = 24.0;
// How dark the screen edges get, 0 = no vignette, 1 = black corners.
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.55;
// Distance from the centre (0 centre, 1 corner) where darkening begins.
uniform float vignette_radius : hint_range(0.0, 1.5) = 0.55;
// Width of the falloff from clear to fully dark.
uniform float vignette_softness : hint_range(0.01, 1.5) = 0.6;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;

	float distance_from_centre = length(SCREEN_UV - vec2(0.5)) * 1.41421356;
	float edge = smoothstep(vignette_radius, vignette_radius + vignette_softness, distance_from_centre);
	color *= 1.0 - edge * vignette_intensity;

	float frame = floor(TIME * grain_rate);
	float noise = hash(floor(FRAGCOORD.xy) + vec2(frame * 17.0, frame * 31.0)) - 0.5;
	color += vec3(noise * grain_intensity);

	COLOR = vec4(color, 1.0);
}
