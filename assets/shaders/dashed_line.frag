#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec4 uLineColor;
uniform float uDashRatio;
uniform float uDashInterval;
uniform float uIsHorizontal;

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord();
    vec2 uv = fragCoord / uSize;

    float gridLines = 1.0 - step(
        uDashInterval * uDashRatio,
        mod((uIsHorizontal > 0.0 ? uv.x : uv.y), uDashInterval)
    );

    fragColor = uLineColor * gridLines;
}