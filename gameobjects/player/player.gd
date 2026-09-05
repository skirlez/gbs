class_name Player
extends Node3D

enum States {
	WAITING,
	WALKING, 
	ROTATING,
}

@export var level_objects: LevelObjects

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

const CARDINAL_OFFSETS = [Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1)]
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

var total_walk_tics = 16 
var total_rotation_tics = 16

@export var culler: Culler

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
		return Util.wrap_grid_pos(walk_destination)
func process_collision(tile):
	if (tile == null):
		return
	level_objects.on_collide_with_object(tile)


func update_culler():
	if not Global.VISUALS_ENABLED:
		return
	culler.make_old_visible_instances_invisible()
	match state:
		States.WAITING:
			culler.make_instances_visible_in_direction(pos, walk_angle)
		States.WALKING:
			culler.make_instances_visible_in_direction(pos, walk_angle)
		States.ROTATING:
			culler.make_instances_visible_in_direction(pos, int_angle_to_walk_angle(rotation_start))
			culler.make_instances_visible_in_direction(pos, int_angle_to_walk_angle(rotation_destination))

func _ready():
	pos.x = 28
	pos.y = 16
	update_origin(pos)
	update_basis(walk_angle)
	update_culler()
	
func switch_states(new):
	timer = 0
	state = new
	state_epoch = Time.get_ticks_msec()
	match state:
		States.WALKING:
			walk_start = Vector2(pos.x, pos.y)
			@warning_ignore("integer_division")			
			var dest_offset = CARDINAL_OFFSETS[walk_angle]
			walk_destination = walk_start + dest_offset
		States.ROTATING:
			rotation_start = walk_angle
			rotation_destination = rotation_start + rotation_direction
			rotation_direction = 0
	
	update_culler()
	
	
	
func update_basis(angle):
	transform.basis = Basis.from_euler(Vector3(0, (angle * PI / 2) - PI / 2, 0)) 
func update_origin(new_pos):
	transform.origin = Util.grid_to_world_3d(new_pos, PERM_Y_OFFSET)
	
func _process(_delta: float) -> void:	
	RenderingServer.global_shader_parameter_set("player_pos", transform.origin)
	var time = (Time.get_ticks_msec() - state_epoch)
	var frame_times = time * 60.0 / 1000.0
	
	# frame_times = timer
	match state:
		States.WALKING:
			var new_pos = lerp(Util.grid_to_world_2d(walk_start), Util.grid_to_world_2d(walk_destination), min(1, frame_times / float(total_walk_tics)))
			transform.origin = Util.world_2d_to_world_3d(new_pos, PERM_Y_OFFSET) 
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
					
				pos = Util.wrap_grid_pos(walk_destination)
				transform.origin = Util.grid_to_world_3d(pos, PERM_Y_OFFSET)
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
