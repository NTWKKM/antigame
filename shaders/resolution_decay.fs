// Resolution Decay post-process shader
// Driven by the 'intensity' uniform (0.0 = clean, 1.0 = full decay)

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
// Custom uniform sent from main.lua via gfx.shader_uniform("intensity", value)
uniform float intensity;

vec4 effect(vec4 color, sampler2D tex, vec2 texture_coords, vec2 screen_coords) {
    // Scale all effects by intensity (0 = no effect, 1 = full glitch)
    float i = clamp(intensity, 0.0, 1.0);
    
    // Chromatic aberration scaled by intensity
    float ca_amount = 0.008 * i;
    vec2 offset = vec2(ca_amount * sin(time * 10.0), 0.0);
    
    float r = texture2D(tex, texture_coords + offset).r;
    float g = texture2D(tex, texture_coords).g;
    float b = texture2D(tex, texture_coords - offset).b;
    float a = texture2D(tex, texture_coords).a;
    
    vec4 col = vec4(r, g, b, a);
    
    // Noise grain scaled by intensity
    float noise = fract(sin(dot(texture_coords.xy, vec2(12.9898, 78.233))) * 43758.5453);
    col.rgb -= noise * 0.15 * i;
    
    // Scanline effect at high intensity
    if (i > 0.5) {
        float scanline = sin(screen_coords.y * 3.14159 * 2.0) * 0.5 + 0.5;
        col.rgb *= 1.0 - (scanline * 0.2 * (i - 0.5) * 2.0);
    }
    
    // Desaturation at high intensity
    if (i > 0.7) {
        float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
        float desat = (i - 0.7) / 0.3; // 0..1 over the 0.7..1.0 range
        col.rgb = mix(col.rgb, vec3(lum), desat * 0.6);
    }
    
    return col * color;
}
#endif
