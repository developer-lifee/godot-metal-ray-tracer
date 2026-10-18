@tool
extends PanelContainer

signal ray_bounces_changed(bounces: int)
signal toggle_preview_requested()

var status_label: Label
var bounces_val_label: Label
var bounces_slider: HSlider
var btn_test: Button

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var hbox_main = HBoxContainer.new()
	hbox_main.add_theme_constant_override("separation", 24)
	margin.add_child(hbox_main)

	# 1. Info / Status Col
	var vbox_info = VBoxContainer.new()
	vbox_info.custom_minimum_size = Vector2(280, 0)
	hbox_main.add_child(vbox_info)

	var title = Label.new()
	title.text = "⚡ Metal Ray Tracer 3D"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.18, 0.78, 1.0))
	vbox_info.add_child(title)

	status_label = Label.new()
	status_label.text = "● GPU: Apple Silicon Metal Hardware RT Activo"
	status_label.add_theme_color_override("font_color", Color(0.25, 0.95, 0.40))
	vbox_info.add_child(status_label)

	# 2. Controls Col
	var vbox_controls = VBoxContainer.new()
	vbox_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_main.add_child(vbox_controls)

	var hbox_bounces = HBoxContainer.new()
	vbox_controls.add_child(hbox_bounces)

	var bounce_lbl = Label.new()
	bounce_lbl.text = "Rebotes de Rayos (PBR Specular): "
	hbox_bounces.add_child(bounce_lbl)

	bounces_slider = HSlider.new()
	bounces_slider.min_value = 1
	bounces_slider.max_value = 4
	bounces_slider.value = 2
	bounces_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bounces_slider.value_changed.connect(_on_bounces_changed)
	hbox_bounces.add_child(bounces_slider)

	bounces_val_label = Label.new()
	bounces_val_label.text = "2"
	bounces_val_label.custom_minimum_size = Vector2(20, 0)
	hbox_bounces.add_child(bounces_val_label)

	# 3. Actions Col
	var vbox_actions = VBoxContainer.new()
	hbox_main.add_child(vbox_actions)

	btn_test = Button.new()
	btn_test.text = "🔄 Sincronizar Cámara & Renderizar Frame"
	btn_test.pressed.connect(_on_test_pressed)
	vbox_actions.add_child(btn_test)

func _on_bounces_changed(val: float) -> void:
	if bounces_val_label:
		bounces_val_label.text = str(int(val))
	ray_bounces_changed.emit(int(val))

func _on_test_pressed() -> void:
	print("[MetalRayTracer UI] Sincronización y disparo de ray tracing solicitado.")
	toggle_preview_requested.emit()
