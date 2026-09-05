class_name Culler
extends Node

var objects: Array
func _on_level_objects_level_loaded(_objects: Array) -> void:
	objects = _objects


const VISIBLE_WIDTH = 10
const VISIBLE_FORWARDS = 13
const VISIBLE_BACKWARDS = 1

var visible_instances_x_ranges = []
var visible_instances_y_ranges = []

func make_old_visible_instances_invisible():	
	var length = len(visible_instances_x_ranges)
	for i in length:
		for y in visible_instances_y_ranges[i]:
			for x in visible_instances_x_ranges[i]:
				var new_pos = Util.wrap_grid_pos(Vector2(x, y))
				var instance: LevelObjectVisual = objects[new_pos.y * Global.LEVEL_SIZE + new_pos.x].visual		
				if instance == null:
					continue
				instance.visible = false

	visible_instances_x_ranges.clear()
	visible_instances_y_ranges.clear()
	
func make_instances_visible_in_direction(pos: Vector2i, angle: Player.WalkAngle):
	# this can and should be done with trig i'm just lazy
	var range_x
	var range_y
	if angle == Player.WalkAngle.UP || angle ==  Player.WalkAngle.DOWN:
		if angle == Player.WalkAngle.UP:
			range_y = range(pos.y - VISIBLE_FORWARDS, pos.y + VISIBLE_BACKWARDS + 1)
		else:
			range_y = range(pos.y - VISIBLE_BACKWARDS, pos.y + VISIBLE_FORWARDS + 1)
		range_x = range(pos.x - VISIBLE_WIDTH, pos.x + VISIBLE_WIDTH + 1)
	else:
		if angle == Player.WalkAngle.RIGHT:
			range_x = range(pos.x - VISIBLE_BACKWARDS, pos.x + VISIBLE_FORWARDS + 1)
		else:
			range_x = range(pos.x - VISIBLE_FORWARDS, pos.x + VISIBLE_BACKWARDS + 1)
		range_y = range(pos.y - VISIBLE_WIDTH, pos.y + VISIBLE_WIDTH + 1)
	for y in range_y:
		for x in range_x:
			var unreal_pos = Vector2i(x, y)
			var new_pos = Util.wrap_grid_pos(unreal_pos)
			var instance: LevelObjectVisual = objects[new_pos.y * Global.LEVEL_SIZE + new_pos.x].visual	
			if instance == null:
				continue
			if instance.visible:
				continue
			instance.visible = true
			var s = Global.RECT_SIZE / 2.0
			instance.transform.origin = Vector3((unreal_pos.x - Global.PATTERN_SIZE) * Global.RECT_SIZE - s, 0.5, (unreal_pos.y - Global.PATTERN_SIZE) * Global.RECT_SIZE - s)
	visible_instances_x_ranges.append(range_x)
	visible_instances_y_ranges.append(range_y)
