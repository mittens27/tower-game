extends CharacterBody2D

@export var push_strength := 0.5
@export var friction := 800.0

func apply_push(force: float):
	velocity.x = force * push_strength

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	velocity.x = move_toward(velocity.x, 0, friction * delta)
	move_and_slide()
