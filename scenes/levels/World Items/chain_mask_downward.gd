extends Sprite2D

@export var max_height: float
@export var elevator: StaticBody2D

var elevator_local_start_y: float
#@onready var elevator_local_start_y = to_local(elevator.global_position).y

var bottom_y: float
var top_y: float

func _ready():
	if elevator == null:
		push_error("Elevator reference is missing on %s" % name)
		return
	bottom_y = to_local(elevator.start_pos).y
	top_y = to_local(elevator.target_pos).y
	
	print("Upward Elevator ref:", elevator)
	
func _process(_delta):
	if elevator == null:
		return
	
	var local_y = to_local(elevator.global_position).y
	
	# Normalize position between top and bottom
	var t = inverse_lerp(bottom_y, top_y, local_y)
	t = clamp(t, 0.0, 1.0)
	
	var visible_height = t * max_height
	
	var rect := region_rect
	rect.position.y = max_height - visible_height
	rect.size.y = visible_height
	region_rect = rect
