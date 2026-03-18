//
//  OrbitSpark.metal
//  Open Lightly
//
//  Created by Bryan Jorden on 3/14/26.
//

#include <metal_stdlib>
using namespace metal;

// Orbit spark shader for SwiftUI .colorEffect modifier
// Draws a bright gradient spark that rotates around a rounded rect border

[[ stitchable ]] half4 orbitSpark(
    float2 position,
    half4 currentColor,
    float2 size,
    float time,        // pass in a continuously incrementing value
    float borderWidth, // e.g. 3.0
    float cornerRadius // e.g. 28.0
) {
    // Normalize to center
    float2 center = size * 0.5;
    float2 p = position - center;
    
    // Signed distance to rounded rect
    float2 d = abs(p) - (center - cornerRadius);
    float dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - cornerRadius;
    
    // Border mask: 1.0 on the border ring, 0.0 elsewhere
    float borderMask = 1.0 - smoothstep(0.0, 1.5, abs(dist) - borderWidth * 0.5);
    
    // Angle of current pixel relative to center
    float angle = atan2(p.y, p.x); // -pi to pi
    
    // Orbit angle (rotates over time)
    float orbitSpeed = 1.2; // full rotations per second
    float orbitAngle = fmod(time * orbitSpeed * 2.0 * M_PI_F, 2.0 * M_PI_F) - M_PI_F;
    
    // Angular distance from the spark head
    float angleDiff = angle - orbitAngle;
    // Wrap to [-pi, pi]
    angleDiff = angleDiff - 2.0 * M_PI_F * round(angleDiff / (2.0 * M_PI_F));
    
    // Spark tail: bright at head, fading over ~40 degrees behind
    float sparkWidth = 0.7; // radians of visible tail
    float spark = smoothstep(sparkWidth, 0.0, abs(angleDiff));
    spark = pow(spark, 2.0); // sharpen the falloff
    
    // Color: cyan head -> purple mid -> magenta tail
    float t = clamp(angleDiff / sparkWidth + 0.5, 0.0, 1.0);
    half3 cyan    = half3(0.0, 0.76, 1.0);
    half3 purple  = half3(0.55, 0.27, 1.0);
    half3 magenta = half3(1.0, 0.08, 0.47);
    
    half3 sparkColor = mix(cyan, purple, half(t));
    sparkColor = mix(sparkColor, magenta, half(t * t));
    
    // Hot white core at the very head
    float core = smoothstep(0.15, 0.0, abs(angleDiff));
    sparkColor = mix(sparkColor, half3(1.0), half(core * 0.5));
    
    // Combine: spark on the border only
    float alpha = spark * borderMask;
    
    // Add to existing color (so it layers on top of the static gradient border)
    return currentColor + half4(sparkColor * half(alpha), half(alpha));
}
