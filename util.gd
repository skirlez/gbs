extends Node

const LEVEL_SIZE = 32
const RECT_SIZE = 4

func clone_meshes(mesh_to_clone):
	var list = []
	for k in 8:
		var offset_vector = Vector2i(round(cos(k * PI/4)), round(sin(k * PI/4)))
		var dup = mesh_to_clone.duplicate()
		dup.transform.origin.x += offset_vector.x * LEVEL_SIZE * RECT_SIZE
		dup.transform.origin.z += offset_vector.y * LEVEL_SIZE * RECT_SIZE
		list.append(dup)
	return list
