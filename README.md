# 🚀 Metal Ray Tracer for Godot 4.7 (GDExtension)
### Hardware-Accelerated Metal Ray Tracing Plugin for macOS & iOS (Apple Silicon)

[![Godot Engine](https://img.shields.io/badge/Godot-4.7-blue.svg)](https://godotengine.org/)
[![Metal](https://img.shields.io/badge/Apple-Metal%203-black.svg)](https://developer.apple.com/metal/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Apple Silicon](https://img.shields.io/badge/Architecture-Apple%20Silicon%20(arm64)-orange.svg)](https://www.apple.com/)

**MetalRayTracer** is a high-performance **GDExtension** plugin for **Godot 4.7** that unlocks true hardware-accelerated ray tracing on Apple Silicon (M1/M2/M3/M4 and iOS A17 Pro/M-series) using Apple's native **Metal Raytracing API**.

Designed to be decoupled, portable, and easy to use, it allows game developers to integrate ray-traced reflections, deep water refraction, caustics, and god rays into Godot with a single draggable 3D node.

---

## ✨ Key Features

- **⚡ Hardware Acceleration**: Utilizes Apple Silicon RT acceleration structures (`metal::raytracing::instance_acceleration_structure`) for high frame rates (60+ FPS at 1080p/720p).
- **🌊 Physical Water Optics**: Full volumetric water refraction, variable depth absorption, and dynamic caustics.
- **🪞 PBR Reflections & Mirror Rays**: Physically based ray reflections and multi-bounce laser beams.
- **🎥 Automatic Camera Sync**: The `MetalRayTracer3D` node tracks Godot's active `Camera3D` position, orientation, and FOV dynamically.
- **🧩 Drag-and-Drop Workflow**: No low-level Metal coding required—design your game visually in the Godot Editor.
- **📱 macOS & iOS Ready**: Built with Universal C ABI and GDExtension for cross-Apple platform support.

---

## 🛠️ Architecture

```
SalonGodot/
└── addons/metal_ray_tracer/
    ├── plugin.cfg                  # Plugin metadata for Godot Editor
    ├── plugin.gd                   # Editor lifecycle script
    ├── metal_ray_tracer.gdextension # Native GDExtension library manifest
    ├── core/
    │   ├── MetalRayCore.h          # Universal C ABI header
    │   ├── MetalRayCore.mm         # Native Metal compute pipeline implementation
    │   └── RayShaders.metal        # Hardware ray tracing compute kernels
    ├── src/
    │   ├── metal_ray_tracer_gdextension.cpp  # GDExtension entry point
    │   └── build.sh                # Single-command compilation script
    ├── nodes/
    │   └── metal_ray_tracer_3d.gd  # Node3D with Camera3D sync & Texture output
    └── bin/
        └── libmetal_ray_tracer.macos.dylib   # Compiled native arm64 binary
```

---

## 🚀 Getting Started

### 1. Installation
Clone or copy the `addons/metal_ray_tracer` directory into your Godot 4.7 project:
```bash
git clone https://github.com/developer-lifee/godot-metal-ray-tracer.git
cp -r godot-metal-ray-tracer/addons/metal_ray_tracer path/to/your/project/addons/
```

### 2. Enable the Plugin
In Godot:
1. Open **Project Settings** -> **Plugins**.
2. Find **Metal Ray Tracer** and check **Enable**.

### 3. Add to Your Scene
1. In the Scene panel, click **+ (Add Child Node)**.
2. Search for **`MetalRayTracer3D`** and add it to your scene.
3. (Optional) Assign a `target_camera` and a `target_texture_rect` to display the ray-traced buffer, or enable `create_fullscreen_overlay`.

---

## 🔨 Compiling from Source

To rebuild the native dynamic library on macOS:
```bash
cd addons/metal_ray_tracer/src
./build.sh
```

---

## 📄 License
This project is licensed under the **MIT License** - see the LICENSE file for details.

Developed with ❤️ by **Esteban Avila** ([@developer-lifee](https://github.com/developer-lifee)).
