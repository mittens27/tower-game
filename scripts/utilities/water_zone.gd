extends Area2D

@export var speed_multipler: float = 0.6
@export var attack_data: AttackData
@export var tick_rate: float = 1.0 #DPS

var bodies_in_zone: Array = []
var timer := 0.0

func _physics_process(delta):
	timer += delta
	
	if timer >= tick_rate:
		timer = 0.0
		
		for body in bodies_in_zone:
			if body.has_method("apply_attack"):
				body.apply_attack(attack_data, global_position)
			if body.has_node("StatusEffectHandler"):
				body.get_node("StatusEffectHandler").activate("poison")

func _on_body_entered(body):
	bodies_in_zone.append(body)

func _on_body_exited(body):
	if body.has_node("StatusEffectHandler"):
		body.get_node("StatusEffectHandler").deactivate("poison")
	bodies_in_zone.erase(body)
