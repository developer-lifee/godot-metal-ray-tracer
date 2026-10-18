#import "MetalRayCore.h"
#import <Metal/Metal.h>
#import <simd/simd.h>
#include <vector>
#include <cmath>
#include <iostream>

#pragma mark - Uniforms Layout (Matching RayShaders.metal)

struct RTUniforms {
    simd_float4 viewport;
    simd_float4 cameraPosition;
    simd_float4 cameraRight;
    simd_float4 cameraUp;
    simd_float4 cameraForward;
    simd_float4 lightPosition;
    simd_float4 lightColor;
    simd_float4 waterSimulation;
    simd_float4 waterImpulse;
    simd_float4 toolOrigin;
    simd_float4 toolDirection;
    simd_float4 toolParameters;
    simd_float4 lightStates;
};

#pragma mark - MetalRayCore Class Definition

@interface MetalRayEngine : NSObject

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLComputePipelineState> raytracePipeline;
@property (nonatomic, strong) id<MTLTexture> outputTexture;
@property (nonatomic, strong) id<MTLBuffer> uniformsBuffer;
@property (nonatomic, strong) id<MTLBuffer> instanceBuffer;

@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) BOOL isInitialized;
@property (nonatomic, assign) BOOL supportsHardwareRT;

- (instancetype)initWithWidth:(int)w height:(int)h shaderPath:(const char*)path;
- (void)resizeWithWidth:(int)w height:(int)h;
- (void)updateCameraWithPos:(simd_float3)pos forward:(simd_float3)fwd up:(simd_float3)up fov:(float)fov;
- (void)updateInstances:(const MetalRayInstance*)instances count:(int)count;
- (BOOL)renderToBuffer:(uint8_t*)outBuffer width:(int)w height:(int)h;

@end

@implementation MetalRayEngine {
    RTUniforms _currentUniforms;
    std::vector<MetalRayInstance> _instances;
}

- (instancetype)initWithWidth:(int)w height:(int)h shaderPath:(const char*)path {
    self = [super init];
    if (!self) return nil;

    _width = (w > 0) ? w : 1280;
    _height = (h > 0) ? h : 720;
    _device = MTLCreateSystemDefaultDevice();
    if (!_device) {
        NSLog(@"[MetalRayCore] Error: Dispositivo Metal no disponible.");
        return nil;
    }

    _commandQueue = [_device newCommandQueue];
    _supportsHardwareRT = [_device supportsFamily:MTLGPUFamilyApple7];

    NSLog(@"[MetalRayCore] GPU: %@ (Hardware Raytracing: %@)",
          _device.name, _supportsHardwareRT ? @"Soportado" : @"Software Emulado");

    // Compilar shaders de Metal
    NSError *error = nil;
    id<MTLLibrary> library = nil;

    if (path != NULL && strlen(path) > 0) {
        NSString *nsPath = [NSString stringWithUTF8String:path];
        NSString *source = [NSString stringWithContentsOfFile:nsPath encoding:NSUTF8StringEncoding error:&error];
        if (source) {
            MTLCompileOptions *options = [MTLCompileOptions new];
            if (@available(macOS 11.0, iOS 14.0, *)) {
                options.languageVersion = MTLLanguageVersion2_4;
            }
            library = [_device newLibraryWithSource:source options:options error:&error];
        }
    }

    if (!library) {
        library = [_device newDefaultLibrary];
    }

    if (library) {
        id<MTLFunction> kernelFunction = [library newFunctionWithName:@"raytracePatio"];
        if (kernelFunction) {
            _raytracePipeline = [_device newComputePipelineStateWithFunction:kernelFunction error:&error];
        }
    }

    // Inicializar Uniforms
    _uniformsBuffer = [_device newBufferWithLength:sizeof(RTUniforms) options:MTLResourceStorageModeShared];
    memset(&_currentUniforms, 0, sizeof(RTUniforms));
    _currentUniforms.viewport = simd_make_float4(_width, _height, tanf(60.0f * M_PI / 360.0f), 0);
    _currentUniforms.lightPosition = simd_make_float4(0.0f, 6.5f, 0.0f, 1.0f);
    _currentUniforms.lightColor = simd_make_float4(1.0f, 0.95f, 0.90f, 1.0f);
    _currentUniforms.lightStates = simd_make_float4(1.0f, 1.0f, 1.0f, 1.0f);

    [self createTextureWithWidth:_width height:_height];
    _isInitialized = YES;

    NSLog(@"[MetalRayCore] Inicializado exitosamente (%dx%d)", _width, _height);
    return self;
}

- (void)createTextureWithWidth:(int)w height:(int)h {
    MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                    width:w
                                                                                   height:h
                                                                                mipmapped:NO];
    desc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;
#if TARGET_OS_OSX
    desc.storageMode = MTLStorageModeManaged;
#else
    desc.storageMode = MTLStorageModeShared;
#endif
    _outputTexture = [_device newTextureWithDescriptor:desc];
}

- (void)resizeWithWidth:(int)w height:(int)h {
    if (w <= 0 || h <= 0) return;
    if (_width == w && _height == h && _outputTexture) return;

    _width = w;
    _height = h;
    [self createTextureWithWidth:_width height:_height];
}

