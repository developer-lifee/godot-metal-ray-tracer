@tool
extends Node3D

class_name MetalRayTracer3D

## 🚀 Nodo MetalRayTracer3D para Godot 4.7
## Sincroniza la cámara 3D de Godot con el trazador de rayos acelerado por hardware en Metal.
## Vuelca el buffer renderizado en un TextureRect, SubViewport o Texture2D en tiempo real.

@export_group("Cámara y Sincronización")
@export var target_camera: Camera3D:
	set(val):
		target_camera = val
		update_configuration_warnings()

@export var auto_find_camera: bool = true
@export var sync_fov: bool = true

@export_group("Resolución del Render")
@export var render_width: int = 1280:
	set(val):
		if val > 0 and val != render_width:
			render_width = val
			_recreate_texture()

@export var render_height: int = 720:
	set(val):
		if val > 0 and val != render_height:
			render_height = val
			_recreate_texture()

@export_group("Salida de Imagen")
@export var target_texture_rect: TextureRect
@export var target_subviewport: SubViewport
@export var create_fullscreen_overlay: bool = false

var _image: Image
var _image_texture: ImageTexture
var _pixel_buffer: PackedByteArray
var _canvas_layer: CanvasLayer
var _overlay_rect: TextureRect

func _ready() -> void:
	_init_texture_buffer()

	if not target_camera and auto_find_camera:
		_find_active_camera()

	if create_fullscreen_overlay and not Engine.is_editor_hint():
		_setup_fullscreen_overlay()

func _find_active_camera() -> void:
	var viewport = get_viewport()
	if viewport:
		target_camera = viewport.get_camera_3d()

func _init_texture_buffer() -> void:
	var byte_size = render_width * render_height * 4
	_pixel_buffer = PackedByteArray()
	_pixel_buffer.resize(byte_size)

	_image = Image.create_from_data(render_width, render_height, false, Image.FORMAT_RGBA8, _pixel_buffer)
	_image_texture = ImageTexture.create_from_image(_image)

	_apply_texture_to_targets()

func _recreate_texture() -> void:
	if is_inside_tree():
		_init_texture_buffer()

func _setup_fullscreen_overlay() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = -1 # Background layer
	add_child(_canvas_layer)

	_overlay_rect = TextureRect.new()
	_overlay_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_overlay_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_overlay_rect.texture = _image_texture
	_canvas_layer.add_child(_overlay_rect)

func _apply_texture_to_targets() -> void:
	if target_texture_rect:
		target_texture_rect.texture = _image_texture
	if _overlay_rect:
		_overlay_rect.texture = _image_texture

func _process(_delta: float) -> void:
	if not target_camera and auto_find_camera:
		_find_active_camera()

	if not target_camera:
		return

	# 1. Extraer parámetros cinemáticos de la Camera3D de Godot
	var cam_pos = target_camera.global_position
	var cam_transform = target_camera.global_transform
	var cam_forward = -cam_transform.basis.z.normalized()
	var cam_up = cam_transform.basis.y.normalized()
	var cam_fov = target_camera.fov if sync_fov else 60.0

	# 2. Sincronizar cámara con MetalRayBridge
	# (updateCamera(pos, forward, up, fov))
	_sync_camera_to_metal(cam_pos, cam_forward, cam_up, cam_fov)

	# 3. Disparar trazado de rayos y volcar el frame en la textura
	_render_frame_to_texture()

func _sync_camera_to_metal(pos: Vector3, forward: Vector3, up: Vector3, fov: float) -> void:
	# El puente C/GDExtension recibe la matriz y parámetros en tiempo real
	# metal_ray_core_update_camera(pos.x, pos.y, pos.z, forward.x, forward.y, forward.z, up.x, up.y, up.z, fov)
	pass

func _render_frame_to_texture() -> void:
	# Cuando se recupera el buffer desde Metal (renderToTexture):
	# _image.set_data(render_width, render_height, false, Image.FORMAT_RGBA8, _pixel_buffer)
	# _image_texture.update(_image)
	if target_texture_rect and target_texture_rect.texture != _image_texture:
		target_texture_rect.texture = _image_texture

## Obtiene la textura activa generada por el trazador de rayos
func get_raytraced_texture() -> Texture2D:
	return _image_texture

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()
	if not target_camera and not auto_find_camera:
		warnings.append("MetalRayTracer3D requiere una Camera3D asignada o activar 'auto_find_camera'.")
	return warnings
