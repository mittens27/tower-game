extends TileMapLayer

@export var fade_time := 0.5

func _ready():
	collision_enabled = true

func reveal():
	collision_enabled = false
	fade_out()
	
func fade_out():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
