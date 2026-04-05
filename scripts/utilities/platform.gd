extends Node2D

@export var top_offset: float = -64.0
@export var move_time: float = 0.5

var start_pos: Vector2
var target_pos: Vector2
var tween

func _ready() -> void:
	start_pos = global_position
	target_pos = start_pos + Vector2(0, top_offset)

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		move_to(target_pos)

func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		await get_tree().create_timer(5).timeout
		move_to(start_pos)

func move_to(pos: Vector2):
	if tween and tween.is_running():
		tween.kill()
		
	tween = create_tween()
	tween.tween_property(self, "global_position", pos, move_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
