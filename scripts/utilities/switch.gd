extends Node2D

@onready var sprite := $Sprite2D

var switch_toggled := false
var player_inside := false

signal activated

func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if player_inside and Input.is_action_just_pressed("ui_use"):
		activate_switch()

func activate_switch():
	if switch_toggled:
		return
	Events.switch_toggled.emit(self)
	switch_toggled = true
	sprite.flip_v = true
	activated.emit(self)

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true

func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
