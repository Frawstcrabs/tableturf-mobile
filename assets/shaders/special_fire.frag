#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec2 uOffset;
uniform float uAnimation;
uniform vec4 uFireColor;
uniform sampler2D uFireMask;
uniform sampler2D uFireEffect;

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord();
    vec2 uv = (fragCoord - uOffset) / uSize;

    float fireMask = pow(clamp(1.0, 0.0, texture(uFireMask, vec2(uv.x * 0.85 + 0.1, uv.y)).r + 0.1), 1.2 + uv.y);
    float fireEffect = clamp(1.0, 0.0, texture(uFireEffect, vec2(uv.x, fract(uv.y + uAnimation))).r);
    float colorStrength = 1.0 - ((1.0 - fireMask) / fireEffect);

    fragColor = uFireColor * pow(colorStrength, 0.15) * 1.25;
}