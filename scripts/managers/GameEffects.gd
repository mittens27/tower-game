extends Node
class_name GameEffects

func hit_stop(duration: float = 0.08) -> void:
	Engine.time_scale = 0.5
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
