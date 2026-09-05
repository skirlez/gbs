class_name LevelObjects
extends Node

var objects = []
const PATTERN_SIZE = 16
const LEVEL_SIZE = PATTERN_SIZE * 2 
const RECT_SIZE = 4 


@export var level_data: LevelData

var bluesphere_scene = preload("res://gameobjects/sphere/bluesphere.tscn")
var bumper_scene = preload("res://gameobjects/bumper/bumper.tscn")
var ring_scene = preload("res://gameobjects/ring/ring.tscn")

enum ObjectType {
	EMPTY = 0,
	BUMPER = 1,
	RED_SPHERE = 2,
	BLUE_SPHERE = 3,
	RING = 4
}

# visual is always null for EMPTY,
# when the game runs headless, visual is always null
class LevelObject:
	var type: ObjectType
	var visual: LevelObjectVisual


var sphere_amount = 0
var ring_amount = 0

func _ready():
	
	var section_objects = [ [],[],[],[] ]
	for arr in section_objects:
		arr.resize(PATTERN_SIZE * PATTERN_SIZE)
		arr.fill(null)
		
	for k in 4:
		var lvl = level_data.levels[RandomNumberGenerator.new().randi_range(0, len(level_data.levels) - 1)]
		#var lvl = levels[len(levels) - 1]
		for i in PATTERN_SIZE:
			for j in PATTERN_SIZE:
			

				var type: ObjectType = lvl[i * PATTERN_SIZE + j]	
				var instance: LevelObjectVisual
				
				if Global.VISUALS_ENABLED:
					if type == ObjectType.EMPTY:
						instance = null
					elif type == ObjectType.BUMPER:			
						instance = bumper_scene.instantiate()
					elif type == ObjectType.RED_SPHERE:
						instance = bluesphere_scene.instantiate()
						instance.got = true
						instance.make_red()
					elif type == ObjectType.BLUE_SPHERE:			
						instance = bluesphere_scene.instantiate()
					elif type == ObjectType.RING:
						instance = ring_scene.instantiate()
					else:
						type = ObjectType.EMPTY
						instance = null
						
					if instance != null:
						instance.visible = false
				else:
					instance = null
				var obj: LevelObject = LevelObject.new() 
				obj.type = type
				obj.visual = instance
				
				var pos = Vector2(j, i)
				# all of the level data is from the "top right" versions of the patterns
				# TODO: figure out if this is supposed to be rotation or flipping
				if k == 0:
					pos.x = PATTERN_SIZE - pos.x - 1
				if k == 2:
					pos.x = PATTERN_SIZE - pos.x - 1
					pos.y = PATTERN_SIZE - pos.y - 1
				if k == 3:
					pos.y = PATTERN_SIZE - pos.y - 1

				
				section_objects[k][pos.y * PATTERN_SIZE + pos.x] = obj
	objects.resize(LEVEL_SIZE * LEVEL_SIZE)
	objects.fill(null)

	# horrible
	for m in 2:
		for i in PATTERN_SIZE:
			for k in 2:
				for j in PATTERN_SIZE:
					objects[(m * LEVEL_SIZE * LEVEL_SIZE / 2.0) # bottom half
								+ k * PATTERN_SIZE	# in right corner or not
								+ i * LEVEL_SIZE + j # movement inside corner
					] = section_objects[m * 2 + k][i * PATTERN_SIZE + j]


	if not Global.VISUALS_ENABLED:
		return
	for i in LEVEL_SIZE:
		for j in LEVEL_SIZE:
			var s = RECT_SIZE / 2.0
			var obj = objects[i * LEVEL_SIZE + j]
			if obj.visual == null:
				continue
			obj.visual.transform.origin = Vector3((j - PATTERN_SIZE) * RECT_SIZE - s, 0.5, (i - PATTERN_SIZE) * RECT_SIZE - s)
			add_child(obj.visual)


	for i in LEVEL_SIZE:
		for j in LEVEL_SIZE:
			var type: ObjectType = objects[i * LEVEL_SIZE + j].type
			if (type == ObjectType.BLUE_SPHERE):
				sphere_amount += 1
			elif (type == ObjectType.RING): # TODO
				ring_amount += 1
	update_sphere_count.emit(sphere_amount)
	update_ring_count.emit(ring_amount)
	level_loaded.emit(objects)
			
signal level_loaded(objects: Array)

func on_collide_with_object(tile: Vector2i):
	var index = tile.y * LEVEL_SIZE + tile.x
	if index >= 0 and index <= len(objects) - 1:
		var object: LevelObject = objects[index]
		match object.type:
			ObjectType.BLUE_SPHERE:
				object.type = ObjectType.RED_SPHERE
				if Global.VISUALS_ENABLED:
					object.visual.get_blue_sphere()
				sphere_amount -= 1
				update_sphere_count.emit(sphere_amount)
				ring_transmutation_routine(tile)
			ObjectType.RING:
				objects[index].type = ObjectType.EMPTY
				if Global.VISUALS_ENABLED:
					object.visual.get_ring()
					objects[index].visual = null
				ring_amount -= 1
				update_ring_count.emit(ring_amount)

