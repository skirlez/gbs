extends Node


var headless: bool = false


func clone_meshes(mesh_to_clone):
	var list = []
	for k in 8:
		var offset_vector = Vector2i(round(cos(k * PI/4)), round(sin(k * PI/4)))
		var dup = mesh_to_clone.duplicate()
		dup.transform.origin.x += offset_vector.x * Global.LEVEL_SIZE * Global.RECT_SIZE
		dup.transform.origin.z += offset_vector.y * Global.LEVEL_SIZE * Global.RECT_SIZE
		list.append(dup)
	return list

	
func grid_to_world_2d(grid_pos: Vector2i) -> Vector2:
	const GRID_OFFSET = Vector2i.ONE * Global.PATTERN_SIZE
	const WORLD_OFFSET = Vector2.ONE * 0.5
	return (Vector2(grid_pos - GRID_OFFSET) - WORLD_OFFSET) * Global.RECT_SIZE
func grid_to_world_3d(grid_pos: Vector2i, y: float) -> Vector3:
	return world_2d_to_world_3d(grid_to_world_2d(grid_pos), y)
func world_2d_to_world_3d(world_pos: Vector2, y: float) -> Vector3:
	return Vector3(world_pos.x, y, world_pos.y)
func wrap_grid_pos(grid_pos: Vector2i):
	grid_pos = Vector2i(grid_pos)
	if (grid_pos.x < 0):
		grid_pos.x += Global.LEVEL_SIZE
	elif (grid_pos.x >= Global.LEVEL_SIZE):
		grid_pos.x -= Global.LEVEL_SIZE
	if (grid_pos.y < 0):
		grid_pos.y += Global.LEVEL_SIZE
	elif (grid_pos.y >= Global.LEVEL_SIZE):
		grid_pos.y -= Global.LEVEL_SIZE
	return grid_pos
