extends Node3D

@onready var player: Player = $Player
@onready var hud: HUD = $HUD
@onready var water_area: Area3D = $PoolWater/Area3D
@onready var trampoline_area: Area3D = get_node_or_null("Trampoline/SpringArea")
@onready var slide_area: Area3D = get_node_or_null("SlideRamp/SlideArea")

var sound_fx: SoundFX

func _ready() -> void:
	# Inicializar SoundFX si no está presente
	sound_fx = SoundFX.new()
	sound_fx.name = "SoundFX"
	add_child(sound_fx)

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
		if hud.has_signal("warp_pressed"):
			hud.connect("warp_pressed", func(): player.flash_warp())
		if hud.has_signal("slowmo_pressed"):
			hud.connect("slowmo_pressed", func(): player.toggle_slowmo())

	if water_area:
		water_area.body_entered.connect(_on_water_entered)
		water_area.body_exited.connect(_on_water_exited)

	_setup_interactive_areas()

func _setup_interactive_areas() -> void:
	# 1. Trampolín de Clavados
	var tramp = get_node_or_null("Trampoline")
	if tramp and not tramp.has_node("SpringArea"):
		var area = Area3D.new()
		area.name = "SpringArea"
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(1.8, 0.6, 2.5) # Área en la punta del trampolín
		col.shape = box
		col.position = Vector3(0, 0.4, 1.0)
		area.add_child(col)
		tramp.add_child(area)
		area.body_entered.connect(_on_trampoline_stepped)

	# 2. Tobogán de Agua
	var slide = get_node_or_null("SlideRamp")
	if slide and not slide.has_node("SlideArea"):
		var s_area = Area3D.new()
		s_area.name = "SlideArea"
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(1.8, 0.8, 11.5)
		col.shape = box
		col.position = Vector3(0, 0.45, 0)
		s_area.add_child(col)
		slide.add_child(s_area)
		s_area.body_entered.connect(_on_slide_entered)
		s_area.body_exited.connect(_on_slide_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not player: return
	if event is InputEventScreenDrag:
		if event.position.x > get_viewport().get_visible_rect().size.x * 0.4:
			player.rotate_camera(event.relative)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		player.rotate_camera(event.relative)
	# Atajos de teclado para probar en Mac
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			player.flash_warp()
		elif event.keycode == KEY_Q:
			player.toggle_slowmo()
		elif event.keycode == KEY_SPACE:
			player.jump()
		elif event.keycode == KEY_1:
			player.toggle_flashlight()
		elif event.keycode == KEY_2:
			player.toggle_laser()
		elif event.keycode == KEY_3:
			player.toggle_mirror()
		elif event.keycode == KEY_C:
			player.toggle_camera_mode()

func _on_water_entered(body: Node3D) -> void:
	if body == player:
		player.is_in_water = true
		SoundFX.get_instance().play_splash(-4.0)

func _on_water_exited(body: Node3D) -> void:
	if body == player:
		player.is_in_water = false

func _on_trampoline_stepped(body: Node3D) -> void:
	if body == player:
		player.apply_spring_impulse(12.5)

func _on_slide_entered(body: Node3D) -> void:
	if body == player:
		var slide_dir = Vector3(0.08, -0.4, 0.92).normalized()
		player.apply_slide_impulse(slide_dir)

func _on_slide_exited(body: Node3D) -> void:
	if body == player:
		player.stop_sliding()
