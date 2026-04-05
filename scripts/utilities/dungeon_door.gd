extends Node2D

@onready var sprite := $AnimatedSprite2D
@onready var collision := $StaticBody2D

var player_inside := false
var door_toggled := false

func _ready() -> void:
	pass

func _process(_delta):
	if player_inside and Input.is_action_just_pressed("ui_use"):
		open_door()
		
func open_door():
	if door_toggled:
		return
	door_toggled = true
	print("Door toggled!")
	sprite.play("open")
	collision.set_deferred("collision_layer", 0)
	collision.set_deferred("collision_mask", 0)
	Events.reveal_requested.emit(RevealIDs.ORCEBASEMENT)

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true

func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
