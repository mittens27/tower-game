extends CharacterBody2D

enum EnemyState { IDLE, WALK, DIE }
var state: EnemyState = EnemyState.WALK

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

func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity.y += gravity * delta
		
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
		ground_check.scale.x = -1 if sprite.flip_h else 1
		
	turn_timer -= delta
	if turn_timer <= 0:
		if is_on_wall():
			turn()
		elif is_on_floor() and not ground_check.is_colliding():
			turn()

	move_and_slide()

	match state:
		EnemyState.IDLE:
			sprite.play("idle")
		EnemyState.WALK:
			sprite.play("walk")
			velocity.x = direction * speed
		EnemyState.DIE:
			velocity.x = 0
			remove_from_group("enemies")
			
func apply_enemy_data():
	health_component.initialize(enemy_data.max_health, enemy_data.max_health)
	speed = enemy_data.speed
	gravity = enemy_data.gravity
	attack.damage = enemy_data.damage

func _on_hit_received(attack_data, source_position: Vector2):
	print("Gremlin hit.")
	health_component.damage(attack_data.damage)
	apply_knockback(attack_data.knockback, source_position)
	
func apply_knockback(force, source_position: Vector2):
	var knockback_dir = (global_position - source_position).normalized()
	velocity = knockback_dir * force

func _on_died():
	state = EnemyState.DIE
	print("Gremlin killed.")
	queue_free()

func turn():
	direction *= -1
	ground_check.position.x *= 1
	turn_timer = turn_cooldown
