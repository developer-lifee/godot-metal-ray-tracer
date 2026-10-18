@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type(
		"MetalRayTracer3D",
		"Node3D",
		preload("nodes/metal_ray_tracer_3d.gd"),
		preload("icons/icon.svg")
	)
	print("[MetalRayTracer] Plugin activado: Nodo MetalRayTracer3D registrado en Godot 4.7.")

func _exit_tree() -> void:
	remove_custom_type("MetalRayTracer3D")
	print("[MetalRayTracer] Plugin desactivado: Nodo MetalRayTracer3D desregistrado.")
