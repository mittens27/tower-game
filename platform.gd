extends Node2D

var player_on := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player_on:
		pass
	else:
		pass


func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		player_on = true

func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		player_on = false
