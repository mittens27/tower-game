shader_type canvas_item;
render_mode blend_mul;

uniform float softness : hint_range(0.01, 0.5) = 0.2;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec2 uv = UV;

    float edge_x = min(uv.x, 1.0 - uv.x);
    float edge_y = min(uv.y, 1.0 - uv.y);
    float edge = min(edge_x, edge_y);

    // Normalize edge so 0 = edge, 1 = center
    float normalized = edge / 0.5;

    // Feather: fades from center → edge
    float alpha = smoothstep(0.0, softness, normalized);

    alpha *= intensity;

    vec3 dark_color = vec3(0.3, 0.5, 0.7);

    // Blend between no effect and darkness
    vec3 final_color = mix(vec3(1.0), dark_color, alpha);

    COLOR = vec4(final_color, 1.0);
}