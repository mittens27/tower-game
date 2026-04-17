extends Node2D

@onready var sprite := $AnimationPlayer
@onready var collision := $StaticBody2D

@export var switch_node: Node2D

var door_open = false

func _ready():
	if switch_node:
		switch_node.connect("activated", _on_switch_activated)

func _on_switch_activated(switch):
	if door_open:
		return
	door_open = true
	sprite.play("open")

func _on_animation_player_animation_finished(anim_name: StringName):
	if anim_name == "open":
		Events.log_door_opened.emit(self)
