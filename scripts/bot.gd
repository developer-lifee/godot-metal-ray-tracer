extends CharacterBody3D

class_name Bot

@export var max_health: float = 50.0
var health: float = 50.0
var speed: float = 2.4
var target: Node3D = null

@onready var laser_mesh: MeshInstance3D = $BeamMesh
var fire_timer: float = 0.0

func _ready() -> void:
	health = max_health
	if laser_mesh:
		laser_mesh.visible = false

func _physics_process(dt: float) -> void:
	if not target:
		target = get_tree().get_first_node_in_group("player")
		return

	var dist = global_position.distance_to(target.global_position)
	if dist > 1.8:
		var dir = (target.global_position - global_position).normalized()
		dir.y = 0
		velocity = dir * speed
		look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
	else:
		velocity = Vector3.ZERO

	if not is_on_floor():
		velocity.y -= 9.8 * dt

	move_and_slide()

	# Shoot beam occasionally
	fire_timer += dt
	if fire_timer >= 2.5:
		fire_timer = 0.0
		_fire_laser()

func _fire_laser() -> void:
	if laser_mesh:
		laser_mesh.visible = true
		await get_tree().create_timer(0.35).timeout
		laser_mesh.visible = false

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		queue_free()
