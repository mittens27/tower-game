extends Node2D

@onready var sprite1 = $bulb
@onready var sprite2 = $stalk
@onready var particles = $GPUParticles2D
@onready var spore_light_one := $PointLight2D5
@onready var spore_light_two := $PointLight2D6

var collected := false

var dim_time := 0.5

func _process(delta):
	if collected:
		sprite1.pause()
		sprite2.pause()
	else:
		sprite1.play()
		sprite2.play()

func _on_area_2d_body_entered(body):
	if body.has_method("apply_spore_buff") and not collected:
		body.apply_spore_buff(7.0, 0.4)
		dormant()
		particles.restart()
		
func dormant():
	collected = true
	dim()
	await get_tree().create_timer(14).timeout
	collected = false
	dim()

func dim():
	var tween = create_tween()
	var target_color = Color(1,1,1) if not collected else Color(0.5,0.5,0.5)
	tween.tween_property(self, "modulate", target_color, dim_time)
	
	var target_energy = 3.0 if not collected else 0.0
	tween.tween_property(spore_light_one, "energy", target_energy, dim_time)
	tween.tween_property(spore_light_two, "energy", target_energy, dim_time)
