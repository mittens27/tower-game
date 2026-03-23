extends Node2D

@export var audio_source: Node2D
@export var door: TileMapLayer
@export var enemies: Array[CharacterBody2D] = []

func _ready():
	for enemy in enemies:
		enemy.room_controller = self
	print("Scene file:", scene_file_path)

func on_enemy_died(enemy):
	enemies.erase(enemy)
	
	if enemies.is_empty():
		unlock_door()

func unlock_door():
	print("All enemies killed. Door unlocked.")
	door.open()
	if audio_source:
		Events.log_door_opened.emit(audio_source)
	else:
		print("No audio source assigned!")
