extends CharacterBody2D

@export var potion_data: PotionData

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
	
func _on_area_2d_body_entered(body: CharacterBody2D):
	if not body.is_in_group("player") or GMan.player_health == GMan.player_max_health:
		return
	elif body.is_in_group("player"):
		body.potion(potion_data)
		queue_free()
