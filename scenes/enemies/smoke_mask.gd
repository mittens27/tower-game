extends CharacterBody2D

enum EnemyState { IDLE, SUSPICIOUS, CHASE, ATTACK, HURT, DIE }
var current_state = EnemyState.IDLE
enum Mask { HAPPY, ANGRY, ATTACK, SURPRISED, HURT, SAD }
var current_mask = Mask.HAPPY

@export var enemy_data: EnemyData

@onready var mask_sprite := $Mask
@onready var smoke_sprite := $Smoke
@onready var anim := $AnimationPlayer
@onready var attack := $Attack/Hitbox
@onready var health_component := $HealthComponent
@onready var hurtbox := $Hurtbox
@onready var ray_front := $Ray_Front
@onready var ray_up := $Ray_Up
@onready var ray_down := $Ray_Down

var room_controller: Node2D
var flash_tween_mask: Tween
var flash_tween_smoke: Tween

signal enemy_died()

var gravity: float
var speed: float
var aggro_speed: float

var knockback_velocity := Vector2.ZERO
var knockback_decay: float

var direction := Vector2.ZERO
@export var change_direction_time := 2.0
var change_direction_time_left := 0.0
var target_direction := Vector2.ZERO

var facing_direction := 1

var orbit_direction := 1
@export var orbit_distance := 60.0

var was_touching_ceiling := false
var was_touching_floor := false

var player: Node2D = null

@export var suspicion_time := 2.0
var suspicion_timer := 0.0
var is_suspicious: bool = false

var can_attack := true
var is_aggro := false
var is_attacking := false
@export var aggro_memory_time := 2.0
var aggro_timer := 0.0

@export var attack_range := 28.0
@export var ideal_attack_distance := 15.0

var is_taking_damage: bool = false

func _ready():
	apply_enemy_data()
	mask_sprite.material = mask_sprite.material.duplicate()
	smoke_sprite.material = smoke_sprite.material.duplicate()
	
	hurtbox.hit_received.connect(_on_hit_received)
	health_component.died.connect(_on_died)

func _physics_process(delta):
	#--- MOVEMENT ---
	if is_taking_damage:
		pass
	elif is_aggro:
		chase_player()
	elif is_suspicious:
		inspect_target()
	else:
		enter_state(EnemyState.IDLE)
		handle_wandering(delta)
		velocity = direction * speed
		
	# --- VISUAL DIRECTION ---
	update_facing()
	
	#--- AGGRO CHECK ---
	if player:
		if can_see_player():
			if not is_aggro:
				is_suspicious = true
				suspicion_timer += delta
				
				if suspicion_timer >= suspicion_time:
					is_aggro = true
					is_suspicious = false
					suspicion_timer = 0.0
			else:
				aggro_timer = aggro_memory_time
		else:
			suspicion_timer = 0.0
			is_suspicious = false
			
			aggro_timer -= delta
			if aggro_timer <= 0:
				is_aggro = false
		
	#--- KNOCKBACK ---
	var base_velocity = velocity

	if knockback_velocity.length() > 0.1:
		velocity = knockback_velocity
	else:
		velocity = base_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	knockback_velocity = knockback_velocity.limit_length(150)

	#--- AVOIDANCE ---
	update_rays()
	avoid_obstacles()
	
	update_smoke()
	move_and_slide()
	
func enter_state(new_state):
	current_state = new_state
	match current_state:
		EnemyState.IDLE:
			set_mask(Mask.HAPPY)
		EnemyState.SUSPICIOUS:
			set_mask(Mask.SURPRISED)
		EnemyState.CHASE:
			set_mask(Mask.ANGRY)
		EnemyState.ATTACK:
			set_mask(Mask.ATTACK)
		EnemyState.HURT:
			set_mask(Mask.HURT)
			
func set_mask(new_mask):
	current_mask = new_mask
	match current_mask:
		Mask.HAPPY:
			play_anim("mask_happy")
		Mask.SURPRISED:
			play_anim("mask_surprised_side")
		Mask.ANGRY:
			play_anim("mask_mad")
		Mask.ATTACK:
			play_anim("mask_attack")
		Mask.HURT:
			play_anim("mask_hurt")
		Mask.SAD:
			play_anim("mask_sad")
			
func update_smoke():
	if current_mask == Mask.ANGRY:
		smoke_sprite.play("angry")
	elif current_mask == Mask.ATTACK:
		smoke_sprite.play("attack")
	elif current_mask == Mask.HURT:
		smoke_sprite.play("hurt")
	else:
		smoke_sprite.play("idle")
			
func play_anim(animation_name: String):
	if anim.current_animation != animation_name:
		anim.play(animation_name)

func apply_enemy_data():
	health_component.initialize(enemy_data.max_health, enemy_data.max_health)
	speed = enemy_data.speed
	gravity = enemy_data.gravity
	aggro_speed = enemy_data.aggro_speed
	knockback_decay = enemy_data.knockback_decay
	
func chase_player():
	if player == null:
		return
		
	var to_player = player.global_position - global_position
	var dir_to_player = to_player.normalized()
	var tangent = Vector2(-dir_to_player.y, dir_to_player.x) * orbit_direction
		
	var distance_error = to_player.length() - orbit_distance
	var radial = dir_to_player * distance_error * 0.02
		
	direction = (tangent * 1.5 + radial).normalized()
	velocity = direction * aggro_speed
	
	var attack_target = player.global_position + Vector2(0, -20)
	var to_target = attack_target - global_position
	var distance = to_target.length()
	
	if can_attack and not is_attacking:
		if distance > ideal_attack_distance:
			direction = to_target.normalized()
			velocity = direction * aggro_speed
		else:
			try_attack()
			return
			
	if is_attacking:
		direction = to_target.normalized()
		velocity = direction * aggro_speed * 0.75
	
	if not is_attacking and not is_taking_damage:
		enter_state(EnemyState.CHASE)
	
