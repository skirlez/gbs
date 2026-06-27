extends Node3D


enum States {
	WAITING,
	WALKING, 
	ROTATING,
}

var timer: int = 0
var state = States.WAITING
var walk_angle: float = 0

var walk_start
var walk_destination

var rotation_direction: int
var rotation_start: int
var rotation_destination: int

var state_epoch = Time.get_ticks_msec()

const PATTERN_SIZE = 16
const LEVEL_SIZE = PATTERN_SIZE * 2 
const RECT_SIZE = 4


var total_walk_tics = 20
var total_rotation_tics = 20


func _ready():
	transform.origin.x = RECT_SIZE * 12.5
	transform.origin.z = RECT_SIZE * 0.5
func switch_states(new):
	timer = 0
	state = new
	state_epoch = Time.get_ticks_msec()
	match state:
		States.WALKING:
			walk_start = transform.origin
			walk_destination = transform.origin + RECT_SIZE * Vector3.FORWARD.rotated(Vector3.DOWN, deg_to_rad(walk_angle)) 
		States.ROTATING:
			rotation_start = int(walk_angle)
			rotation_destination = (rotation_start + 90 * rotation_direction)
func update_basis(angle):
	transform.basis = Basis.from_euler(Vector3(0, -deg_to_rad(angle), 0)) 
			
func _process(_delta: float) -> void:	
	RenderingServer.global_shader_parameter_set("player_pos", transform.origin)
	var time = (Time.get_ticks_msec() - state_epoch)
	var frame_times = time * 60.0 / 1000.0
	match state:
		States.WALKING:
			transform.origin = lerp(walk_start, walk_destination, min(1, frame_times / float(total_walk_tics)))
		States.ROTATING:
			var angle = lerp(rotation_start, rotation_destination, min(1, frame_times / float(total_rotation_tics)))
			update_basis(angle)


func _physics_process(_delta: float) -> void:

	# kinda fighting with the engine here to detect collisions but i don't think area3d has any deterministic guarantees or whatever

	var s = RECT_SIZE / 2.0
	# top left most tile
	var top_left = Vector3(-s - PATTERN_SIZE * RECT_SIZE, 0, s - PATTERN_SIZE * RECT_SIZE)

	
	timer += 1
	match state:
		States.WAITING:
			if (timer == 180):
				switch_states(States.WALKING)
		States.WALKING:
			var interm = lerp(walk_start, walk_destination, min(1, timer / float(total_walk_tics)))
			var my_tile = interm - top_left
			
			my_tile.x = round(my_tile.x / RECT_SIZE)
			my_tile.z = round(my_tile.z / RECT_SIZE) + 1
			print(my_tile.x)
			print(my_tile.z)
			var index = my_tile.z * LEVEL_SIZE + my_tile.x
			var instances =	$"../LevelObjects".instances
			if index >= 0 and index <= len(instances) - 1:
				var inst = instances[index]
				if is_instance_valid(inst):
					on_collide_with_instance(inst)
			
			
			if (timer == total_walk_tics):
				transform.origin = walk_destination
				if Input.is_action_pressed("rotate_left"):
					rotation_direction = -1
					switch_states(States.ROTATING)
				elif Input.is_action_pressed("rotate_right"):
					rotation_direction = 1
					switch_states(States.ROTATING)
				else:
					switch_states(States.WALKING)
		States.ROTATING:
			if (timer == total_rotation_tics):
				walk_angle = rotation_destination % 360
				if walk_angle < 0:
					walk_angle += 360
				update_basis(walk_angle)
				switch_states(States.WALKING)


func on_collide_with_instance(node: Node3D) -> void:
	if node is BlueSphere:
		if node.got:
			return
		node.get_blue_sphere()
	if node is Ring:
		node.get_ring()
