extends Node2D

@export var fog_layers: Dictionary[String, Node]

func _ready():
	visible = true
	
	Events.reveal_requested.connect(_on_reveal_requested)
	
func _on_reveal_requested(reveal_id: String):
	reveal_layer(reveal_id)
	
func reveal_layer(name: String):
	if fog_layers.has(name):
		fog_layers[name].reveal()
