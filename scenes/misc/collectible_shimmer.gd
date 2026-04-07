extends Node2D

@onready var light := $PointLight2D
@onready var timer := $Timer

func _on_timer_timeout():
	shimmer()

func shimmer():
	var move_time = 0.5
	var tween = create_tween()
	tween.tween_property(light, "position", Vector2(0, -35), move_time)
	await get_tree().create_timer(2).timeout
	light.position = Vector2(0, 35)
	timer.start()
