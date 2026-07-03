extends Node3D

class_name BlueSphere

const LEVEL_SIZE = 32
const RECT_SIZE = 4 

var got = false
var meshes = []
func initialize_meshes():
	meshes = [$Mesh]
	for mesh in Util.clone_meshes($Mesh):
		meshes.append(mesh)
		add_child(mesh)

func _ready() -> void:
	for mesh in meshes:
		RenderingServer.instance_set_ignore_culling(mesh.get_instance(), true)
		
func get_blue_sphere():
	got = true
	$CollectSound.play()
	make_red()
var redsphere_material = preload("res://gameobjects/sphere/redsphere.material")
func make_red():
	for mesh in meshes:
		mesh.set_surface_override_material(0, redsphere_material)
