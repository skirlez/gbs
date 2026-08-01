extends Node3D


enum States {
	WAITING,
	WALKING, 
	ROTATING,
}

@onready var level_objects = $"../LevelObjects"

var timer: int = 0
var state = States.WAITING

enum WalkAngle {
	RIGHT = 0,
	UP = 1,
	LEFT = 2,
	DOWN = 3
}
var jump_timer = 0
const TOTAL_JUMP_TICS = 17 * 2
const VISUAL_JUMP_HEIGHT = 2.5

const WALK_ANGLE_OFFSETS = [Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1)]
const COLLISION_RADIUS = 0.2

var walk_angle = WalkAngle.UP

const PERM_Y_OFFSET = 1;
var y_offset = 0;

var pos: Vector2i
var walk_start: Vector2i
var walk_destination: Vector2i

var rotation_direction: int
var rotation_start: int
var rotation_destination: int

var state_epoch = Time.get_ticks_msec()

const PATTERN_SIZE = 16
const LEVEL_SIZE = PATTERN_SIZE * 2 
const RECT_SIZE = 4

const VISIBLE_WIDTH = 10
const VISIBLE_FORWARDS = 13
const VISIBLE_BACKWARDS = 1

var visible_instances_x_ranges = []
var visible_instances_y_ranges = []

func make_old_visible_instances_invisible():	
	var instances = level_objects.instances
	var length = len(visible_instances_x_ranges)
	for i in length:
		for y in visible_instances_y_ranges[i]:
			for x in visible_instances_x_ranges[i]:
				var new_pos = wrap_grid_pos(Vector2(x, y))
				var instance: LevelObject = instances[new_pos.y * LEVEL_SIZE + new_pos.x]			
				if instance == null:
					continue
				instance.visible = false

func update_visible_instances():
	make_old_visible_instances_invisible()
	visible_instances_x_ranges.clear()
	visible_instances_y_ranges.clear()
	match state:
		States.WAITING:
			make_instances_visible_in_direction(walk_angle)
		States.WALKING:
			make_instances_visible_in_direction(walk_angle)
		States.ROTATING:
			make_instances_visible_in_direction(int_angle_to_walk_angle(rotation_start))
			make_instances_visible_in_direction(int_angle_to_walk_angle(rotation_destination))
	
func make_instances_visible_in_direction(angle: WalkAngle):
	# this can and should be done with trig i'm just lazy
	var range_x
	var range_y
	if angle == WalkAngle.UP || angle == WalkAngle.DOWN:
		if angle == WalkAngle.UP:
			range_y = range(pos.y - VISIBLE_FORWARDS, pos.y + VISIBLE_BACKWARDS + 1)
		else:
			range_y = range(pos.y - VISIBLE_BACKWARDS, pos.y + VISIBLE_FORWARDS + 1)
		range_x = range(pos.x - VISIBLE_WIDTH, pos.x + VISIBLE_WIDTH + 1)
	else:
		if angle == WalkAngle.RIGHT:
			range_x = range(pos.x - VISIBLE_BACKWARDS, pos.x + VISIBLE_FORWARDS + 1)
		else:
			range_x = range(pos.x - VISIBLE_FORWARDS, pos.x + VISIBLE_BACKWARDS + 1)
		range_y = range(pos.y - VISIBLE_WIDTH, pos.y + VISIBLE_WIDTH + 1)
	var instances = level_objects.instances
	for y in range_y:
		for x in range_x:
			var unreal_pos = Vector2i(x, y)
			var new_pos = wrap_grid_pos(unreal_pos)
			var instance: LevelObject = instances[new_pos.y * LEVEL_SIZE + new_pos.x]			
			if instance == null:
				continue
			if instance.visible:
				continue
			instance.visible = true
			var s = RECT_SIZE / 2.0
			instance.transform.origin = Vector3((unreal_pos.x - PATTERN_SIZE) * RECT_SIZE - s, 0.5, (unreal_pos.y - PATTERN_SIZE) * RECT_SIZE - s)
	visible_instances_x_ranges.append(range_x)
	visible_instances_y_ranges.append(range_y)
	
var total_walk_tics = 16 
var total_rotation_tics = 16

func grid_to_world_2d(grid_pos: Vector2i) -> Vector2:
	const GRID_OFFSET = Vector2i.ONE * PATTERN_SIZE
	const WORLD_OFFSET = Vector2.ONE * 0.5
	return (Vector2(grid_pos - GRID_OFFSET) - WORLD_OFFSET) * RECT_SIZE
func grid_to_world_3d(grid_pos: Vector2i) -> Vector3:
	return world_2d_to_world_3d(grid_to_world_2d(grid_pos))
func world_2d_to_world_3d(world_pos: Vector2) -> Vector3:
	return Vector3(world_pos.x, PERM_Y_OFFSET, world_pos.y)