signal update_sphere_count(sphere_amount: int)
signal update_ring_count(ring_amount: int)

			
const PERIMETER_GROUP = 0
const NO_GROUP_YET = -1
const NOT_BLUE_SPHERE_GROUP = -2
func ring_transmutation_routine(tile: Vector2i):
	var all_path_tiles = find_longest_adjacent_roundabout_shortest_path_or_null(tile)
	print(all_path_tiles)
	if all_path_tiles == null:
		return
	# first we square this path
	var top_left = all_path_tiles[0]
	var bottom_right = all_path_tiles[0]
	for path_tile in all_path_tiles:
		if top_left.x > path_tile.x:
			top_left.x = path_tile.x
		elif bottom_right.x < path_tile.x:
			bottom_right.x = path_tile.x
		if top_left.y > path_tile.y:
			top_left.y = path_tile.y
		elif bottom_right.y < path_tile.y:
			bottom_right.y = path_tile.y

	
	var width = bottom_right.x - top_left.x + 1
	var height = bottom_right.y - top_left.y + 1
	var rect = []
	rect.resize(width * height)
	
	for x in width:
		for y in height:
			var index = (y + top_left.y) * LEVEL_SIZE + (x + top_left.x)
			if objects[index].type != ObjectType.BLUE_SPHERE and objects[index].type != ObjectType.RED_SPHERE:
				rect[y * width + x] = NOT_BLUE_SPHERE_GROUP
			else:
				rect[y * width + x] = NO_GROUP_YET

	for t in all_path_tiles:
		var x = t.x - top_left.x
		var y = t.y - top_left.y
		rect[y * width + x] = PERIMETER_GROUP
	var interior_group = null
	
	# we flood fill and then determine which of the two groups is the interior
	var group = 1
	for x in width:
		for y in height:
			if rect[y * width + x] != -1:
				continue
			if not flood_fill_did_reach_edge(rect, width, height, x, y, group):
				interior_group = group
			group += 1
	if interior_group == null:
		return # no interior, like in a 2x2
	var group_count = group - 1
	if group_count > 2:
		print("something has gone very wrong:")
		print(width)
		print(height)
		print(rect)
		return
	var interior = {}
	for t in all_path_tiles:
		var index = t.y * LEVEL_SIZE + t.x
		interior[index] = true
	for x in width:
		for y in height:
			if rect[y * width + x] == interior_group:
				var index = (y + top_left.y) * LEVEL_SIZE + (x + top_left.x)
				var obj = objects[index]
				if obj.type != ObjectType.BLUE_SPHERE:
					continue
				interior[index] = true
	# if there aren't any interior spheres besides the path, we leave
	if len(interior) == len(all_path_tiles):
		return
	
	$RingTransmute.play()
	for index in interior.keys():
		var obj = objects[index]
		if Global.VISUALS_ENABLED:
			obj.visual.queue_free()
			var ring = ring_scene.instantiate()
			add_child(ring)
			obj.visual = ring
		obj.type = ObjectType.RING

		
const CARDINAL_OFFSETS = [Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1)]
func find_longest_adjacent_roundabout_shortest_path_or_null(tile: Vector2i):
	var longest_path = null
	for start_offset in CARDINAL_OFFSETS:
		var start_tile = tile + start_offset
		var list = find_shortest_path(start_tile, start_offset, tile)
		if list == null:
			continue
		if longest_path == null or len(longest_path) < len(list):
			longest_path = list
	return longest_path

func find_shortest_path(start: Vector2i, start_offset : Vector2i, end: Vector2i):
	var queue = []
	var predecessor_dirs = { }
	process(queue, predecessor_dirs, start_offset, start)
	while len(queue) > 0:
		var head = queue.pop_front()
		if head == end:
			return get_path_to_start(predecessor_dirs, head)
			
		for offset in CARDINAL_OFFSETS:
			var new_tile = head + offset
			if predecessor_dirs[head] == -offset:
				continue
			process(queue, predecessor_dirs, offset, new_tile)

func process(queue, predecessor_dirs, offset, new_tile):
	if new_tile.x < 0 or new_tile.y < 0 or new_tile.x >= LEVEL_SIZE or new_tile.y >= LEVEL_SIZE:
		return
	var obj = objects[new_tile.y * LEVEL_SIZE + new_tile.x]
	if (obj.type != ObjectType.RED_SPHERE):
		return
	if new_tile in predecessor_dirs:
		return
	queue.append(new_tile)
	predecessor_dirs[new_tile] = offset

func get_path_to_start(predecessor_dirs, end) -> Array:
	var list = [end]
	var current = end
	while current in predecessor_dirs:
		var offset = predecessor_dirs[current]
		current -= offset
		if current == end:
			break
		list.append(current)
	return list

# returns true if found the edge of the rectangle in the process
func flood_fill_did_reach_edge(rect, width, height, x, y, group):
	var index = y * width + x
	if index < 0 or index >= width * height:
		return true
	if rect[index] != NO_GROUP_YET:
		return false
	rect[index] = group
	return (
		flood_fill_did_reach_edge(rect, width, height, x + 1, y, group)
		or flood_fill_did_reach_edge(rect, width, height, x - 1, y, group)
		or flood_fill_did_reach_edge(rect, width, height, x, y + 1, group)
		or flood_fill_did_reach_edge(rect, width, height, x, y - 1, group)
	)
