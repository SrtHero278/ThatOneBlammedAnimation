shader_type canvas_item;

varying flat vec3 TINT;

void vertex() {
	TINT = COLOR.rgb;
	COLOR.rgb = vec3(1.0);
}

void fragment() {
	float diff = COLOR.r - ((COLOR.g + COLOR.b) * 0.5);
	
	COLOR.r = ((COLOR.g + COLOR.b) * 0.5) + (TINT.r * diff);
	COLOR.g = COLOR.g + (TINT.g * diff);
	COLOR.b = COLOR.b + (TINT.b * diff);
}