func wrap_grid_pos(grid_pos: Vector2i):
	grid_pos = Vector2i(grid_pos)
	if (grid_pos.x < 0):
		grid_pos.x += LEVEL_SIZE
	elif (grid_pos.x >= LEVEL_SIZE):
		grid_pos.x -= LEVEL_SIZE
	if (grid_pos.y < 0):
		grid_pos.y += LEVEL_SIZE
	elif (grid_pos.y >= LEVEL_SIZE):
		grid_pos.y -= LEVEL_SIZE
	return grid_pos
func int_angle_to_walk_angle(angle: int) -> WalkAngle:
	var a = angle % 4
	if a < 0:
		a += 4
	return a as WalkAngle


func get_tile_for_collision():
	var progress = timer / float(total_walk_tics)
	if progress <= COLLISION_RADIUS:
		return walk_start
	if progress >= 1 - COLLISION_RADIUS:
		return wrap_grid_pos(walk_destination)
	return null
func process_collision(tile):
	if (tile == null):
		return
	var index = tile.y * LEVEL_SIZE + tile.x
	var instances =	level_objects.instances
	if index >= 0 and index <= len(instances) - 1:
		var inst = instances[index]
		if is_instance_valid(inst):
			on_collide_with_instance(inst)


func _ready():
	pos.x = 28
	pos.y = 16
	update_origin(pos)
	update_basis(walk_angle)
	update_visible_instances()	
func switch_states(new):
	timer = 0
	state = new
	state_epoch = Time.get_ticks_msec()
	match state:
		States.WALKING:
			walk_start = Vector2(pos.x, pos.y)
			@warning_ignore("integer_division")			
			var dest_offset = WALK_ANGLE_OFFSETS[walk_angle]
			walk_destination = walk_start + dest_offset
		States.ROTATING:
			rotation_start = walk_angle
			rotation_destination = rotation_start + rotation_direction
			rotation_direction = 0
	update_visible_instances()
func update_basis(angle):
	transform.basis = Basis.from_euler(Vector3(0, (angle * PI / 2) - PI / 2, 0)) 
func update_origin(new_pos):
	transform.origin = grid_to_world_3d(new_pos)
	
func _process(_delta: float) -> void:	
	RenderingServer.global_shader_parameter_set("player_pos", transform.origin)
	var time = (Time.get_ticks_msec() - state_epoch)
	var frame_times = time * 60.0 / 1000.0
	
	# frame_times = timer
	match state:
		States.WALKING:
			var new_pos = lerp(grid_to_world_2d(walk_start), grid_to_world_2d(walk_destination), min(1, frame_times / float(total_walk_tics)))
			transform.origin = world_2d_to_world_3d(new_pos) 
		States.ROTATING:
			var angle = lerp(float(rotation_start), float(rotation_destination), min(1, frame_times / float(total_rotation_tics)))
			update_basis(angle)



func _physics_process(_delta: float) -> void:
	# if not Input.is_action_just_pressed("advance") and state != States.WAITING:
	# 	return
	timer += 1
	match state:
		States.WAITING:
			if (timer == 180):
				switch_states(States.WALKING)
		States.WALKING:
			if Input.is_action_just_pressed("jump"):
				if jump_timer == 0:
					rotation_direction = 0
					jump_timer = 1
					$Jump.play()
			if jump_timer <= 0:
				var tile = get_tile_for_collision()
				process_collision(tile)
				if Input.is_action_just_pressed("rotate_left"):
					rotation_direction = 1
				if Input.is_action_just_pressed("rotate_right"):
					rotation_direction = -1
			if (timer == total_walk_tics):
				# this is done twice since you need to be able to hold left and right to keep rotating
				# the above check doesn't check for hold, since if it did, if you held and kept holding through a rotation,
				# it would register a rotation for the next move too
					
				pos = wrap_grid_pos(walk_destination)
				transform.origin = grid_to_world_3d(pos)
				if jump_timer <= 0:
					process_collision(pos)
					if Input.is_action_pressed("rotate_left"):
						rotation_direction = 1
					if Input.is_action_pressed("rotate_right"):
						rotation_direction = -1
				if y_offset != 0 or rotation_direction == 0:
					switch_states(States.WALKING)
				elif (rotation_direction != 0):
					switch_states(States.ROTATING)
				else:
					switch_states(States.WALKING)
		States.ROTATING:
			if (timer == total_rotation_tics):
				walk_angle = int_angle_to_walk_angle(rotation_destination)
				update_basis(walk_angle)
				switch_states(States.WALKING)
	
	if (jump_timer <= 0):
		y_offset = 0
		if (jump_timer == -1):
			jump_timer = 0
	else:
		y_offset = sin((jump_timer / float(TOTAL_JUMP_TICS) * PI)) * VISUAL_JUMP_HEIGHT
		jump_timer += 1
		if (jump_timer == TOTAL_JUMP_TICS):
			jump_timer = -1
	$Mesh.transform.origin.y = y_offset

func on_collide_with_instance(node: Node3D) -> void:
	if node is BlueSphere:
		if node.got:
			return
		node.get_blue_sphere()
	if node is Ring:
		node.get_ring()
