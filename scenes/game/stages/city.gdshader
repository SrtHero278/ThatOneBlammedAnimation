shader_type canvas_item;

uniform sampler2D window:repeat_enable;
uniform float uv_add;
varying flat vec4 TINT;

void vertex() {
	TINT = COLOR;
	COLOR = vec4(1.0);
	UV.x += uv_add;
}

void fragment() {
	vec4 window_color = texture(window, UV) * TINT;
	COLOR.rgb = mix(COLOR.rgb, window_color.rgb, window_color.a);
}
