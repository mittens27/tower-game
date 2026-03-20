extends Node2D

@onready var effects = {
	"spores": $SporeParticles,
	"fire": $FireParticles,
	"poison": $PoisonParticles
}

var active_counts := {}

func activate(effect_name: String):
	if not effects.has(effect_name):
		return
	
	active_counts[effect_name] = active_counts.get(effect_name, 0) + 1
	
	# Only turn ON when first source appears
	if active_counts[effect_name] == 1:
		effects[effect_name].emitting = true

func deactivate(effect_name: String):
	if not active_counts.has(effect_name):
		return
		
	active_counts[effect_name] -= 1
	
	# Only turn OFF when no sources remain
	if active_counts[effect_name] <= 0:
		active_counts.erase(effect_name)
		effects[effect_name].emitting = false
