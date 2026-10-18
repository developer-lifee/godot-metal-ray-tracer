#!/bin/bash
set -e

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN_DIR="$PLUGIN_DIR/bin"
CORE_DIR="$PLUGIN_DIR/core"
SRC_DIR="$PLUGIN_DIR/src"
GODOT_DIR="$(cd "$PLUGIN_DIR/../.." && pwd)"

mkdir -p "$BIN_DIR"

echo "🔨 Compilando MetalRayCore & GDExtension para macOS (arm64 Apple Silicon)..."
clang++ -shared -fPIC -O3 -std=c++17 -ObjC++ \
  -framework Metal -framework Foundation -framework QuartzCore \
  -I"$GODOT_DIR" \
  -I"$CORE_DIR" \
  "$SRC_DIR/metal_ray_tracer_gdextension.cpp" \
  "$CORE_DIR/MetalRayCore.mm" \
  -o "$BIN_DIR/libmetal_ray_tracer.macos.dylib"

echo "✅ Compilación exitosa: $BIN_DIR/libmetal_ray_tracer.macos.dylib"
