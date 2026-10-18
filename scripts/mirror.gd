extends MeshInstance3D

@onready var viewport: SubViewport = $SubViewport
@onready var mirror_camera: Camera3D = $SubViewport/MirrorCamera

var mirror_plane: Plane

func _ready() -> void:
	# Mirror plane in world space (normal pointing towards the room: +Z, passing through mirror center)
	var normal = -global_transform.basis.z.normalized()
	mirror_plane = Plane(normal, global_position.dot(normal))
	
	# Assign the viewport texture to the mirror material
	var mat = get_surface_override_material(0)
	if not mat:
		mat = mesh.surface_get_material(0).duplicate()
		set_surface_override_material(0, mat)
	if mat is ShaderMaterial:
		mat.set_shader_parameter("mirror_texture", viewport.get_texture())

func _process(_delta: float) -> void:
	var main_cam = get_viewport().get_camera_3d()
	if not main_cam:
		return
	
	# Normal facing front of mirror
	var n = -global_transform.basis.z.normalized()
	var d = mirror_plane.distance_to(main_cam.global_position)
	
	# Mirror camera position
	mirror_camera.global_position = main_cam.global_position - 2.0 * d * n
	
	# Mirror camera orientation
	var fwd = -main_cam.global_transform.basis.z
	var up = main_cam.global_transform.basis.y
	var ref_fwd = fwd - 2.0 * fwd.dot(n) * n
	var ref_up = up - 2.0 * up.dot(n) * n
	
	mirror_camera.look_at(mirror_camera.global_position + ref_fwd, ref_up)
	mirror_camera.fov = main_cam.fov
