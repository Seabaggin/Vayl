//
//  OrbitSpark.metal
//  Open Lightly
//

#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 orbitSpark(
    float2 position,
    half4 currentColor,
    float2 size,
    float time,
    float borderWidth,
    float cornerRadius,
    float colorMode     // 0.0 = dark, 1.0 = light
) {
    float2 center = size * 0.5;
    float2 p = position - center;

    float2 d = abs(p) - (center - cornerRadius);
    float dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - cornerRadius;

    float borderMask = 1.0 - smoothstep(0.0, 1.5, abs(dist) - borderWidth * 0.5);

    float angle = atan2(p.y, p.x);

    float orbitSpeed = 0.45;
    float orbitAngle = fmod(time * orbitSpeed * 2.0 * M_PI_F, 2.0 * M_PI_F) - M_PI_F;

    float angleDiff = angle - orbitAngle;
    angleDiff = angleDiff - 2.0 * M_PI_F * round(angleDiff / (2.0 * M_PI_F));

    float sparkWidth = 0.7;
    float spark = smoothstep(sparkWidth, 0.0, abs(angleDiff));
    spark = pow(spark, 2.0);

    float t = clamp(angleDiff / sparkWidth + 0.5, 0.0, 1.0);

    // Dark mode colors
    half3 darkA = half3(0.0,  0.76, 1.0);   // cyan    #00C2FF
    half3 darkB = half3(0.42, 0.23, 0.88);  // purple  #6C3AE0
    half3 darkC = half3(1.0,  0.0,  0.42);  // magenta #FF006A

    // Light mode colors (warm aurora)
    half3 lightA = half3(0.42, 0.23, 0.88);  // purple  #6C3AE0
    half3 lightB = half3(1.0,  0.0,  0.42);  // magenta #FF006A
    half3 lightC = half3(0.78, 0.59, 0.04);  // gold    #C8960A

    half3 colorA = mix(darkA, lightA, half(colorMode));
    half3 colorB = mix(darkB, lightB, half(colorMode));
    half3 colorC = mix(darkC, lightC, half(colorMode));

    half3 sparkColor = mix(colorA, colorB, half(t));
    sparkColor = mix(sparkColor, colorC, half(t * t));

    // Hot white core — stays white in both modes
    float core = smoothstep(0.15, 0.0, abs(angleDiff));
    sparkColor = mix(sparkColor, half3(1.0), half(core * 0.5));

    float alpha = spark * borderMask;

    return currentColor + half4(sparkColor * half(alpha), half(alpha));
}