func inspect_target():
	if player == null:
		return
	
	var to_player = player.global_position - global_position
	var dir_to_player = to_player.normalized()
	var tangent = Vector2(-dir_to_player.y, dir_to_player.x) * orbit_direction
		
	var distance_error = to_player.length() - orbit_distance
	var radial = dir_to_player * distance_error * 0.02
		
	direction = (tangent * 1.5 + radial).normalized()
	velocity = direction * aggro_speed
	
	enter_state(EnemyState.SUSPICIOUS)
	update_suspicious_mask()
	
func update_suspicious_mask():
	if player == null:
		return
	
	var offset = player.global_position - global_position
	var vertical_difference = offset.y
	var horizontal_difference = abs(offset.x)
	
	if vertical_difference > 24 and horizontal_difference < 32:
		play_anim("mask_surprised_down")
	else:
		play_anim("mask_surprised_side")
	
func handle_wandering(delta):
	change_direction_time_left -= delta
	
	if change_direction_time_left <= 0:
		target_direction = get_random_direction()
		change_direction_time_left = change_direction_time
		
	direction = direction.lerp(target_direction, delta * 1.5)

func get_random_direction():
	return Vector2(
		randf_range(-1, 1),
		randf_range(-0.5, 0.5)
	).normalized()
	
func update_rays():
	ray_front.target_position = direction * 25.0
	
func update_facing():
	if velocity.x > 5 and facing_direction != 1:
		turn(1)
	elif velocity.x < -5 and facing_direction != -1:
		turn (-1)
		
func turn(dir: int):
	facing_direction = dir
	
	var flipped := dir == -1
	
	if not is_taking_damage:
		mask_sprite.flip_h = flipped
		mask_sprite.position.x = abs(mask_sprite.position.x) * dir
	smoke_sprite.flip_h = flipped if dir == -1 else not flipped
	
func avoid_obstacles():
	if ray_front.is_colliding():
		var normal = ray_front.get_collision_normal()
		var avoid_dir = normal
		
		direction = direction.lerp(avoid_dir, 0.2).normalized()
	
	var touching_ceiling = ray_up.is_colliding()
	var touching_floor = ray_down.is_colliding()
	
	if touching_ceiling and not was_touching_ceiling:
		orbit_direction *= -1
		
	if touching_ceiling:
		direction.y += 1.0
		
	if touching_floor and not was_touching_floor:
		orbit_direction *= -1
		
	if touching_floor:
		direction.y += -1.0
		
	was_touching_ceiling = touching_ceiling
	was_touching_floor = touching_floor
		
	direction = direction.normalized()

func _on_detection_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_detection_body_exited(body):
	if body.is_in_group("player"):
		player = null

func can_see_player():
	var space = get_world_2d().direct_space_state #looks for physics collisions in world
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position) #casts a ray line from enemy to player
	query.exclude = [self] #makes sure ray doesnt detect the enemy itself
	var result = space.intersect_ray(query) #checks to see if anything is between enemy and player along ray line

	return result.is_empty() or result.collider == player
	
func try_attack():
	if can_attack:
		can_attack = false
		is_attacking = true
		enter_state(EnemyState.ATTACK)

func _on_hit_received(attack_data, source_position: Vector2):
	health_component.damage(attack_data.damage)
	apply_knockback(attack_data.knockback, source_position)
	flash_white()
	take_damage()
	
func take_damage():
	enter_state(EnemyState.HURT)
	is_taking_damage = true
	await get_tree().create_timer(0.3).timeout
	set_mask(Mask.SAD)
	await get_tree().create_timer(0.5).timeout
	is_taking_damage = false
	update_facing()
	enter_state(EnemyState.CHASE)

func _on_died():
	if room_controller:
		room_controller.on_enemy_died(self)
	current_state = EnemyState.DIE
	Events.entity_died.emit(self)
	enemy_died.emit()
	print("Persona killed.")
	queue_free()

func apply_knockback(force, source_position: Vector2):
	var knockback_dir = (global_position - source_position).normalized()
	knockback_velocity = knockback_dir * force
	
func flash_white():
	if flash_tween_mask:
		flash_tween_mask.kill()
	if flash_tween_smoke:
		flash_tween_smoke.kill()

	mask_sprite.material.set_shader_parameter("flash_amount", 1.0)
	smoke_sprite.material.set_shader_parameter("flash_amount", 1.0)

	flash_tween_mask = create_tween()
	flash_tween_mask.tween_method(
		func(value): mask_sprite.material.set_shader_parameter("flash_amount", value),
		1.0,
		0.0,
		0.08
	)
	flash_tween_smoke = create_tween()
	flash_tween_smoke.tween_method(
		func(value): smoke_sprite.material.set_shader_parameter("flash_amount", value),
		1.0,
		0.0,
		0.08
	)

func _on_animation_player_animation_finished(anim_name: StringName):
	if anim_name == "mask_attack" and is_attacking:
		is_attacking = false
		await get_tree().create_timer(4).timeout
		can_attack = true
