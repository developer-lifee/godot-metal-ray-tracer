extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var water_area: Area3D = $PoolWater/Area3D

func _ready() -> void:
	if hud and player:
		if hud.has_signal("joystick_moved"):
			hud.connect("joystick_moved", func(vec): player.joystick_input = vec)
		if hud.has_signal("jump_pressed"):
			hud.connect("jump_pressed", func(): player.jump())
		if hud.has_signal("tool_laser_pressed"):
			hud.connect("tool_laser_pressed", func(): player.toggle_laser())
		if hud.has_signal("tool_flashlight_pressed"):
			hud.connect("tool_flashlight_pressed", func(): player.toggle_flashlight())
		if hud.has_signal("tool_mirror_pressed"):
			hud.connect("tool_mirror_pressed", func(): player.toggle_mirror())
		if hud.has_signal("camera_mode_pressed"):
			hud.connect("camera_mode_pressed", func(): player.toggle_camera_mode())

	if water_area:
		water_area.body_entered.connect(_on_water_entered)
		water_area.body_exited.connect(_on_water_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not player: return
	if event is InputEventScreenDrag:
		if event.position.x > get_viewport().get_visible_rect().size.x * 0.4:
			player.rotate_camera(event.relative)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		player.rotate_camera(event.relative)

func _on_water_entered(body: Node3D) -> void:
	if body == player:
		player.is_in_water = true

func _on_water_exited(body: Node3D) -> void:
	if body == player:
		player.is_in_water = false
