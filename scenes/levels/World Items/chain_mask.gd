extends Sprite2D

@export var max_height: float
@export var elevator: StaticBody2D

var elevator_local_start_y: float

var rect := region_rect

func _ready():
	if elevator == null:
		push_error("Elevator reference is missing on %s" % name)
		return
	elevator_local_start_y = to_local(elevator.global_position).y
	
	rect.size.y = max_height
	region_rect = rect
	
	print("Upward Elevator ref:", elevator)
	
func _process(_delta):
	if elevator == null:
		return
	
	var local_elevator_pos = to_local(elevator.global_position)
	
	var moved_distance = local_elevator_pos.y - elevator_local_start_y
	
	var visible_height = clamp(max_height + moved_distance, 0.0, max_height)
	
	#var rect := region_rect
	#rect.position.y = max_height - visible_height
	rect.size.y = visible_height
	region_rect = rect
