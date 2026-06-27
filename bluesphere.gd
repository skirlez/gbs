extends Node3D

class_name BlueSphere

var got = false
func _ready() -> void:
	RenderingServer.instance_set_ignore_culling($Mesh.get_instance(), true)
func get_blue_sphere():
	got = true
	$CollectSound.play()
	make_red()
func make_red():
	$Mesh.set_instance_shader_parameter("albedo", Vector4(1, 0, 0, 0))
