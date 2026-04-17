extends Area2D

signal hit_received(attack_data, source_position)

@export var invulnerability_time := 0.5
var invulnerable := false

func _ready():
	area_entered.connect(_on_area_entered)
	
func _on_area_entered(area):
	if invulnerable:
		return
		
	if not "attack_data" in area:
		return
	
	hit_received.emit(area.attack_data, area.global_position)
	
	Events.player_hurt.emit(get_parent())

	Events.attack_landed.emit(
		area.get_parent(),   # attacker
		get_parent(),        # target
		area.attack_data
	)
	
	if get_parent().is_in_group("player"):
		start_invulnerability()
	
func start_invulnerability():
	invulnerable = true
	monitorable = false
	await get_tree().create_timer(invulnerability_time).timeout
	invulnerable = false
	monitorable = true
