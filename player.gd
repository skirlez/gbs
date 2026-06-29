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
const WALK_ANGLE_OFFSETS = [Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1)]
var walk_angle = WalkAngle.UP

const PERM_Y_OFFSET = 1;
const JUMP_VELOCITY = 0.3;
var y_offset = 0;
var y_speed = 0;

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


var total_walk_tics = 20
var total_rotation_tics = 20

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
	
func update_basis(angle):
	transform.basis = Basis.from_euler(Vector3(0, (angle * PI / 2) - PI / 2, 0)) 
func update_origin(new_pos):
	transform.origin = grid_to_world_3d(new_pos)
	
func _process(_delta: float) -> void:	
	RenderingServer.global_shader_parameter_set("player_pos", transform.origin)
	var time = (Time.get_ticks_msec() - state_epoch)
	var frame_times = time * 60.0 / 1000.0
	match state:
		States.WALKING:
			var new_pos = lerp(grid_to_world_2d(walk_start), grid_to_world_2d(walk_destination), min(1, frame_times / float(total_walk_tics)))
			transform.origin = world_2d_to_world_3d(new_pos) 
		States.ROTATING:
			var angle = lerp(float(rotation_start), float(rotation_destination), min(1, frame_times / float(total_rotation_tics)))
			update_basis(angle)


func _physics_process(_delta: float) -> void:
	y_offset += y_speed
	if y_offset > 0:
		y_speed -= 0.01
	else:
		y_offset = 0
	$Mesh.transform.origin.y = y_offset
	timer += 1
	match state:
		States.WAITING:
			if (timer == 180):
				switch_states(States.WALKING)
		States.WALKING:
			if Input.is_action_just_pressed("jump"):
				if y_offset == 0:
					y_speed = JUMP_VELOCITY 
					$Jump.play()
			if (timer == total_walk_tics):
				if y_offset < 0.5:
					var my_tile = walk_destination
					var index = my_tile.y * LEVEL_SIZE + my_tile.x
					var instances =	$"../LevelObjects".instances
					if index >= 0 and index <= len(instances) - 1:
						var inst = instances[index]
						if is_instance_valid(inst):
							on_collide_with_instance(inst)

				pos = walk_destination
				transform.origin = grid_to_world_3d(pos)
				if y_offset != 0:
					switch_states(States.WALKING)
				elif Input.is_action_pressed("rotate_left"):
					rotation_direction = 1
					switch_states(States.ROTATING)
				elif Input.is_action_pressed("rotate_right"):
					rotation_direction = -1
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


func on_collide_with_instance(node: Node3D) -> void:
	if node is BlueSphere:
		if node.got:
			return
		node.get_blue_sphere()
	if node is Ring:
		node.get_ring()
