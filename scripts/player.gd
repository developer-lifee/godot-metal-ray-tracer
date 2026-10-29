extends CharacterBody3D

class_name Player

@export var walk_speed: float = 4.2
@export var swim_speed: float = 3.4
@export var jump_velocity: float = 5.2
@export var swim_jump_velocity: float = 3.8
@export var warp_distance: float = 8.5
@export var warp_cooldown_time: float = 1.2

var gravity: float = 9.8
var is_in_water: bool = false
var is_deep_submerged: bool = false
var is_first_person: bool = false
var is_crouching: bool = false
var is_sliding: bool = false

# Cooldowns y estados
var warp_cooldown_timer: float = 0.0
var slowmo_active: bool = false
var splash_sound_timer: float = 0.0

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
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var joystick_input: Vector2 = Vector2.ZERO

# Posiciones de las 15 rocas de río idénticas al juego original de Swift
const RT_RIVER_ROCKS = [
	Vector3(-2.8, -0.2, -1.8),
	Vector3(-3.2, -0.2, 0.5),
	Vector3(-2.5, -0.2, 2.2),
	Vector3(2.8, -0.2, -2.0),
	Vector3(3.2, -0.2, 0.2),
	Vector3(2.6, -0.2, 2.5),
	Vector3(-1.5, -0.2, 3.8),
	Vector3(1.2, -0.2, 4.0),
	Vector3(-4.0, -0.2, -3.5),
	Vector3(4.2, -0.2, -3.8),
	Vector3(-3.8, -0.2, 3.8),
	Vector3(3.9, -0.2, 3.9),
	Vector3(0.0, -0.2, 4.5),
	Vector3(-4.5, -0.2, 0.0),
	Vector3(4.5, -0.2, 0.0)
]

func _ready() -> void:
	if laser_beam:
		laser_beam.visible = false
	if flashlight:
		flashlight.visible = false
	if mirror_shield:
		mirror_shield.visible = false
	update_camera_mode()

func _physics_process(dt: float) -> void:
	# Cooldowns
	if warp_cooldown_timer > 0.0:
		warp_cooldown_timer -= dt

	# Verificar profundidad real de agua:
	# En la piscina normal (Y > -2.0) el agua no pasa de la cintura, camina erguido.
	# Solo a profundidad abisal (Y <= -2.5) entra en postura de natación flotante 3D.
	if is_in_water:
		is_deep_submerged = (global_position.y <= -2.5)
	else:
		is_deep_submerged = false

	# 1. Comportamiento en Agua
	if is_in_water:
		# Fricción hidrodinámica suave
		velocity.x = lerp(velocity.x, 0.0, 2.0 * dt)
		velocity.z = lerp(velocity.z, 0.0, 2.0 * dt)

		if is_deep_submerged:
			# Flotación 3D en agua profunda
			var target_y = -1.2
			var diff = target_y - global_position.y
			if diff > 0:
				velocity.y += diff * 8.0 * dt
				velocity.y *= exp(-dt * 3.0)
			else:
				velocity.y -= 3.0 * dt
		else:
			# Agua baja (cintura): Gravedad normal reducida, apoyado en el piso de la piscina
			if not is_on_floor():
				velocity.y -= gravity * 0.7 * dt

		# Sonido de chapoteo: SÓLO cuando se desplaza significativamente
		var horizontal_speed = Vector2(velocity.x, velocity.z).length()
		if horizontal_speed > 0.6:
			splash_sound_timer -= dt
			if splash_sound_timer <= 0.0:
				splash_sound_timer = 0.45
				_play_sfx("splash")
		else:
			splash_sound_timer = 0.0 # Quieto -> Silencio total

	# 2. Comportamiento en Cobertura o Tobogán
	elif is_crouching:
		# Inhibir gravedad y salto repetitivo al pegarse a una roca (Fix de bug de golpeteo)
		velocity.y = 0.0
	elif not is_on_floor() and not is_sliding:
		velocity.y -= gravity * dt

	# 3. Detección automática o manual de Cobertura en Rocas
	_check_rock_cover()

	# 4. Dirección de Movimiento
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
	var current_speed = walk_speed
	if is_in_water:
		current_speed = swim_speed
	elif is_crouching:
		current_speed = walk_speed * 0.55

	if move_dir != Vector3.ZERO:
		velocity.x = move_dir.x * current_speed
		velocity.z = move_dir.z * current_speed
		if not is_first_person and mesh_root:
			var target_rot = atan2(move_dir.x, move_dir.z)
			mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_rot, 14.0 * dt)
	elif not is_sliding:
		velocity.x = move_toward(velocity.x, 0, current_speed * 12.0 * dt)
		velocity.z = move_toward(velocity.z, 0, current_speed * 12.0 * dt)

	# 5. Postura visual del modelo
	if mesh_root:
		if is_deep_submerged:
			# Postura inclinada horizontalmente para nado libre
			mesh_root.rotation.x = lerp_angle(mesh_root.rotation.x, deg_to_rad(-75.0), 8.0 * dt)
			mesh_root.position.y = lerp(mesh_root.position.y, 0.4, 8.0 * dt)
		elif is_crouching:
			# Postura agachada de cobertura
			mesh_root.rotation.x = lerp_angle(mesh_root.rotation.x, deg_to_rad(-15.0), 10.0 * dt)
			mesh_root.position.y = lerp(mesh_root.position.y, -0.35, 10.0 * dt)
		else:
			# Postura de pie estándar
			mesh_root.rotation.x = lerp_angle(mesh_root.rotation.x, 0.0, 10.0 * dt)
			mesh_root.position.y = lerp(mesh_root.position.y, 0.0, 10.0 * dt)

	move_and_slide()

	# 6. Actualización del haz láser
	if held_tool == ToolType.LASER:
		update_laser()

	# 7. Check de portal subterráneo si se sumerge a fondo abisal
	if global_position.y <= -3.8:
		_enter_subterranean_realm()

