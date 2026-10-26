// Health cues drawn over the game: a dark red vignette at the screen edge and a
// desaturation of the whole view. Driven from HealthOverlay.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

// How strongly the edges darken, 0 = not at all, 1 = black corners.
uniform float vignette : hint_range(0.0, 1.0) = 0.0;
// How much colour is drained, 0 = none, 1 = greyscale.
uniform float desaturation : hint_range(0.0, 1.0) = 0.0;
uniform vec4 vignette_color : source_color = vec4(0.12, 0.0, 0.0, 1.0);

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;
	float grey = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(color, vec3(grey), desaturation);

	float distance_from_centre = length(SCREEN_UV - vec2(0.5)) * 1.41421356;
	float edge = smoothstep(0.3, 1.0, distance_from_centre);
	color = mix(color, vignette_color.rgb, edge * vignette);

	COLOR = vec4(color, 1.0);
}
