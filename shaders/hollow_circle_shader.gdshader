shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0);

uniform float radius : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float smoothing : hint_range(0.01, 0.1, 0.01) = 0.03;

const vec2 center = vec2(0.0);

void fragment() {
	vec2 uv = (UV - 0.5) * 2.0;
	float d = distance(uv, center);
	
	float mask = 1.0;
	
	mask *= smoothstep(radius-smoothing, radius, d);
	mask *= smoothstep(radius+smoothing, radius, d);
	
	
	COLOR = vec4(color.r, color.g, color.b, mask);
}

