extends Node2D

@onready var sprite := $AnimatedSprite2D
@onready var collision := $StaticBody2D

@export var switch_node: Node2D

var door_open = false

func _ready():
	if switch_node:
		switch_node.connect("activated", _on_switch_activated)

func _process(delta):
	if door_open:
		collision.global_position.y = move_toward(collision.global_position.y, -64, 50 * delta)

func _on_switch_activated(switch):
	if door_open:
		return
	door_open = true
	sprite.play("open")
	
func _on_animated_sprite_2d_animation_finished():
	if sprite.animation == "open":
		Events.log_door_opened.emit(self)
		collision.set_deferred("collision_layer", 0)
		collision.set_deferred("collision_mask", 0)
