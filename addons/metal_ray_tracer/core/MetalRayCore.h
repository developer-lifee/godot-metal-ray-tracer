#ifndef METAL_RAY_CORE_H
#define METAL_RAY_CORE_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Represents an instance in the Ray Tracing Acceleration Structure (TLAS)
typedef struct {
    float transform[16];   // 4x4 affine transform (Column-major: m00..m33)
    uint32_t meshId;       // Index of the BLAS mesh geometry
    uint32_t materialId;   // Material parameters index
    uint32_t mask;         // Visibility / ray intersection mask (e.g. 0x01 = visible)
} MetalRayInstance;

// Material definition for PBR and optical surfaces
typedef struct {
    float albedo[4];       // RGBA color
    float normalRoughness[4]; // Normal + Roughness (w)
    float emissionKind[4]; // Emission RGB + Surface Kind (w: 0=solid, 1=glass/water, 2=mirror, etc.)
} MetalRayMaterial;

// Lifecycle Management
bool metal_ray_core_init(int initialWidth, int initialHeight, const char* metalShaderPath);
void metal_ray_core_shutdown(void);
void metal_ray_core_resize(int newWidth, int newHeight);

// 1. updateCamera(pos, forward, up, fov)
void metal_ray_core_update_camera(
    float posX, float posY, float posZ,
    float fwdX, float fwdY, float fwdZ,
    float upX, float upY, float upZ,
    float fovDegrees
);

// 2. updateSceneInstances(transforms, meshes, materials)
void metal_ray_core_update_scene_instances(
    const MetalRayInstance* instances,
    int count
);

// 3. renderToTexture(targetTexture, width, height)
// Renders the hardware ray-traced frame into an RGBA8 buffer for Godot Image/Texture
bool metal_ray_core_render_to_texture(
    uint8_t* outRgbaBuffer,
    int width,
    int height
);

// Optional helper for Godot direct MTLTexture integration
void* metal_ray_core_get_metal_texture_ptr(void);

#ifdef __cplusplus
}
#endif

#endif // METAL_RAY_CORE_H
