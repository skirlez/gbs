class_name LevelObjectVisual
extends Node3D



func _ready() -> void:
	RenderingServer.instance_set_ignore_culling($Mesh.get_instance(), true)
