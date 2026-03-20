extends Area2D

@export var door: TileMapLayer
@export var enemies: Array[CharacterBody2D] = []

func _ready():
	for enemy in enemies:
		enemy.room_controller = self

func on_enemy_died(enemy):
	enemies.erase(enemy)
	
	if enemies.is_empty():
		unlock_door()

func unlock_door():
	print("All enemies killed. Door unlocked.")
	door.open()
