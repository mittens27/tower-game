extends ColorRect

func reveal():
	print("Before tween alpha:", modulate.a)
	var fade_time := 0.5
	var target_color = modulate
	target_color.a = 0.0
	
	var tween = create_tween()

	tween.tween_property(self, "modulate", target_color, fade_time)
