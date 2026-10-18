#include "gdextension_interface.h"
#include "../core/MetalRayCore.h"
#include <cstdio>

static GDExtensionInterfaceGetProcAddress g_get_proc_address = nullptr;
static GDExtensionClassLibraryPtr g_library = nullptr;

static void initialize_metal_ray_tracer(void *p_userdata, GDExtensionInitializationLevel p_level) {
    if (p_level == GDEXTENSION_INITIALIZATION_SCENE) {
        printf("[MetalRayTracer GDExtension] Inicializando subsistema Metal Ray Core...\n");
        // Inicializar Metal con resolución base 1280x720
        metal_ray_core_init(1280, 720, "res://addons/metal_ray_tracer/core/RayShaders.metal");
    }
}

static void deinitialize_metal_ray_tracer(void *p_userdata, GDExtensionInitializationLevel p_level) {
    if (p_level == GDEXTENSION_INITIALIZATION_SCENE) {
        printf("[MetalRayTracer GDExtension] Apagando Metal Ray Core...\n");
        metal_ray_core_shutdown();
    }
}

extern "C" {

__attribute__((visibility("default"))) GDExtensionBool metal_ray_tracer_library_init(
    GDExtensionInterfaceGetProcAddress p_get_proc_address,
    GDExtensionClassLibraryPtr p_library,
    GDExtensionInitialization *r_initialization
) {
    g_get_proc_address = p_get_proc_address;
    g_library = p_library;

    r_initialization->minimum_initialization_level = GDEXTENSION_INITIALIZATION_SCENE;
    r_initialization->initialize = initialize_metal_ray_tracer;
    r_initialization->deinitialize = deinitialize_metal_ray_tracer;

    printf("[MetalRayTracer GDExtension] Punto de entrada cargado exitosamente.\n");
    return 1;
}

}
