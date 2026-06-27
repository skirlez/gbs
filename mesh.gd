extends MeshInstance3D

var angle = 0

func _process(delta: float) -> void:
	angle += delta * 2
	transform.basis = Basis.from_euler(Vector3(0, angle, rad_to_deg(90)))
func _ready() -> void:
	RenderingServer.instance_set_ignore_culling(get_instance(), true)
