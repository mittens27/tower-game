extends Node2D

var base_energy := 5.48
var energy_variation := 0.4

var base_scale := Vector2.ONE
var scale_variation := 0.04

var flicker_timer := 0.0
var flicker_speed := 0.1 #seconds

func _process(delta):
	for light in get_children():
		if light is PointLight2D:
			flicker_timer -= delta
			if flicker_timer <= 0:
				flicker_timer = flicker_speed
				light.energy = base_energy + randf_range(-energy_variation, energy_variation)
				light.scale = base_scale + Vector2(randf_range(-scale_variation, scale_variation), randf_range(-scale_variation, scale_variation))
