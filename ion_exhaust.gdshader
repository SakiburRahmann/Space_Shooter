shader_type canvas_item;

uniform vec4 color_core : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color_tail : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform float speed : hint_range(0.0, 20.0) = 15.0;
uniform float turbulence : hint_range(0.0, 1.0) = 0.4;
uniform float intensity : hint_range(0.0, 5.0) = 2.0;

// High-speed noise generator for engine turbulence
float noise(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    float x = UV.x;
    float y = abs(UV.y - 0.5) * 2.0;
    
    // 1. Kinetic Noise Flow
    vec2 scroll_uv = UV * vec2(1.0, 2.0) - vec2(TIME * speed, 0.0);
    float n = noise(floor(scroll_uv * 20.0) / 20.0);
    
    // 2. Tapered Plume Mask
    // Base is white-hot core, tail is blue/transparent
    float mask = (1.0 - x) * (1.0 - y);
    mask = pow(mask, 1.5 + n * turbulence);
    
    // 3. Dual-Phase Gradient
    // Logic: 0.0-0.3 is Core (White/Cream), 0.3-1.0 is Tail (Blue)
    vec4 final_color = mix(color_tail, color_core, smoothstep(0.8, 0.1, x));
    
    // 4. Intensity & Alpha
    final_color.rgb *= intensity;
    COLOR = vec4(final_color.rgb, mask * final_color.a);
}
