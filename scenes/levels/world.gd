extends Node2D

@export var player := CharacterBody2D

@onready var tilemap := $Terrain/DisappearingFG3
@onready var tilemap_material: ShaderMaterial = tilemap.material as ShaderMaterial

var reveal_active: bool = false

var current_radius = 0.0
var target_radius = 120.0  # or whatever fits your scene

func _process(delta):
	if not reveal_active:
		return
	if reveal_active:
		current_radius = lerp(current_radius, target_radius, 5 * delta)
		tilemap_material.set_shader_parameter("radius", current_radius)
		var screen_pos = get_viewport().get_canvas_transform() * player.global_position
		tilemap_material.set_shader_parameter("player_pos", screen_pos)
	
func _on_reveal_area_secret_room_1_body_entered(body):
	if body.is_in_group("player"):
		reveal_active = true

func _on_reveal_area_secret_room_1_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		reveal_active = false
		tilemap_material.set_shader_parameter("player_pos", Vector2(-1000, -1000))
		current_radius = 0.0
		tilemap_material.set_shader_parameter("radius", current_radius)
