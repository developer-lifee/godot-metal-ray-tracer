@tool
extends EditorPlugin

var dock_instance: Control

func _enter_tree() -> void:
	# 1. Registrar tipo de nodo visual en la biblioteca de nodos
	add_custom_type(
		"MetalRayTracer3D",
		"Node3D",
		preload("nodes/metal_ray_tracer_3d.gd"),
		preload("icons/icon.svg")
	)

	# 2. Añadir panel de control visual en la interfaz del editor
	var dock_script = preload("ui/metal_ray_tracer_dock.gd")
	dock_instance = dock_script.new()
	dock_instance.custom_minimum_size = Vector2(0, 110)
	add_control_to_bottom_panel(dock_instance, "⚡ Metal Ray Tracer")

	print("[MetalRayTracer] Plugin activado: Nodo MetalRayTracer3D y Panel Visual cargados en Godot 4.7.")

func _exit_tree() -> void:
	if dock_instance:
		remove_control_from_bottom_panel(dock_instance)
		dock_instance.free()
		dock_instance = null

	remove_custom_type("MetalRayTracer3D")
	print("[MetalRayTracer] Plugin desactivado: Nodo y Panel desregistrados.")
