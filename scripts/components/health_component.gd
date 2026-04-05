extends Node

signal health_changed(current, max)
signal died

var max_health: int
var current_health: int

func damage(amount: int):
	current_health = clamp(current_health - amount, 0, max_health)

	health_changed.emit(current_health)
	
	if current_health == 0:
		died.emit()
		Events.entity_died.emit(get_parent())

func heal(amount: int):
	current_health = clamp(current_health + amount, 0, max_health)
	health_changed.emit(current_health)

func initialize(max_hp: int, current_hp: int):
	max_health = max_hp
	current_health = current_hp
	
	health_changed.emit(current_health)
