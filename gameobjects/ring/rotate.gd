extends MeshInstance3D

var angle = 0
func _process(delta: float) -> void:
	angle += delta * 2
	transform.basis = Basis.from_euler(Vector3(0, angle, deg_to_rad(90)))
