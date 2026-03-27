extends CharacterBody2D

enum PlayerState { IDLE, RUN, ATTACK, JUMP, FALL, DIE }
var state : PlayerState = PlayerState.IDLE

@onready var sprite := $AnimatedSprite2D
@onready var health_component := $HealthComponent
@onready var hurtbox := $Hurtbox
@onready var attack := $Attack/Hitbox
@onready var hitbox := $Attack
@onready var effect_handler := $StatusEffectHandler
@onready var collision_box := $CollisionShape2D
@onready var light_inner := $PlayerLight2
@onready var light_outer := $PlayerLight

@export var player_data: PlayerData

const SPEED = 175.0
const JUMP_VELOCITY = -250.0

var gravity_multiplier: float = 1.0
var current_speed_multiplier: float = 1.0

var is_attacking := false
var spores := false

var facing_direction := 1

func _ready():
	apply_player_data()
	
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_component_health_changed)
	hurtbox.hit_received.connect(_on_hit_received)

	attack.monitorable = false
	attack.monitoring = false
	
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		var applied_gravity = get_gravity() * gravity_multiplier
		velocity += applied_gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		if spores:
			Events.spore_jump.emit(self)
		else:
			Events.player_jumped.emit(self)
		
	# Get the input direction and handle the movement/deceleration.
	velocity.x *= current_speed_multiplier
	
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if direction != 0:
		sprite.flip_h = (direction == -1)
		hitbox.scale.x = -1 if sprite.flip_h else 1
		effect_handler.scale.x = -1 if sprite.flip_h else 1
		facing_direction = -1 if sprite.flip_h else 1
		collision_box.position.x = 2 if sprite.flip_h else -2

	#move pushable objects
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider.is_in_group("pushable"):
			collider.apply_push(velocity.x)
			
	move_and_slide()
	
	#State Machine
	if velocity.x == 0 and is_on_floor():
		state = PlayerState.IDLE
	elif velocity.x != 0 and is_on_floor():
		state = PlayerState.RUN
	if velocity.y < 0 and not is_on_floor():
		state = PlayerState.JUMP
	elif velocity.y >= 0 and not is_on_floor():
		state = PlayerState.FALL
	if Input.is_action_just_pressed("attack"):
		is_attacking = true
	if is_attacking:
		state = PlayerState.ATTACK
	elif not is_attacking:
		attack.monitorable = false
		attack.monitoring = false
		
	match state:
		PlayerState.IDLE:
			sprite.play("idle")
		PlayerState.RUN:
			sprite.play("run")
		PlayerState.JUMP:
			sprite.play("jump")
		PlayerState.FALL:
			sprite.play("fall")
		PlayerState.ATTACK:
			sprite.play("attack")
			attack.monitorable = true
			attack.monitoring = true
		PlayerState.DIE:
			sprite.play("die")
			
func apply_player_data():
	if GMan.player_health <= 0:
		GMan.player_health = player_data.max_health
		
	health_component.initialize(
		player_data.max_health,
		GMan.player_health
		)

func _on_health_component_health_changed(current_health):
	GMan.player_health = current_health
	Events.player_health_changed.emit(current_health)
	print("Player hit. Current health:", current_health)
	
func _on_died():
	print("Player died.")
	GMan.coins = 0
	GMan.player_health = 0
	Events.entity_died.emit(self)
	Events.player_died.emit()
	queue_free()

func _on_hit_received(attack_data, source_position: Vector2):
	health_component.damage(attack_data.damage)
	Events.player_hurt.emit(self)

func apply_attack(attack_data, source_position):
	health_component.damage(attack_data.damage)

func _on_animated_sprite_2d_animation_finished():
	if sprite.animation == "attack":
		is_attacking = false
		
func apply_spore_buff(duration: float, gravity_scale: float):
	spores = true
	Events.spores_collected.emit(self)
	gravity_multiplier = gravity_scale
	effect_handler.activate("spores")
	light_colour("spore_colours")
	
	await get_tree().create_timer(duration).timeout
	
	spores = false
	gravity_multiplier = 1.0
	effect_handler.deactivate("spores")
	light_colour("spore_colours")
	
func light_colour(type):
	var dim_time = 0.5
	var tween = create_tween()
	if type == "spore_colours":
		var target_color_one = Color(0.94, 0.43, 0.00, 0.68) if not spores else Color(0.176, 0.396, 1.0, 0.753)
		var target_color_two = Color(0.99, 0.48, 0.13, 0.68) if not spores else Color(0.248, 0.461, 1.0, 0.753)
		tween.tween_property(light_outer, "color", target_color_one, dim_time)
		tween.tween_property(light_inner, "color", target_color_two, dim_time)
