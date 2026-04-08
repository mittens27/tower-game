extends Node2D

@onready var plant_player := $Plant
@onready var spore_player := $Spores
@onready var health_component := $HealthComponent
@onready var hurtbox := $Hurtbox
@onready var attack_hitbox := $Attack/Hitbox

@export var enemy_data: EnemyData

var blood_scene: PackedScene
var blood_gradient: Gradient

var last_hit_source_pos: Vector2 = Vector2.ZERO

var idle_loops = 0
var spore_active := false

func _ready():
	apply_enemy_data()
	
	health_component.died.connect(_on_died)
	hurtbox.hit_received.connect(_on_hit_received)
	health_component.died.connect(_on_died)
	hurtbox.hit_received.connect(_on_hit_received)
	
	plant_player.frame_changed.connect(_on_plant_frame_changed)
	plant_player.animation_looped.connect(_on_plant_animation_looped)
	plant_player.animation_finished.connect(_on_plant_animation_finished)
	spore_player.animation_finished.connect(_on_spores_animation_finished)
	
	spore_player.visible = false
	spore_active = true
	attack_hitbox.monitorable = false
	
func _process(delta):
	if spore_active == true:
		attack_hitbox.monitorable = true
	else:
		attack_hitbox.monitorable = false
	
func _on_plant_frame_changed():
	if plant_player.animation == "spores" and plant_player.frame == 12:
		spore_player.visible = true
		spore_player.play("spores")

func _on_plant_animation_looped():
	if plant_player.animation == "idle":
		idle_loops += 1
		
		if idle_loops >= 5:
			idle_loops = 0
			plant_player.play("spores")
			spore_active = true

func _on_plant_animation_finished():
	if plant_player.animation == "spores":
		plant_player.play("idle")

func _on_spores_animation_finished():
	if spore_player.animation == "spores":
		spore_player.visible = false
		spore_active = false
		
func _on_hit_received(attack_data, source_position: Vector2):
	last_hit_source_pos = source_position
	health_component.damage(attack_data.damage)
	
func _on_died():
	var hit_position = global_position
	call_deferred("spawn_blood", hit_position, last_hit_source_pos)
	#spawn_blood(hit_position, last_hit_source_pos)
	
	Events.entity_died.emit(self)
	queue_free()

func apply_enemy_data():
	health_component.initialize(enemy_data.max_health, enemy_data.max_health)
	
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
