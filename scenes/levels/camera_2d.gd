extends Camera2D

@export var lookAhead := 60.0
@export var followSpeed := 4.0

@export var player: CharacterBody2D

func _process(delta):
	global_position = global_position.round()
	
	if player == null:
		return
	
	var dir = player.facing_direction
	var target_x: float = dir * lookAhead
	
	global_position = lerp(global_position, player.global_position, followSpeed * delta)
	offset.x = lerp(offset.x, target_x, followSpeed * delta)
