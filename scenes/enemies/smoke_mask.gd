extends CharacterBody2D

enum EnemyState { IDLE, AGGRO, HURT, SURPRISED, DIE }
var state: EnemyState = EnemyState.IDLE

@export var enemy_data: EnemyData

@onready var sprite := $Mask
@onready var anim := $AnimationPlayer
@onready var attack := $Attack/Hitbox
@onready var health_component := $HealthComponent
@onready var hurtbox := $Hurtbox
@onready var ray_front := $Ray_Front
@onready var ray_up := $Ray_Up
@onready var ray_down := $Ray_Down

var room_controller: Node2D
var flash_tween: Tween

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

var orbit_direction := 1
@export var orbit_distance := 60.0

var was_touching_ceiling := false
var was_touching_floor := false

var player: Node2D = null
var can_attack := false
var is_aggro := false
@export var aggro_memory_time := 2.0
var aggro_timer := 0.0

func _ready():
	apply_enemy_data()
	sprite.material = sprite.material.duplicate()
	
	hurtbox.hit_received.connect(_on_hit_received)
	health_component.died.connect(_on_died)

func _physics_process(delta):
	#--- AGGRO CHECK ---
	if player:
		if can_see_player():
			aggro_timer = aggro_memory_time
			is_aggro = true
		else:
			aggro_timer -= delta
			if aggro_timer <= 0:
				is_aggro = false
	
	#--- DIRECTION ---
	if is_aggro and player:
		var to_player = player.global_position - global_position
		var dir_to_player = to_player.normalized()
		var tangent = Vector2(-dir_to_player.y, dir_to_player.x) * orbit_direction
		
		var distance_error = to_player.length() - orbit_distance
		var radial = dir_to_player * distance_error * 0.02
		
		direction = (tangent * 1.5 + radial).normalized()
		velocity = direction * aggro_speed

	else:
		handle_wandering(delta)
		velocity = direction * speed
		
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
	
	move_and_slide()

func apply_enemy_data():
	health_component.initialize(enemy_data.max_health, enemy_data.max_health)
	speed = enemy_data.speed
	gravity = enemy_data.gravity
	aggro_speed = enemy_data.aggro_speed
	knockback_decay = enemy_data.knockback_decay
	
func _on_hit_received(attack_data, source_position: Vector2):
	health_component.damage(attack_data.damage)
	apply_knockback(attack_data.knockback, source_position)
	flash_white()
	
func _on_died():
	if room_controller:
		room_controller.on_enemy_died(self)
	state = EnemyState.DIE
	Events.entity_died.emit(self)
	enemy_died.emit()
	print("Persona killed.")
	queue_free()

func apply_knockback(force, source_position: Vector2):
	var knockback_dir = (global_position - source_position).normalized()
	knockback_velocity = knockback_dir * force
	
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
		direction.y -= -1.0
		
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
