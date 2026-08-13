class_name LevelObjects
extends Node

var instances = []
const PATTERN_SIZE = 16
const LEVEL_SIZE = PATTERN_SIZE * 2 
const RECT_SIZE = 4 


@export var level_data: LevelData

var bluesphere_scene = preload("res://gameobjects/sphere/bluesphere.tscn")
var bumper_scene = preload("res://gameobjects/bumper/bumper.tscn")
var ring_scene = preload("res://gameobjects/ring/ring.tscn")
func _ready():
	
	var section_instances = [ [],[],[],[] ]
	for arr in section_instances:
		arr.resize(PATTERN_SIZE * PATTERN_SIZE)
		arr.fill(null)
		
	for k in 4:
		var lvl = level_data.levels[RandomNumberGenerator.new().randi_range(0, len(level_data.levels) - 1)]
		#var lvl = levels[len(levels) - 1]
		for i in PATTERN_SIZE:
			for j in PATTERN_SIZE:
				var obj = lvl[i * PATTERN_SIZE + j]
				if obj == 0:
					continue
				var instance
				if obj == 1:			
					instance = bumper_scene.instantiate()
				elif obj == 2:
					instance = bluesphere_scene.instantiate()
					instance.got = true
					instance.make_red()
				elif obj == 3:			
					instance = bluesphere_scene.instantiate()
				elif obj == 4:
					instance = ring_scene.instantiate()
				else:
					continue
				instance.visible = false;
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
				
				section_instances[k][pos.y * PATTERN_SIZE + pos.x] = instance
	instances.resize(LEVEL_SIZE * LEVEL_SIZE)
	instances.fill(null)

	# horrible
	for m in 2:
		for i in PATTERN_SIZE:
			for k in 2:
				for j in PATTERN_SIZE:
					instances[(m * LEVEL_SIZE * LEVEL_SIZE / 2.0) # bottom half
								+ k * PATTERN_SIZE	# in right corner or not
								+ i * LEVEL_SIZE + j # movement inside corner
					] = section_instances[m * 2 + k][i * PATTERN_SIZE + j]

	
	for i in LEVEL_SIZE:
		for j in LEVEL_SIZE:
			var s = RECT_SIZE / 2.0
			var instance = instances[i * LEVEL_SIZE + j]
			if instance == null:
				continue
			instance.transform.origin = Vector3((j - PATTERN_SIZE) * RECT_SIZE - s, 0.5, (i - PATTERN_SIZE) * RECT_SIZE - s)
			add_child(instance)

func remove_instance_from_array(node: LevelObject):
	for i in LEVEL_SIZE*LEVEL_SIZE:
		if instances[i] == node:
			instances[i] = null


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
			if instances[index] is not BlueSphere:
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
		return # no interior
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
				var inst = instances[index]
				if inst is not BlueSphere:
					continue
				if inst.got:
					continue
				interior[index] = true
	# if there aren't any interior spheres besides the path, we leave
	if len(interior) == len(all_path_tiles):
		return
	
	for index in interior.keys():
		instances[index].queue_free()
		var ring = ring_scene.instantiate()
		add_child(ring)
		instances[index] = ring
		$RingTransmute.play()
		
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
	var inst = instances[new_tile.y * LEVEL_SIZE + new_tile.x]
	if inst is not BlueSphere:
		return
	if not inst.got:
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