- (void)updateCameraWithPos:(simd_float3)pos forward:(simd_float3)fwd up:(simd_float3)up fov:(float)fov {
    fwd = simd_normalize(fwd);
    simd_float3 right = simd_normalize(simd_cross(fwd, up));
    up = simd_normalize(simd_cross(right, fwd));

    _currentUniforms.cameraPosition = simd_make_float4(pos, 1.0f);
    _currentUniforms.cameraForward = simd_make_float4(fwd, 0.0f);
    _currentUniforms.cameraRight = simd_make_float4(right, 0.0f);
    _currentUniforms.cameraUp = simd_make_float4(up, 0.0f);
    float tanHalfFov = tanf((fov * (float)M_PI / 180.0f) * 0.5f);
    _currentUniforms.viewport = simd_make_float4(_width, _height, tanHalfFov, 0.0f);

    if (_uniformsBuffer) {
        memcpy([_uniformsBuffer contents], &_currentUniforms, sizeof(RTUniforms));
    }
}

- (void)updateInstances:(const MetalRayInstance*)instances count:(int)count {
    if (!instances || count <= 0) return;
    _instances.assign(instances, instances + count);

    size_t byteCount = sizeof(MetalRayInstance) * count;
    if (!_instanceBuffer || _instanceBuffer.length < byteCount) {
        _instanceBuffer = [_device newBufferWithLength:byteCount options:MTLResourceStorageModeShared];
    }
    memcpy([_instanceBuffer contents], instances, byteCount);
}

- (BOOL)renderToBuffer:(uint8_t*)outBuffer width:(int)w height:(int)h {
    if (!_isInitialized || !_commandQueue || !_outputTexture) return NO;
    if (w != _width || h != _height) {
        [self resizeWithWidth:w height:h];
    }

    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    if (_raytracePipeline) {
        id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
        [encoder setComputePipelineState:_raytracePipeline];
        [encoder setTexture:_outputTexture atIndex:0];
        if (_uniformsBuffer) {
            [encoder setBuffer:_uniformsBuffer offset:0 atIndex:0];
        }
        if (_instanceBuffer) {
            [encoder setBuffer:_instanceBuffer offset:0 atIndex:1];
        }

        MTLSize threadgroupSize = MTLSizeMake(16, 16, 1);
        MTLSize threadgroups = MTLSizeMake((_width + 15) / 16, (_height + 15) / 16, 1);
        [encoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadgroupSize];
        [encoder endEncoding];
    }

#if TARGET_OS_OSX
    id<MTLBlitCommandEncoder> blit = [commandBuffer blitCommandEncoder];
    [blit synchronizeTexture:_outputTexture slice:0 level:0];
    [blit endEncoding];
#endif

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    // Copiar al buffer de salida para Godot
    if (outBuffer != NULL) {
        NSUInteger bytesPerRow = _width * 4;
        MTLRegion region = MTLRegionMake2D(0, 0, _width, _height);
        [_outputTexture getBytes:outBuffer bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
    }

    return YES;
}

@end

#pragma mark - C ABI Bridge Implementations

static MetalRayEngine* s_engine = nil;

bool metal_ray_core_init(int initialWidth, int initialHeight, const char* metalShaderPath) {
    if (s_engine != nil) {
        return true;
    }
    @autoreleasepool {
        s_engine = [[MetalRayEngine alloc] initWithWidth:initialWidth height:initialHeight shaderPath:metalShaderPath];
        return (s_engine != nil && s_engine.isInitialized);
    }
}

void metal_ray_core_shutdown(void) {
    @autoreleasepool {
        s_engine = nil;
    }
}

void metal_ray_core_resize(int newWidth, int newHeight) {
    @autoreleasepool {
        [s_engine resizeWithWidth:newWidth height:newHeight];
    }
}

void metal_ray_core_update_camera(
    float posX, float posY, float posZ,
    float fwdX, float fwdY, float fwdZ,
    float upX, float upY, float upZ,
    float fovDegrees
) {
    @autoreleasepool {
        simd_float3 pos = simd_make_float3(posX, posY, posZ);
        simd_float3 fwd = simd_make_float3(fwdX, fwdY, fwdZ);
        simd_float3 up = simd_make_float3(upX, upY, upZ);
        [s_engine updateCameraWithPos:pos forward:fwd up:up fov:fovDegrees];
    }
}

void metal_ray_core_update_scene_instances(const MetalRayInstance* instances, int count) {
    @autoreleasepool {
        [s_engine updateInstances:instances count:count];
    }
}

bool metal_ray_core_render_to_texture(uint8_t* outRgbaBuffer, int width, int height) {
    @autoreleasepool {
        if (!s_engine) return false;
        return [s_engine renderToBuffer:outRgbaBuffer width:width height:height];
    }
}

void* metal_ray_core_get_metal_texture_ptr(void) {
    @autoreleasepool {
        if (!s_engine || !s_engine.outputTexture) return NULL;
        return (__bridge void*)s_engine.outputTexture;
    }
}
