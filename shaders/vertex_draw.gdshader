shader_type canvas_item;
uniform vec4 color : source_color;

const vec2 center = vec2(0.0);

void fragment() {
	vec2 uv = UV - 0.5;
	float d = 1.0 - distance(uv, center);

	COLOR = color * smoothstep(0.5, 0.6, d);
}