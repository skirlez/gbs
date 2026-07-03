extends Node3D
class_name Ring


var meshes = []
func initialize_meshes():
	meshes = [$Mesh]
	for mesh in Util.clone_meshes($Mesh):
		meshes.append(mesh)
		add_child(mesh)
func _ready() -> void:
	for mesh in meshes:
		RenderingServer.instance_set_ignore_culling(mesh.get_instance(), true)

	
func get_ring():
	var collect_sound = $CollectSound
	collect_sound.reparent(get_parent())
	get_parent().remove_child(self)
	queue_free()
	
	collect_sound.play()
	await collect_sound.finished
	collect_sound.queue_free()
