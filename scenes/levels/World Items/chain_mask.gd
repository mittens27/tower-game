extends Sprite2D

@export var max_height: float
@export var elevator: StaticBody2D

@onready var elevator_local_start_y = to_local(elevator.global_position).y

var rect := region_rect

func _ready():
	#var rect := region_rect
	rect.size.y = max_height
	region_rect = rect
		
func _process(_delta):
	var local_elevator_pos = to_local(elevator.global_position)
	
	var moved_distance = local_elevator_pos.y - elevator_local_start_y
	
	var visible_height = clamp(max_height + moved_distance, 0.0, max_height)
	
	#var rect := region_rect
	#rect.position.y = max_height - visible_height
	rect.size.y = visible_height
	region_rect = rect
