extends Sprite2D

@export var max_height: float
@export var elevator: StaticBody2D

@onready var elevator_local_start_y = to_local(elevator.global_position).y

@onready var bottom_y = to_local(elevator.start_pos).y
@onready var top_y = to_local(elevator.target_pos).y
#var rect := region_rect

func _process(_delta):
	var local_y = to_local(elevator.global_position).y
	
	# Normalize position between top and bottom
	var t = inverse_lerp(bottom_y, top_y, local_y)
	t = clamp(t, 0.0, 1.0)
	
	var visible_height = t * max_height
	
	var rect := region_rect
	rect.position.y = max_height - visible_height
	rect.size.y = visible_height
	region_rect = rect
