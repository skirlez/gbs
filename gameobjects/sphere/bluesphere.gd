class_name BlueSphere
extends LevelObjectVisual

const LEVEL_SIZE = 32
const RECT_SIZE = 4 

var got = false

func _ready() -> void:
	RenderingServer.instance_set_ignore_culling($Mesh.get_instance(), true)
		
func get_blue_sphere():
	got = true
	$CollectSound.play()
	make_red()
var redsphere_material = preload("res://gameobjects/sphere/redsphere.material")
func make_red():
	$Mesh.set_surface_override_material(0, redsphere_material)
