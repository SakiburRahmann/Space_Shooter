shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;
uniform float mix_amount : hint_range(0.0, 1.0) = 0.35;
uniform vec4 color_tint : source_color = vec4(0.05, 0.05, 0.1, 1.0);
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	// 1. Precise Screen Sample with Blur
	vec4 screen_col = textureLod(screen_texture, SCREEN_UV, blur_amount);
	
	// 2. Holographic Tint
	vec4 final_col = mix(screen_col, color_tint, mix_amount);
	
	// 3. Animated Scanlines (The technical look)
	float scanline = sin(UV.y * 300.0 + TIME * 10.0) * 0.05;
	final_col.rgb += scanline;
	
	// 4. Sub-Pixel Interference (Glitch grain)
	float interference = fract(sin(dot(UV + floor(TIME * 20.0), vec2(12.9898, 78.233))) * 43758.5453);
	if (interference > 0.98) {
		final_col.rgb += 0.15; // Random digital pips
	}
	
	// 5. Edge Highlight Projection (Corner Focus)
	float edge = 1.0 - smoothstep(0.0, 0.01, UV.x) * smoothstep(1.0, 0.99, UV.x) * 
	                   smoothstep(0.0, 0.015, UV.y) * smoothstep(1.0, 0.985, UV.y);
	final_col.rgb += edge * 0.4;
	
	// ALPHA: Slight transparency shift
	final_col.a = mix_amount + (scanline * 2.0);
	
	COLOR = final_col;
}
