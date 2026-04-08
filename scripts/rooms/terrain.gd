extends TileMapLayer

@export var player := CharacterBody2D
@export var reveal_collisions: Dictionary[String, TileMapLayer]

@onready var tilemap := $SecretRoom1
@onready var tilemap_material: ShaderMaterial = tilemap.material as ShaderMaterial

var reveal_active: bool = false

var fade_time := 0.5

var current_radius = 0.0
var target_radius = 120.0  # or whatever fits your scene

func _ready():
	Events.reveal_requested.connect(_on_reveal_requested)

	tilemap_material.set_shader_parameter("player_pos", Vector2(-1000, -1000))
	tilemap_material.set_shader_parameter("radius", 0.0)
	
func _process(delta):
	if not reveal_active:
		return
	if reveal_active:
		current_radius = lerp(current_radius, target_radius, 5 * delta)
		tilemap_material.set_shader_parameter("radius", current_radius)
		var screen_pos = get_viewport().get_canvas_transform() * player.global_position
		tilemap_material.set_shader_parameter("player_pos", screen_pos)
	
func _on_reveal_requested(reveal_id: String):
	reveal_layer(reveal_id)
	
func reveal_layer(name: String):
	var tween = create_tween()
	if reveal_collisions.has(name):
		tween.tween_property(reveal_collisions[name], "modulate:a", 0.0, fade_time)
		reveal_collisions[name].collision_enabled = false
	
func _on_reveal_area_secret_room_1_body_entered(body):
	if body.is_in_group("player"):
		reveal_active = true

func _on_reveal_area_secret_room_1_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		reveal_active = false
		tilemap_material.set_shader_parameter("player_pos", Vector2(-1000, -1000))
		current_radius = 0.0
		tilemap_material.set_shader_parameter("radius", current_radius)
