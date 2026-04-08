extends CharacterBody2D

enum EnemyState { IDLE, WALK, DIE }
var state: EnemyState = EnemyState.WALK

@export var enemy_data: EnemyData

@onready var ground_check := $RayCast2D
@onready var attack := $Attack/Hitbox
@onready var health_component := $HealthComponent
@onready var hurtbox := $Hurtbox
@onready var sprite := $Sprite2D
@onready var anim := $AnimationPlayer
@onready var eyes := $eyes

signal enemy_died()

var room_controller: Node2D

var gravity: float
var speed: float
var blood_gradient: Gradient
var blood_scene: PackedScene

var facing_direction := 1
var turn_cooldown := 0.1
var turn_timer := 0.0

var last_hit_source_pos: Vector2 = Vector2.ZERO

func _ready():
	apply_enemy_data()
	
	hurtbox.hit_received.connect(_on_hit_received)
	health_component.died.connect(_on_died)

func _physics_process(delta):
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
			anim.play("idle")
		EnemyState.WALK:
			anim.play("run")
			velocity.x = facing_direction * speed
		EnemyState.DIE:
			velocity.x = 0
			remove_from_group("enemies")
			
func apply_enemy_data():
	health_component.initialize(enemy_data.max_health, enemy_data.max_health)
	speed = enemy_data.speed
	gravity = enemy_data.gravity

func _on_hit_received(attack_data, source_position: Vector2):
	last_hit_source_pos = source_position
	health_component.damage(attack_data.damage)
	apply_knockback(attack_data.knockback, source_position)
	
func apply_knockback(force, source_position: Vector2):
	var knockback_dir = (global_position - source_position).normalized()
	velocity = knockback_dir * force

func _on_died():
	var hit_position = global_position
	#spawn_blood(hit_position, last_hit_source_pos)
	call_deferred("spawn_blood", hit_position, last_hit_source_pos)

	if room_controller:
		room_controller.on_enemy_died(self)
	state = EnemyState.DIE
	Events.entity_died.emit(self)
	enemy_died.emit()
	print("Gremlin killed.")
	queue_free()

func turn():
	facing_direction *= -1
	ground_check.position.x *= 1
	eyes.offset.x *= -1
	turn_timer = turn_cooldown
	
func spawn_blood(hit_position: Vector2, source_pos: Vector2):
	var blood = enemy_data.blood_scene.instantiate()
	if source_pos == Vector2.ZERO:
		source_pos = hit_position
	
	var direction = hit_position - source_pos
	
	if direction.length() == 0:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()
	
	#var spawn_pos = hit_position + direction * 8 #offset position

	get_tree().current_scene.add_child(blood)
	blood.set_gradient(enemy_data.blood_gradient)
	blood.global_position = hit_position
	blood.set_direction(direction)
	
	blood.restart()
