shader_type canvas_item;

uniform vec2 camera_pos = vec2(0.0, 0.0);

// Sovereign Biome-Driven Uniforms
uniform vec3 color_top = vec3(0.01, 0.01, 0.04);
uniform vec3 color_bottom = vec3(0.03, 0.01, 0.06);
uniform vec3 accent_1 = vec3(0.1, 0.25, 0.4);
uniform vec3 accent_2 = vec3(0.05, 0.15, 0.3);
uniform float vignette_strength = 0.9;
uniform float seed_val = 0.0;

uniform float anim_speed = 0.3;
uniform float warp_amount = 0.5;

// Hash functions
vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p + seed_val) * 43758.5453123);
}

// Simplex/Value noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(dot(hash2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)), 
                   dot(hash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
               mix(dot(hash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)), 
                   dot(hash2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x), u.y);
}

// Ridged noise for sharp dark veins/dust lanes
float ridged_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float n = mix(mix(dot(hash2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)), 
                      dot(hash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
                  mix(dot(hash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)), 
                      dot(hash2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x), u.y);
    return 1.0 - abs(n);
}

// FBM for glowing gas (soft and ethereal)
float fbm(vec2 x) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(vec2(cos(0.5), sin(0.5)), vec2(-sin(0.5), cos(0.50)));
    for (int i = 0; i < 6; ++i) {
        v += a * (noise(x) * 0.5 + 0.5); // Normalize to 0-1
        x = rot * x * 2.0;
        a *= 0.5;
    }
    return v;
}

// FBM for dark matter dust lanes (sharp and jagged)
float fbm_ridged(vec2 x) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(vec2(cos(0.5), sin(0.5)), vec2(-sin(0.5), cos(0.50)));
    for (int i = 0; i < 5; ++i) {
        v += a * ridged_noise(x);
        x = rot * x * 2.0 + vec2(13.5, 4.2);
        a *= 0.5;
    }
    return v;
}

float hash_1d(vec2 p) {
    return fract(sin(dot(p + seed_val, vec2(12.9898, 78.233))) * 43758.5453);
}

// Generates astrophotography starfields with varied colors
vec3 render_stars(vec2 uv, float density, float star_size, float twinkle_speed) {
    vec2 pos = floor(uv * density);
    vec2 st = fract(uv * density);
    float h = hash_1d(pos);
    
    if (h < 0.92) return vec3(0.0);
    
    float dist = length(st - vec2(0.5));
    float star = smoothstep(star_size, 0.0, dist);
    
    float t = sin(TIME * twinkle_speed + h * 6.28) * 0.5 + 0.5;
    
    // Stellar Class colors (Blue giants, normal white, red dwarfs)
    vec3 color = vec3(1.0);
    float color_hash = fract(h * 133.33);
    if (color_hash > 0.8) color = vec3(0.6, 0.8, 1.0); // Blue giant
    else if (color_hash < 0.2) color = vec3(1.0, 0.6, 0.4); // Red dwarf
    else if (color_hash < 0.4) color = vec3(1.0, 0.9, 0.6); // Yellow sun
    
    float intensity = pow((h - 0.92) * 12.5, 2.0); // Extreme brightness variance
    
    return star * t * intensity * color;
}

void fragment() {
    // 1. Deep Space Void
    vec3 bg_col = mix(color_top, color_bottom, SCREEN_UV.y);
    vec2 base_uv = SCREEN_UV * vec2(1920.0, 1080.0) / 1000.0;
    
    // Rotate the massive galaxy band randomly based on universe seed
    float angle = seed_val * 6.28;
    mat2 rot_band = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));
    
    // True Parallax Vectors (Astronomical Distances)
    vec2 dust_uv     = base_uv + camera_pos * 0.000005;  // Deepest void
    vec2 far_star_uv = base_uv + camera_pos * 0.000015;  // Distant stars
    vec2 nebula_uv   = base_uv + camera_pos * 0.00005;   // The Great Nebula
    vec2 near_star_uv= base_uv + camera_pos * 0.00015;   // Foreground stars
    
    // ==========================================
    // LAYER 1: The Galactic Core and Dark Matter
    // ==========================================
    vec2 warp = vec2(fbm(nebula_uv * 0.5 + TIME * 0.01), fbm(nebula_uv * 0.5 + 4.2 - TIME * 0.01));
    vec2 w_uv = nebula_uv + (warp * 2.0 - 1.0) * 0.3 * warp_amount;
    
    // Calculate the physical shape of the cosmic gas
    float gas1 = fbm(w_uv * 0.8);
    float gas2 = fbm(w_uv * 1.5 + vec2(3.1));
    
    // Calculate sharp, black dark matter dust veins
    float dust_lanes = fbm_ridged(dust_uv * 1.2);
    
    // Sculpt the gas into a massive diagonal Galactic Band
    vec2 rotated_uv = rot_band * w_uv;
    float band = exp(-pow(abs(rotated_uv.y) * 1.2, 1.5));
    
    float total_gas = pow(gas1 * gas2, 1.2) * 3.0;
    total_gas *= mix(0.3, 1.0, band); // Concentrate gas into the core band
    
    // Subtract dust lanes for dramatic splits inside the nebula
    float final_nebula = total_gas * pow(dust_lanes, 1.5);
    
    // Inject Photorealistic HDR Color Palette
    float mask1 = smoothstep(0.1, 0.4, final_nebula);
    float mask2 = smoothstep(0.3, 0.7, final_nebula);
    float core_mask = smoothstep(0.6, 1.0, final_nebula);
    
    vec3 nebula_rgb = mix(bg_col, accent_2 * 0.8, mask1);
    nebula_rgb = mix(nebula_rgb, accent_1 * 1.5, mask2);
    nebula_rgb += vec3(1.0, 0.9, 0.8) * core_mask * 2.5; // Burning core highlight
    
    vec3 out_col = mix(bg_col, nebula_rgb, clamp(final_nebula * 1.5, 0.0, 1.0));
    
    // ==========================================
    // LAYER 2: Ultra-Dense Core Star Clusters
    // ==========================================
    float cluster_mask = smoothstep(0.2, 0.8, total_gas);
    vec3 clusters = render_stars(far_star_uv, 300.0, 0.05, 0.3) * cluster_mask * 2.0;
    out_col += clusters * accent_1; // Light from the gas tints the nearby stars
    
    // ==========================================
    // LAYER 3: Distant Multi-Color Starfield
    // ==========================================
    vec3 far_stars = render_stars(far_star_uv, 120.0, 0.05, 1.0);
    out_col += far_stars;
    
    // ==========================================
    // LAYER 4: Giant Foreground Parallax Stars
    // ==========================================
    vec3 near_stars = render_stars(near_star_uv, 35.0, 0.08, 2.5);
    float halo = render_stars(near_star_uv, 35.0, 0.3, 2.5).r;
    out_col += near_stars * 2.0 + (halo * accent_1 * 0.8);
    
    // ==========================================
    // Cinematic Cosmos Vignette
    // ==========================================
    float vig = 1.0 - length(SCREEN_UV - vec2(0.5)) * vignette_strength;
    out_col *= clamp(vig, 0.0, 1.0);
    
    COLOR = vec4(out_col, 1.0);
}
