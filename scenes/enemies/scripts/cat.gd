extends CharacterBody2D

enum EnemyState { IDLE_LEFT, IDLE_RIGHT, WALK_LEFT, WALK_RIGHT, TURN_LEFT, TURN_RIGHT, DIE }
var state: EnemyState = EnemyState.WALK_RIGHT

@export var enemy_data: EnemyData

@onready var ground_check := $RayCast2D
@onready var attack := $Attack/Hitbox
@onready var health_component := $HealthComponent
@onready var hurtbox := $Hurtbox
@onready var sprite := $AnimatedSprite2D

var gravity: float
var speed: float

var direction := 1
var turn_cooldown := 0.1
var turn_timer := 0.0

func _ready():
	apply_enemy_data()
	
	hurtbox.hit_received.connect(_on_hit_received)
	health_component.died.connect(_on_died)
	
	attack.monitoring = false
	attack.monitorable = false

func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity.y += gravity * delta
		
	#if velocity.x != 0:
		#sprite.flip_h = velocity.x < 0
		#ground_check.scale.x = -1 if sprite.flip_h else 1
		
	turn_timer -= delta
	if turn_timer <= 0:
		if is_on_wall():
			if direction == 1:
				state = EnemyState.TURN_LEFT
			elif direction == -1:
				state = EnemyState.TURN_RIGHT
		elif is_on_floor() and not ground_check.is_colliding():
			if direction == 1:
				state = EnemyState.TURN_LEFT
			elif direction == -1:
				state = EnemyState.TURN_RIGHT

	move_and_slide()

	match state:
		EnemyState.IDLE_LEFT:
			sprite.play("idle_left")
		EnemyState.IDLE_RIGHT:
			sprite.play("idle_right")
		EnemyState.WALK_LEFT:
			sprite.play("walk_left")
			velocity.x = direction * speed
		EnemyState.WALK_RIGHT:
			sprite.play("walk_right")
			velocity.x = direction * speed
		EnemyState.TURN_LEFT:
			sprite.play("turn_left")
			velocity.x = 0
		EnemyState.TURN_RIGHT:
			sprite.play("turn_right")
			velocity.x = 0
		EnemyState.DIE:
			velocity.x = 0
			remove_from_group("enemies")
			
func apply_enemy_data():
	health_component.initialize(enemy_data.max_health, enemy_data.max_health)
	speed = enemy_data.speed
	gravity = enemy_data.gravity

func _on_hit_received(attack_data, source_position: Vector2):
	print("Gremlin hit.")
	health_component.damage(attack_data.damage)
	apply_knockback(attack_data.knockback, source_position)
	
func apply_knockback(force, source_position: Vector2):
	var knockback_dir = (global_position - source_position).normalized()
	velocity = knockback_dir * force

func _on_died():
	state = EnemyState.DIE
	print("Cat brutally murdered. You monster.")
	queue_free()

func turn():
	direction *= -1
	ground_check.scale.x = 1 if (direction == 1) else -1
	turn_timer = turn_cooldown

func _on_animated_sprite_2d_animation_finished():
	if sprite.animation == "turn_left":
		state = EnemyState.WALK_LEFT
		turn()
	if sprite.animation == "turn_right":
		state = EnemyState.WALK_RIGHT
		turn()
