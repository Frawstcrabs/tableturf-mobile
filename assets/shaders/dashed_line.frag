#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec4 uLineColor;
uniform float uDashLength;
uniform float uDashRatio;
uniform float uIsHorizontal;
uniform float uTileCount;

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord();
    vec2 uv = fragCoord / uSize;

    float gridInterval = 1.0 / uTileCount;
    float gridLines = 1.0 - step(
        gridInterval * uDashLength * uDashRatio,
        mod((uIsHorizontal > 0.0 ? uv.x : uv.y), gridInterval * uDashLength)
    );

    fragColor = uLineColor * gridLines;
}