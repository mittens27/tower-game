extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	Events.player_died.connect(_on_player_player_died)

var waiting_for_restart := false

func _on_player_player_died():
	waiting_for_restart = true

func _input(event):
	if waiting_for_restart and event.is_action_pressed("ui_accept"):
		Scenes.restart_level()
		Events.game_reset.emit()
