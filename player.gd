extends Node3D


enum States {
	WAITING,
	WALKING, 
	ROTATING,
}

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
const JUMP_VELOCITY = 0.3;
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

func _ready():
	pos.x = 28
	pos.y = 16
	update_origin(pos)
	update_basis(walk_angle)
	
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

func get_tile_for_collision():
	var progress = timer / float(total_walk_tics)
	if progress <= COLLISION_RADIUS:
		return walk_start
	if progress >= 1 - COLLISION_RADIUS:
		return walk_destination
	return null
func process_collision(tile):
	if (tile == null):
		return
	var index = tile.y * LEVEL_SIZE + tile.x
	var instances =	$"../LevelObjects".instances
	if index >= 0 and index <= len(instances) - 1:
		var inst = instances[index]
		if is_instance_valid(inst):
			on_collide_with_instance(inst)

func _physics_process(_delta: float) -> void:
	# if not Input.is_action_just_pressed("advance") and state != States.WAITING:
	# 	return
	timer += 1
	match state:
		States.WAITING:
			if (timer == 180):
				switch_states(States.WALKING)
		States.WALKING:
			if Input.is_action_pressed("jump"):
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
				pos = walk_destination
				transform.origin = grid_to_world_3d(pos)
				if jump_timer <= 0:
					process_collision(pos)
				if y_offset != 0 or rotation_direction == 0:
					switch_states(States.WALKING)
				elif (rotation_direction != 0):
					switch_states(States.ROTATING)
				else:
					switch_states(States.WALKING)
		States.ROTATING:
			if (timer == total_rotation_tics):
				var angle_final = rotation_destination % 4
				if angle_final < 0:
					angle_final += 4
				walk_angle = angle_final as WalkAngle 
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
