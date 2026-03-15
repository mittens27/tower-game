extends CharacterBody2D

@onready var sprite := $AnimatedSprite2D

const SPEED = 175.0
const JUMP_VELOCITY = -250.0


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if velocity.y < 0 and not is_on_floor():
		sprite.play("jump")
	elif velocity.y >= 0 and not is_on_floor():
		sprite.play("fall")

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		if velocity.y == 0:
			sprite.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if velocity.y == 0:
			sprite.play("idle")
		
	if direction != 0:
		sprite.flip_h = (direction == -1)

	move_and_slide()
