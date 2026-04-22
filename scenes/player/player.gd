extends CharacterBody2D

enum PlayerState { IDLE, RUN, ATTACK, JUMP, FALL, DIE }
var state : PlayerState = PlayerState.IDLE

@onready var sprite := $Sprite2D
@onready var anim := $AnimationPlayer
@onready var health_component := $HealthComponent
@onready var hurtbox := $Hurtbox
@onready var attack := $Attack/Hitbox
@onready var hitbox := $Attack
@onready var effect_handler := $StatusEffectHandler
@onready var collision_box := $CollisionShape2D
@onready var light_inner := $PlayerLight2
@onready var light_outer := $PlayerLight

@export var player_data: PlayerData
@export var drop_through_time := 0.2

var flash_tween: Tween

const SPEED = 175.0
const JUMP_VELOCITY = -250.0

var gravity_multiplier: float = 1.0
var current_speed_multiplier: float = 1.0

var is_attacking := false
var spores := false

var facing_direction := 1

var dropping := false
const ONE_WAY_LAYER := 12

func _ready():
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_component_health_changed)
	hurtbox.hit_received.connect(_on_hit_received)
	Events.attack_landed.connect(_on_attack_landed)


	apply_player_data()

	attack.monitorable = false
	attack.monitoring = false
	
func _physics_process(delta):
	#one way platforms
	var input_down := Input.is_action_pressed("ui_down")
	var jump_pressed := Input.is_action_just_pressed("ui_accept")
	
	if input_down and jump_pressed and is_on_one_way_platform():
		drop_through_platform()
	elif jump_pressed:
		jump()
	
	# Add the gravity.
	if not is_on_floor():
		var applied_gravity = get_gravity() * gravity_multiplier
		velocity += applied_gravity * delta
		
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
		
		if collider == null:
			continue
		if not is_instance_valid(collider):
			continue
		
		if is_instance_valid(collider) and collider.is_in_group("pushable"):
			collider.apply_push(velocity.x)
			
	move_and_slide()
	
	#State Machine
	if not is_attacking:
		if velocity.x == 0 and is_on_floor():
			state = PlayerState.IDLE
		elif velocity.x != 0 and is_on_floor():
			state = PlayerState.RUN
		elif velocity.y < 0:
			state = PlayerState.JUMP
		elif velocity.y >= 0:
			state = PlayerState.FALL

	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		state = PlayerState.ATTACK
		
	match state:
		PlayerState.IDLE:
			play_anim("idle")
		PlayerState.RUN:
			play_anim("walk")
		PlayerState.JUMP:
			play_anim("jump")
		PlayerState.FALL:
			play_anim("fall")
		PlayerState.ATTACK:
			play_anim("attack")
		PlayerState.DIE:
			play_anim("die")
			
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
	apply_knockback(attack_data.knockback, source_position)
	Events.player_hurt.emit(self)
	
	flash_white()

func apply_knockback(force, source_position: Vector2):
	var knockback_dir = (global_position - source_position).normalized()
	velocity = knockback_dir * force
	velocity.y = force * -0.25

func apply_attack(attack_data, source_position):
	health_component.damage(attack_data.damage)
	flash_white()
		
func potion(potion_data):
	Events.potion_collected.emit(self, potion_data)
	if potion_data.type == "healing_potion":
		health_component.heal(potion_data.healing)
		effect_handler.activate(potion_data.effect)
		await get_tree().create_timer(1).timeout
		effect_handler.deactivate(potion_data.effect)
		
func jump():
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		if spores:
			Events.spore_jump.emit(self)
		else:
			Events.player_jumped.emit(self)

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

func drop_through_platform():
	if dropping:
		return
	
	dropping = true
	set_collision_mask_value(12, false)
	velocity.y = 50
	await get_tree().create_timer(drop_through_time).timeout
	set_collision_mask_value(12, true)
	dropping = false
	
func is_on_one_way_platform() -> bool:
	if not is_on_floor():
		return false
		
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		
		if collider is TileMapLayer:
			var tilemap := collider as TileMapLayer
			
			var local_pos = tilemap.to_local(collision.get_position())
			var coords = tilemap.local_to_map(local_pos)
			
			var tile_data = tilemap.get_cell_tile_data(coords)
			
			if tile_data and tile_data.get_custom_data("one_way"):
				return true
		if collider != TileMapLayer:
			var mask_value = collider.get_collision_mask()
			if mask_value == 1031:
				return true
	return false

func _on_animation_player_animation_finished(anim_name: StringName):
	if anim_name == "attack":
		is_attacking = false

func play_anim(name: String):
	if anim.current_animation != name:
		anim.play(name)
		
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
	
func apply_attack_recoil(force: float, direction: Vector2):
	velocity = -direction.normalized() * force
	velocity.y = force * -0.15

func _on_attack_landed(attacker, target, attack_data):
	if not attacker.is_in_group("player"):
		return
	
	print("Player landed a hit!")
	
	var attack_dir = Vector2(facing_direction, 0)
	apply_attack_recoil(500.0, attack_dir)
	GEffects.hit_stop()
