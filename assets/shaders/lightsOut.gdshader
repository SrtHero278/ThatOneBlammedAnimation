shader_type canvas_item;

uniform float window_scale = 1.0;
uniform float effect_min = 0.0;
uniform float effect_max = 0.0;

varying flat vec3 TINT;
void vertex() {TINT = COLOR.rgb; COLOR.rgb = vec3(1.0);}

void fragment() {
	float zoom_frag = FRAGCOORD.x * window_scale;
	if (zoom_frag >= effect_min && zoom_frag <= effect_max)
		COLOR.rgb = TINT * (1.0 - smoothstep(0.0, 0.30, COLOR.r + COLOR.g + COLOR.b));
}