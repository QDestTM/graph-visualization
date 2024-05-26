shader_type canvas_item;

uniform vec4 color_base : source_color = vec4(1.0);
uniform vec4 color_fill : source_color = vec4(1.0);

uniform float smoothing: hint_range(0.0, 0.5, 0.01) = 0.05;
uniform float progress: hint_range(-0.5, 1.0, 0.01) = 1.0;

const float a_edge1 = 0.9 / 2.0;
const float a_edge2 = 0.7 / 2.0;

void fragment() {
	float y_shifted = abs(UV.y - 0.5);
	
	float alpha = smoothstep(a_edge1, a_edge2, y_shifted);
	float mask = smoothstep(progress + smoothing, progress, UV.x);
	
	vec4 color = vec4(0.0);
	color += color_base * mask;
	color += color_fill * ( 1.0 - mask );
	
	COLOR = vec4(1.0, 1.0, 1.0, alpha) * color;
}
