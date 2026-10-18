extends CharacterBody3D

class_name Player

@export var walk_speed: float = 4.0
@export var swim_speed: float = 3.2
@export var jump_velocity: float = 5.2
@export var swim_jump_velocity: float = 3.8

var gravity: float = 9.8
var is_in_water: bool = false
var is_first_person: bool = false

# Tools
enum ToolType { NONE, FLASHLIGHT, LASER, MIRROR }
var held_tool: ToolType = ToolType.NONE

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var first_person_camera: Camera3D = $FirstPersonCamera
@onready var flashlight: SpotLight3D = $Flashlight
@onready var laser_raycast: RayCast3D = $LaserRayCast
@onready var laser_beam: MeshInstance3D = $LaserBeam
@onready var mirror_shield: Node3D = $MirrorShield
@onready var mesh_root: Node3D = $ModelRoot

var joystick_input: Vector2 = Vector2.ZERO

func _ready() -> void:
	if laser_beam:
		laser_beam.visible = false
	if flashlight:
		flashlight.visible = false
	if mirror_shield:
		mirror_shield.visible = false
	update_camera_mode()

func _physics_process(dt: float) -> void:
	# Water buoyant and gravity physics
	if is_in_water:
		velocity.x = lerp(velocity.x, 0.0, 2.2 * dt)
		velocity.z = lerp(velocity.z, 0.0, 2.2 * dt)
		var target_y = -0.35
		var diff = target_y - global_position.y
		if diff > 0:
			velocity.y += diff * 12.0 * dt
			velocity.y *= exp(-dt * 3.5)
		else:
			velocity.y -= 4.5 * dt
	elif not is_on_floor():
		velocity.y -= gravity * dt

	# Input movement
	var input_dir = joystick_input
	if input_dir == Vector2.ZERO:
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	var cam_transform = camera_pivot.global_transform
	var forward = -cam_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var right = cam_transform.basis.x
	right.y = 0
	right = right.normalized()

	var move_dir = (right * input_dir.x + forward * (-input_dir.y)).normalized()
	var current_speed = swim_speed if is_in_water else walk_speed

	if move_dir != Vector3.ZERO:
		velocity.x = move_dir.x * current_speed
		velocity.z = move_dir.z * current_speed
		if not is_first_person and mesh_root:
			var target_rot = atan2(move_dir.x, move_dir.z)
			mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_rot, 14.0 * dt)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * 12.0 * dt)
		velocity.z = move_toward(velocity.z, 0, current_speed * 12.0 * dt)

	move_and_slide()

	# Laser tracking
	if held_tool == ToolType.LASER:
		update_laser()

func jump() -> void:
	if is_in_water:
		velocity.y = swim_jump_velocity
	elif is_on_floor():
		velocity.y = jump_velocity

func toggle_flashlight() -> void:
	if held_tool == ToolType.FLASHLIGHT:
		held_tool = ToolType.NONE
		flashlight.visible = false
	else:
		held_tool = ToolType.FLASHLIGHT
		flashlight.visible = true
		if laser_beam: laser_beam.visible = false
		if mirror_shield: mirror_shield.visible = false

func toggle_laser() -> void:
	if held_tool == ToolType.LASER:
		held_tool = ToolType.NONE
		laser_beam.visible = false
	else:
		held_tool = ToolType.LASER
		laser_beam.visible = true
		if flashlight: flashlight.visible = false
		if mirror_shield: mirror_shield.visible = false

func toggle_mirror() -> void:
	if held_tool == ToolType.MIRROR:
		held_tool = ToolType.NONE
		if mirror_shield: mirror_shield.visible = false
	else:
		held_tool = ToolType.MIRROR
		if mirror_shield: mirror_shield.visible = true
		if laser_beam: laser_beam.visible = false
		if flashlight: flashlight.visible = false

func update_laser() -> void:
	if not laser_raycast: return
	laser_raycast.force_raycast_update()
	if laser_raycast.is_colliding():
		var hit_collider = laser_raycast.get_collider()
		if hit_collider and hit_collider.has_method("take_damage"):
			hit_collider.take_damage(25.0 * get_physics_process_delta_time())

func toggle_camera_mode() -> void:
	is_first_person = not is_first_person
	update_camera_mode()

func update_camera_mode() -> void:
	if is_first_person:
		if first_person_camera: first_person_camera.current = true
		if camera: camera.current = false
		if mesh_root: mesh_root.visible = false
	else:
		if camera: camera.current = true
		if first_person_camera: first_person_camera.current = false
		if mesh_root: mesh_root.visible = true

func rotate_camera(relative: Vector2) -> void:
	camera_pivot.rotate_y(-relative.x * 0.005)
	var spring_arm = $CameraPivot/SpringArm3D
	if spring_arm:
		spring_arm.rotate_x(-relative.y * 0.005)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/2.5, PI/4)
