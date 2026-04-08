shader_type canvas_item;

uniform float softness : hint_range(0.0, 0.5) = 0.05;

void fragment() {
    vec2 uv = UV;

    float edge_x = min(uv.x, 1.0 - uv.x);
    float edge_y = min(uv.y, 1.0 - uv.y);
    float edge = min(edge_x, edge_y);

    float alpha = smoothstep(0.0, softness, edge);

    COLOR = vec4(0.0, 0.0, 0.0, alpha) * COLOR;
}