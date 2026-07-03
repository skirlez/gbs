extends Node3D
class_name Bumper

var meshes = []
func initialize_meshes():
	meshes = [$Mesh]
	for mesh in Util.clone_meshes($Mesh):
		meshes.append(mesh)
		add_child(mesh)
func _ready() -> void:
	for mesh in meshes:
		RenderingServer.instance_set_ignore_culling(mesh.get_instance(), true)
