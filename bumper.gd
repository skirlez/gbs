extends Node3D
class_name Bumper
func _ready() -> void:
	RenderingServer.instance_set_ignore_culling($Mesh.get_instance(), true)
