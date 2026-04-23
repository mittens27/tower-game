extends Area2D

#signal hit(target, attack_data)

@export var attack_data: AttackData

var damage: int

var already_hit := []

#@onready var attack := $Attack

func get_damage():
	return attack_data.damage
	
func start_attack():
	already_hit.clear()
	monitorable = true
	
	await get_tree().process_frame
	
	for area in get_overlapping_areas():
		try_hit(area)

func end_attack():
	monitorable = false
	already_hit.clear()
	
func try_hit(area):
	if area in already_hit:
		return
	
	if not area.has_method("receive_hit"):
		return
		
	already_hit.append(area)
	area.receive_hit(attack_data, global_position)
	
#func _ready():
	#area_entered.connect(_on_area_entered)
	#
#func _on_area_entered(area):
		#hit.emit(area, attack_data)
		#print("EMITTING SIGNAL")
		#Events.attack_landed.emit(
			#get_parent(),
			#area.get_parent(),
			#attack_data
		#)
