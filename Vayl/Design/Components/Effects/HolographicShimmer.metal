#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

float2 hash22(float2 p) {
    p = float2(dot(p, float2(127.1, 311.7)),
               dot(p, float2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float smoothNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(dot(hash22(i + float2(0,0)), f - float2(0,0)),
            dot(hash22(i + float2(1,0)), f - float2(1,0)), u.x),
        mix(dot(hash22(i + float2(0,1)), f - float2(0,1)),
            dot(hash22(i + float2(1,1)), f - float2(1,1)), u.x),
        u.y
    );
}

float fbm(float2 p) {
    float v = 0.0;
    v += 0.500 * smoothNoise(p * 1.0);
    v += 0.250 * smoothNoise(p * 2.0);
    v += 0.125 * smoothNoise(p * 4.0);
    v += 0.062 * smoothNoise(p * 8.0);
    return v;
}

float4 orbField(float2 uv, float time) {
    // Oil Slick palette — cyan, purple, magenta, gold, deep violet
    // Higher radii than before so orbs overlap more — fuller coverage
    float freqsX[5]  = {0.38, 0.51, 0.63, 0.27, 0.74};
    float freqsY[5]  = {0.30, 0.41, 0.50, 0.21, 0.60};
    float phasesX[5] = {0.0,  2.0,  3.9,  5.0,  1.9};
    float phasesY[5] = {0.0,  2.5,  1.2,  0.7,  4.1};
    float radii[5]   = {0.70, 0.65, 0.60, 0.75, 0.55};

    float4 colors[5] = {
        float4(0.00, 0.76, 1.00, 1.00),  // cyan
        float4(0.42, 0.23, 0.88, 1.00),  // purple
        float4(1.00, 0.00, 0.42, 1.00),  // magenta
        float4(0.78, 0.55, 0.08, 0.85),  // gold
        float4(0.55, 0.00, 1.00, 0.90),  // deep violet
    };

    // Oil slick base — deeper black than inkBase
    float4 result = float4(0.016, 0.012, 0.047, 1.0);

    for (int i = 0; i < 5; i++) {
        float cx = 0.5 + sin(time * freqsX[i] + phasesX[i]) * 0.46;
        float cy = 0.5 + cos(time * freqsY[i] + phasesY[i]) * 0.52;
        float2 delta = uv - float2(cx, cy);
        // Pill is ~6:1 aspect ratio — stretch y significantly so
        // orbs fill the full height rather than pooling at centre
        delta.y *= 0.20;
        float dist = length(delta);
        float r = radii[i];
        float contribution = smoothstep(r, r * 0.15, dist);
        // Screen blend — each orb adds light, never subtracts
        float3 screened = 1.0 - (1.0 - result.rgb) * (1.0 - colors[i].rgb * contribution * colors[i].a);
        result.rgb = screened;
    }
    return result;
}

[[stitchable]]
float2 holoDistort(float2 position,
                   float2 size,
                   float  time) {
    float2 uv = position / size;
    float nx = fbm(uv * 3.2 + float2(time * 0.18, 0.0));
    float ny = fbm(uv * 3.2 + float2(0.0, time * 0.14));
    return position + float2(nx, ny) * 5.0;
}

[[stitchable]]
half4 holoColor(float2 position,
                half4  currentColor,
                float2 size,
                float  time) {
    float2 uv = position / size;

    float4 color = orbField(uv, time);

    // Dark overlay on top of orbs — matches React rgba(4,3,12,0.55).
    // mix(color, inkBase, 0.55) darkens over orbs; previous mix(inkBase, color, 0.85) was inverted.
    float4 inkBase = float4(0.016, 0.012, 0.047, 1.0);
    color = mix(color, inkBase, 0.55);

    // Grain — oil surface texture
    float grain = smoothNoise(uv * 180.0) * 0.500
                + smoothNoise(uv * 340.0) * 0.250
                + smoothNoise(uv * 680.0) * 0.125;
    grain = grain * 0.5 + 0.5;
    color.rgb = mix(color.rgb, color.rgb * (0.88 + grain * 0.24), 0.13);

    // No vignette — clipShape(Capsule()) handles edges

    return half4(color);
}

[[stitchable]]
half4 holoSpecular(float2 position,
                   half4  currentColor,
                   float2 size,
                   float  time) {
    float2 uv    = position / size;
    float specX  = 0.5 + sin(time * 0.38) * 0.42;
    float dist   = abs(uv.x - specX);
    float spec   = smoothstep(0.18, 0.0, dist);
    spec        *= smoothstep(0.0, 0.25, uv.x) * smoothstep(1.0, 0.75, uv.x);
    float spec2X = specX + 0.22;
    float spec2  = smoothstep(0.12, 0.0, abs(uv.x - spec2X)) * 0.35;

    float4 base   = float4(currentColor);
    float4 result = mix(base, float4(1.0), (spec * 0.60 + spec2) * base.a * 0.50);
    return half4(result);
}
