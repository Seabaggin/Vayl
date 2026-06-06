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

// MARK: - Caustic Layer (OBDeepCardFace)
// Voronoi/Cellular noise caustics: two animated Voronoi layers combined via min()
// on the F2−F1 boundary distance, with sine-fBm domain warping for organic motion.
// Produces a stylised, animated light web suited to Vayl's aesthetic.

float2 cellHash(float2 p) {
    p = float2(dot(p, float2(127.1, 311.7)),
               dot(p, float2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453123);
}

// Returns float2(F1, F2) — distance to nearest and second-nearest cell point.
// F2−F1 is smallest at cell boundaries → the caustic web after thresholding.
// Each cell point traces a Lissajous path so motion is organic and non-repeating.
float2 voronoiF1F2(float2 uv, float time, float speed, float phaseOff) {
    float2 cell = floor(uv);
    float2 frc  = fract(uv);
    float  F1 = 8.0, F2 = 8.0;

    for (int j = -2; j <= 2; j++) {
        for (int i = -2; i <= 2; i++) {
            float2 nb  = float2(float(i), float(j));
            float2 rng = cellHash(cell + nb);
            float  t   = time * speed + phaseOff;
            float2 pt  = nb + float2(
                0.5 + 0.44 * sin(t        + rng.x * 6.2832),
                0.5 + 0.44 * cos(t * 0.73 + rng.y * 6.2832 + 1.3)
            );
            float d = length(pt - frc);
            if      (d < F1) { F2 = F1; F1 = d; }
            else if (d < F2) { F2 = d; }
        }
    }
    return float2(F1, F2);
}

// Three-octave sine domain warp — bends the Voronoi grid into organic curves.
float2 sineWarp(float2 uv, float time, float strength) {
    float2 w = float2(0.0);
    w.x += sin(uv.y * 2.8 + time * 0.36)       * 0.60
         + sin(uv.x * 2.1 + time * 0.27 + 1.1) * 0.40;
    w.y += sin(uv.x * 2.5 + time * 0.31)       * 0.60
         + sin(uv.y * 3.3 + time * 0.21 + 2.3) * 0.40;
    w.x += sin(uv.y * 5.6 + time * 0.59 + 0.7) * 0.22
         + sin(uv.x * 4.3 + time * 0.48 + 3.1) * 0.16;
    w.y += sin(uv.x * 5.1 + time * 0.54 + 1.4) * 0.22
         + sin(uv.y * 6.9 + time * 0.41 + 4.2) * 0.16;
    w.x += sin(uv.y * 11.2 + time * 0.91 + 2.2) * 0.08;
    w.y += sin(uv.x * 9.7  + time * 0.83 + 5.1) * 0.08;
    return uv + w * strength;
}

[[stitchable]]
half4 causticLayer(float2 position,
                   half4  currentColor,   // ignored — fully computed from UV
                   float2 resolution,
                   float  time,
                   float  scale,          // ~4.5  Voronoi cell density
                   float  threshold,      // ~0.82 line width (higher = thinner/darker)
                   float  warpStrength,   // ~0.25 domain warp magnitude
                   float  speed1,         // ~0.15 layer 1 drift speed
                   float  speed2,         // ~0.20 layer 2 drift speed
                   float  sharpness,      // ~4.0  contrast curve power
                   float  alphaScale)     // ~0.85 overall brightness
{
    float2 uv       = position / resolution;
    float2 warpedUV = sineWarp(uv, time, warpStrength);

    // Two Voronoi layers — 1.37× scale ratio avoids moiré
    float2 v1  = voronoiF1F2(warpedUV * scale,        time, speed1, 0.00);
    float2 v2  = voronoiF1F2(warpedUV * scale * 1.37, time, speed2, 1.80);

    // min() of both boundary distances gives the intersecting filament network
    float web    = min(v1.y - v1.x, v2.y - v2.x);
    float caustic = 1.0 - smoothstep(0.0, threshold, web);
    caustic       = pow(caustic, sharpness);

    // Radial vignette — full glow at centre, fade at card rim
    float2 d       = (uv - float2(0.5)) / 0.65;
    float vignette = max(0.0, 1.0 - dot(d, d));
    caustic       *= vignette;

    if (caustic < 0.004) return half4(0.0);

    // Color ramp: deep indigo → spectrum purple → lavender-white peaks
    float3 deepCol   = float3(0.08, 0.02, 0.22);
    float3 midCol    = float3(0.38, 0.18, 0.82);
    float3 brightCol = float3(0.80, 0.72, 1.00);

    float3 col = caustic < 0.5
        ? mix(deepCol,  midCol,    caustic * 2.0)
        : mix(midCol,   brightCol, (caustic - 0.5) * 2.0);

    // Premultiplied alpha for .blendMode(.screen)
    float alpha = caustic * alphaScale;
    return half4(half3(col * alpha), half(alpha));
}

// MARK: - HTML Caustics (OBDeepCardFace)
// Direct port of the reference HTML shader.
// Folded Simplex fBm: layers of gradient noise folded via (1 − |n|), which
// creates sharp bright ridges wherever the smooth field crosses zero — the
// fluid, overlapping light rays seen in the HTML reference.
// hash22 reused from top of file (already declared above).

// 2D Simplex noise — smooth gradient noise on a triangular grid.
float snoise(float2 p) {
    const float K1 = 0.366025404;  // (sqrt(3)−1)/2
    const float K2 = 0.211324865;  // (3−sqrt(3))/6
    float2 i = floor(p + (p.x + p.y) * K1);
    float2 a = p - i + (i.x + i.y) * K2;
    float2 o = (a.x > a.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float2 b = a - o + K2;
    float2 c = a - 1.0 + 2.0 * K2;
    float3 h = max(0.5 - float3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    float3 n = h * h * h * h * float3(dot(a, hash22(i)),
                                      dot(b, hash22(i + o)),
                                      dot(c, hash22(i + 1.0)));
    return dot(n, float3(70.0));
}

// fBm built on simplex noise — named fbmS to avoid collision with the
// value-noise fbm() already declared above.
float fbmS(float2 p, float t, int octaves) {
    float v = 0.0, a = 0.5, f = 1.0, mx = 0.0;
    for (int i = 0; i < octaves; i++) {
        v  += snoise(p * f + float2(t * 0.09 * f, t * 0.07 * f)) * a;
        mx += a;
        a  *= 0.50;
        f  *= 2.1;
    }
    return v / mx;
}

[[stitchable]]
half4 htmlCaustics(float2 position,
                   half4  color,
                   float2 size,
                   float  time,
                   float  scale,      // ~0.014 world-pt frequency (matches HTML)
                   float  threshold)  // ~0.78  only bright ridge peaks survive
{
    float2 p = position * scale;

    // Sinkhole distortion — steep pow() curve concentrates the warp in the core.
    // Centre shrinks aggressively (reads as far away), edges stay near the surface.
    float2 center    = size * 0.5 * scale;
    float2 delta     = p - center;
    float  maxRadius = max(size.x, size.y) * 0.5 * scale;
    float  dist      = clamp(length(delta) / maxRadius, 0.0, 1.0);
    p = center + delta * (1.0 + 1.2 * pow(1.0 - dist, 2.5));

    // Light domain warp — breaks geometric regularity without smearing
    float wx = snoise(p * 0.6 + float2(2.1, 8.4)) * 0.18;
    float wy = snoise(p * 0.6 + float2(7.3, 1.6)) * 0.18;

    // 4-octave fBm at warped coordinates
    float n      = fbmS(p + float2(wx, wy), time * 0.9, 4);

    // The fold — creates sharp bright ridges at zero crossings of the noise
    float folded = 1.0 - abs(n);
    if (folded < threshold) return half4(0.0);

    float norm = (folded - threshold) / (1.0 - threshold);

    // Dual power curve: soft diffuse glow + tight bright core
    float b = min(1.0, pow(norm, 1.6) * 0.40 + pow(norm, 3.5) * 0.85);

    // Radial vignette
    float dx  = (position.x - size.x * 0.5) / (size.x * 0.58);
    float dy  = (position.y - size.y * 0.5) / (size.y * 0.58);
    float fin = b * max(0.0, 1.0 - (dx * dx + dy * dy));
    if (fin < 0.008) return half4(0.0);

    // Color ramp — deep purple → lavender-white (matches HTML palette)
    float mv = min(1.0, fin * 1.5);
    float r  = mix( 85.0 / 255.0, 228.0 / 255.0, mv);
    float g  = mix( 30.0 / 255.0, 195.0 / 255.0, mv);
    float bl = mix(190.0 / 255.0, 255.0 / 255.0, mv);

    // Alpha matches HTML's 140/255 ceiling
    float a = pow(fin, 0.70) * (140.0 / 255.0);
    return half4(half(r * a), half(g * a), half(bl * a), half(a));
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
