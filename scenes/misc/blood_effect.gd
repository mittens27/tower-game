extends GPUParticles2D


func _ready():
	#restart()
	await get_tree().create_timer(lifetime).timeout
	queue_free

func set_direction(dir: Vector2):
	rotation = dir.angle()
	
func set_gradient(gradient: Gradient):
	var mat := process_material as ParticleProcessMaterial
	if mat:
		mat = mat.duplicate()
		process_material = mat
		
		var gradient_tex := GradientTexture1D.new()
		gradient_tex.gradient = gradient
		
		mat.color_ramp = gradient_tex