## -----------------------------------------------------------
## MECÁNICAS INTERACTIVAS PORTADAS DE SWIFT
## -----------------------------------------------------------

## Detección táctica de proximidad a las rocas para agacharse/cubrirse
func _check_rock_cover() -> void:
	if is_in_water:
		is_crouching = false
		return

	var near_rock = false
	var player_xz = Vector2(global_position.x, global_position.z)
	for rock_pos in RT_RIVER_ROCKS:
		var rock_xz = Vector2(rock_pos.x, rock_pos.z)
		if player_xz.distance_to(rock_xz) < 1.15:
			near_rock = true
			break

	if near_rock and not is_crouching:
		is_crouching = true
		_play_sfx("cover")
	elif not near_rock and is_crouching:
		is_crouching = false

## Flash Warp (Salto cuántico frontal)
func flash_warp() -> void:
	if warp_cooldown_timer > 0.0:
		return

	warp_cooldown_timer = warp_cooldown_time
	_play_sfx("warp")

	# Dirección del warp según la mirada de la cámara
	var cam_fwd = -camera_pivot.global_transform.basis.z.normalized()
	var start_pos = global_position + Vector3(0, 0.8, 0)
	var target_pos = global_position + cam_fwd * warp_distance

	# Raycast de comprobación espacial
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(start_pos, target_pos + Vector3(0, 0.8, 0))
	query.exclude = [get_rid()]
	var result = space_state.intersect_ray(query)

	if result:
		# Detenerse antes de la colisión
		var hit_pos = result.position
		var normal = result.normal
		global_position = hit_pos + normal * 0.65
		global_position.y -= 0.8
	else:
		global_position = target_pos

	velocity = Vector3.ZERO

## Slow-Mo (Ralentización del tiempo cinematográfica)
func toggle_slowmo() -> void:
	slowmo_active = not slowmo_active
	if slowmo_active:
		Engine.time_scale = 0.25
		_play_sfx("slowmo_on")
	else:
		Engine.time_scale = 1.0
		_play_sfx("slowmo_off")

## Impulso del Trampolín de Clavados
func apply_spring_impulse(force: float = 12.5) -> void:
	velocity.y = force
	# Proyectar ligeramente hacia el centro de la piscina
	velocity.z = clamp(velocity.z + 2.5, -4.0, 4.0)
	_play_sfx("spring")

## Impulso del Tobogán de Agua
func apply_slide_impulse(slide_vector: Vector3) -> void:
	is_sliding = true
	velocity = slide_vector * 14.0

func stop_sliding() -> void:
	is_sliding = false

## Salto
func jump() -> void:
	if is_in_water:
		velocity.y = swim_jump_velocity
		_play_sfx("splash")
	elif is_on_floor() or is_crouching:
		is_crouching = false
		velocity.y = jump_velocity

## Reino Subterráneo / Cámara Espejo
func _enter_subterranean_realm() -> void:
	# Transportar al punto de inicio de la cueva subterránea o de retorno
	global_position = Vector3(0.0, 0.5, 4.0)
	velocity = Vector3.ZERO
	_play_sfx("warp")

## -----------------------------------------------------------
## HERRAMIENTAS Y ACCIONES
## -----------------------------------------------------------

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
		_play_sfx("laser")
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
			hit_collider.take_damage(35.0 * get_physics_process_delta_time())
			_play_sfx("laser_hit")

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

func _play_sfx(kind: String) -> void:
	var sfx = SoundFX.get_instance()
	if not sfx: return
	match kind:
		"laser": sfx.play_laser()
		"laser_hit": sfx.play_laser_hit()
		"splash": sfx.play_splash()
		"spring": sfx.play_spring()
		"warp": sfx.play_warp()
		"slowmo_on": sfx.play_slowmo(true)
		"slowmo_off": sfx.play_slowmo(false)
		"cover": sfx.play_cover()
