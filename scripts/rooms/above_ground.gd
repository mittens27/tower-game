extends TileMapLayer

@export var switch_node := Node2D
@export var fade_time := 0.5

func _ready():
	if switch_node:
		switch_node.activated.connect(_on_switch_activated)
	
	visible = true
	collision_enabled = true

func _on_switch_activated(switch):
	reveal()

func reveal():
	collision_enabled = false

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
