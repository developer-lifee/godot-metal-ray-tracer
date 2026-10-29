extends CanvasLayer

class_name HUD

signal joystick_moved(vector: Vector2)
signal jump_pressed
signal tool_flashlight_pressed
signal tool_laser_pressed
signal tool_mirror_pressed
signal camera_mode_pressed
signal warp_pressed
signal slowmo_pressed

@onready var joystick_base: Control = $JoystickBase
@onready var joystick_knob: Control = $JoystickBase/Knob
@onready var jump_btn: Button = $ActionButtons/JumpBtn
@onready var laser_btn: Button = $ActionButtons/LaserBtn
@onready var light_btn: Button = $ActionButtons/LightBtn
@onready var mirror_btn: Button = $ActionButtons/MirrorBtn
@onready var warp_btn: Button = $ActionButtons/WarpBtn
@onready var slowmo_btn: Button = $ActionButtons/SlowmoBtn
@onready var cam_btn: Button = $CameraBtn
@onready var slowmo_overlay: ColorRect = $SlowmoOverlay

var is_dragging_joystick: bool = false
var joystick_radius: float = 60.0
var joystick_center: Vector2

func _ready() -> void:
	joystick_center = joystick_base.size / 2.0
	joystick_knob.position = joystick_center - (joystick_knob.size / 2.0)

	jump_btn.pressed.connect(func(): emit_signal("jump_pressed"))
	laser_btn.pressed.connect(func(): emit_signal("tool_laser_pressed"))
	light_btn.pressed.connect(func(): emit_signal("tool_flashlight_pressed"))
	mirror_btn.pressed.connect(func(): emit_signal("tool_mirror_pressed"))
	cam_btn.pressed.connect(func(): emit_signal("camera_mode_pressed"))
	
	if warp_btn:
		warp_btn.pressed.connect(func(): emit_signal("warp_pressed"))
	if slowmo_btn:
		slowmo_btn.pressed.connect(_on_slowmo_button_pressed)

func _on_slowmo_button_pressed() -> void:
	emit_signal("slowmo_pressed")
	if slowmo_overlay:
		slowmo_overlay.visible = not slowmo_overlay.visible

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var local_pos = joystick_base.get_global_transform().affine_inverse() * event.position
			if local_pos.distance_to(joystick_center) < joystick_radius * 1.5:
				is_dragging_joystick = true
				_update_joystick(local_pos)
		else:
			if is_dragging_joystick:
				is_dragging_joystick = false
				_reset_joystick()

	elif event is InputEventScreenDrag and is_dragging_joystick:
		var local_pos = joystick_base.get_global_transform().affine_inverse() * event.position
		_update_joystick(local_pos)

func _update_joystick(pos: Vector2) -> void:
	var diff = pos - joystick_center
	var dist = min(diff.length(), joystick_radius)
	var dir = diff.normalized() if diff.length() > 0.001 else Vector2.ZERO
	var knob_center = joystick_center + dir * dist
	joystick_knob.position = knob_center - (joystick_knob.size / 2.0)

	var normalized_vec = dir * (dist / joystick_radius)
	emit_signal("joystick_moved", normalized_vec)

func _reset_joystick() -> void:
	joystick_knob.position = joystick_center - (joystick_knob.size / 2.0)
	emit_signal("joystick_moved", Vector2.ZERO)
