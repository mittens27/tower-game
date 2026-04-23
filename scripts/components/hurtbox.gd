extends Area2D

signal hit_received(attack_data, source_position)

@export var invulnerability_time := 0.5
var invulnerable := false

func _ready():
	area_entered.connect(_on_area_entered)

func receive_hit(attack_data, source_position):
	if invulnerable:
		return
		
	hit_received.emit(attack_data, source_position)

	Events.attack_landed.emit(
		attack_data,
		get_parent(),
	)
	
	if get_parent().is_in_group("player"):
		Events.player_hurt.emit(get_parent())
		start_invulnerability()
		
func _on_area_entered(area):
	if not "attack_data" in area:
		return
		
	receive_hit(area.attack_data, area.global_position)
	print("Player hurtbox entered by:", area.name)
	
func start_invulnerability():
	invulnerable = true
	await get_tree().create_timer(invulnerability_time).timeout
	invulnerable = false
