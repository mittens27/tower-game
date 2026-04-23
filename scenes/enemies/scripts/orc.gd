extends CharacterBody2D

enum EnemyState { IDLE_LEFT, IDLE_RIGHT, WALK, ATTACK, DIE }
var state: EnemyState = EnemyState.WALK

@export var enemy_data: EnemyData

@onready var ground_check := $RayCast2D
@onready var attack := $Attack/Hitbox
@onready var axe_attack := $AxeAttack
@onready var axe_attack_hitbox := $AxeAttack/Hitbox
@onready var health_component := $HealthComponent
@onready var hurtbox := $Hurtbox
@onready var sprite := $Sprite2D
@onready var anim := $AnimationPlayer
@onready var effect_handler := $StatusEffectHandler

var flash_tween: Tween

signal enemy_died()

var room_controller: Node2D

var gravity: float
var speed: float
var blood_gradient: Gradient
var blood_scene: PackedScene

var facing_direction := 1
var turn_cooldown := 0.1
var turn_timer := 0.0

var player: Node2D = null
var is_aggro := false
var can_attack := true
var is_attacking := false
@export var aggro_memory_time := 2.0
var aggro_timer := 0.0

var last_hit_source_pos: Vector2 = Vector2.ZERO

var knockback_velocity := Vector2.ZERO
var knockback_decay: float

func _ready():
	apply_enemy_data()
	sprite.material = sprite.material.duplicate()
	
	hurtbox.hit_received.connect(_on_hit_received)
	health_component.died.connect(_on_died)
	
	axe_attack_hitbox.monitorable = false
	axe_attack_hitbox.monitoring = false

func _physics_process(delta):
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if player:
		aggro_timer = aggro_memory_time
		is_aggro = true
	else:
		aggro_timer -= delta
		if aggro_timer <= 0:
			is_aggro = false
	
	if is_attacking:
		velocity.x = 0
	else:
		if is_aggro:
			chase_player()
		else:
			patrol(delta)
		
	ground_check.scale.x = 1 if (facing_direction == 1) else -1

	#--- KNOCKBACK ---
	velocity = velocity.lerp(knockback_velocity, 0.5)
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	knockback_velocity = knockback_velocity.limit_length(50)
	
	move_and_slide()

	match state:
		EnemyState.IDLE_LEFT:
			anim.play("idle_left")
		EnemyState.IDLE_RIGHT:
			anim.play("idle_right")
		EnemyState.WALK:
			if not is_attacking:
				if is_aggro:
					anim.set_speed_scale(2)
					velocity.x = facing_direction * speed * 1.5
				else:
					anim.set_speed_scale(1)
					velocity.x = facing_direction * speed
				if facing_direction == -1:
					anim.play("walk_left")
				elif facing_direction == 1:
					anim.play("walk_right")
		EnemyState.ATTACK:
			velocity.x = 0
			anim.set_speed_scale(1)
			if facing_direction == -1:
				anim.play("attack_left")
			elif facing_direction == 1:
				anim.play("attack_right")
		EnemyState.DIE:
			velocity.x = 0
			remove_from_group("enemies")
	if is_attacking:
		state = EnemyState.ATTACK
			
func apply_enemy_data():
	health_component.initialize(enemy_data.max_health, enemy_data.max_health)
	speed = enemy_data.speed
	gravity = enemy_data.gravity

func _on_hit_received(attack_data, source_position: Vector2):
	last_hit_source_pos = source_position
	health_component.damage(attack_data.damage)
	apply_knockback(attack_data.knockback, source_position)
	flash_white()
	
func apply_knockback(force, source_position: Vector2):
	var knockback_dir = (global_position - source_position).normalized()
	knockback_velocity = knockback_dir * force

func _on_died():
	var hit_position = global_position
	call_deferred("spawn_blood", hit_position, last_hit_source_pos)

	if room_controller:
		room_controller.on_enemy_died(self)
	state = EnemyState.DIE
	Events.entity_died.emit(self)
	enemy_died.emit()
	print("Orc killed.")
	queue_free()

func turn():
	facing_direction *= -1
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

	get_tree().current_scene.add_child(blood)
	blood.set_gradient(enemy_data.blood_gradient)
	blood.global_position = hit_position
	blood.set_direction(direction)
	
	blood.restart()

func _on_detection_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_detection_body_exited(body):
	if body.is_in_group("player"):
		player = null

func chase_player():
	if player == null:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	if distance < 40:
		if can_attack and not is_attacking:
			try_attack()
			return
		
	facing_direction = sign(player.global_position.x - global_position.x)
	state = EnemyState.WALK

func try_attack():
	if can_attack:
		can_attack = false
		is_attacking = true
		state = EnemyState.ATTACK
		
func patrol(delta):
	turn_timer -= delta
	if turn_timer <= 0:
		if is_on_wall():
			turn()
		elif is_on_floor() and not ground_check.is_colliding():
			turn()
	state = EnemyState.WALK


func _on_animation_player_animation_finished(anim_name: StringName):
	if anim_name == "attack_left" or anim_name == "attack_right":
		is_attacking = false
		
		await get_tree().create_timer(1.5).timeout
		can_attack = true

func apply_attack(attack_data, source_position):
	health_component.damage(attack_data.damage)
	flash_white()
	
func flash_white():
	if flash_tween:
		flash_tween.kill()

	sprite.material.set_shader_parameter("flash_amount", 1.0)

	flash_tween = create_tween()
	flash_tween.tween_method(
		func(value): sprite.material.set_shader_parameter("flash_amount", value),
		1.0,
		0.0,
		0.08
	)
