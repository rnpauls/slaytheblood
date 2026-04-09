shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 1.0;  // 0 = original, 1 = fully grey

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    
    // Weighted grayscale (human eye perception)
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    
    // Mix between original and grayscale
    COLOR.rgb = mix(color.rgb, vec3(gray), strength);
    COLOR.a = color.a;  // Preserve alpha
}