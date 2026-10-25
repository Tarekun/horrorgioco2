// Tints the edges of the screen, strongest in the corners. Used for the red
// flash when the player is hit; `intensity` is driven from DamageOverlay.
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(0.65, 0.0, 0.0, 1.0);

void fragment() {
	float distance_from_centre = length(UV - vec2(0.5)) * 1.4142;
	float edge = smoothstep(0.35, 1.0, distance_from_centre);
	COLOR = vec4(flash_color.rgb, edge * intensity);
}
