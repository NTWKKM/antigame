#version 100
precision mediump float;

// Inputs from raylib
varying vec2 fragTexCoord;
varying vec4 fragColor;

// Uniforms
uniform sampler2D texture0;
uniform float intensity;
uniform float u_time;

void main() {
    // Scale all effects by intensity (0 = no effect, 1 = full glitch)
    float i = clamp(intensity, 0.0, 1.0);
    
    // Chromatic aberration scaled by intensity
    float ca_amount = 0.008 * i;
    vec2 offset = vec2(ca_amount * sin(u_time * 10.0), 0.0);
    
    float r = texture2D(texture0, fragTexCoord + offset).r;
    float g = texture2D(texture0, fragTexCoord).g;
    float b = texture2D(texture0, fragTexCoord - offset).b;
    float a = texture2D(texture0, fragTexCoord).a;
    
    vec4 col = vec4(r, g, b, a);
    
    // Noise grain scaled by intensity
    float noise = fract(sin(dot(fragTexCoord.xy, vec2(12.9898, 78.233)) + u_time) * 43758.5453);
    col.rgb -= noise * 0.15 * i;
    
    // Scanline effect at high intensity
    if (i > 0.5) {
        float scanline = sin(fragTexCoord.y * 360.0 * 3.14159) * 0.5 + 0.5;
        col.rgb *= 1.0 - (scanline * 0.2 * (i - 0.5) * 2.0);
    }
    
    // Desaturation at high intensity
    if (i > 0.7) {
        float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
        float desat = (i - 0.7) / 0.3; // 0..1 over the 0.7..1.0 range
        col.rgb = mix(col.rgb, vec3(lum), desat * 0.6);
    }
    
    gl_FragColor = col * fragColor;
}
