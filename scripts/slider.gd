extends Node2D

signal slider_hit(slider_node)
signal slider_miss(slider_node)

var ANGLE_ERROR: float = 0.5

var checkpoints: PackedVector2Array = []
var creation_time: int
var current_time: int
var lifetime: int

var hit_radius: int = 80
var curr_point_index = 0
var states: Array = ["not active", "active", "finished"]
var state: int = 0

@onready var path_line: Line2D = $PathLine
@onready var start_indicator: Sprite2D = $StartIndicator

func _ready() -> void:
	creation_time = Time.get_ticks_msec()
	if checkpoints.size() > 0:
		start_indicator.position = checkpoints[0]
		start_indicator.visible = true
	if checkpoints.size() >= 2:
		path_line.points = checkpoints


func _process(delta: float) -> void:
	current_time = Time.get_ticks_msec()
	if (current_time - creation_time) > lifetime:
		miss()
	if state == 0:
		if current_time >= creation_time and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var mouse_pos = get_global_mouse_position()
			if mouse_pos.distance_to(checkpoints[0]) < hit_radius:
				activate()
	elif state == 1:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			miss()
			return
		var mouse_pos = get_global_mouse_position()
		if mouse_pos.distance_to(checkpoints[curr_point_index]) < hit_radius:
			curr_point_index += 1
			if curr_point_index >= checkpoints.size():
				hit()
		'''else:
			var perf_vec: Vector2 = checkpoints[curr_point_index] - checkpoints[curr_point_index - 1]
			var user_vec: Vector2 = mouse_pos - checkpoints[curr_point_index - 1]
			if abs(perf_vec.angle() - user_vec.angle()) > ANGLE_ERROR:
				miss()'''
			

func activate():
	state = 1
	curr_point_index = 1
	start_indicator.visible = false
		
		
func hit():
	state = 2
	slider_hit.emit(self)
	queue_free()
	
	
func miss():
	state = 2
	slider_miss.emit(self)
	queue_free()


func get_end_position() -> Vector2:
	if checkpoints.size() > 0:
		return checkpoints[-1]
	return global_position
