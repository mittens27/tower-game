extends Node2D

func _ready():
	await get_tree().process_frame
	
	for child in get_children():
		if child is Parallax2D:
			setup_parallax(child)

func setup_parallax(p: Parallax2D):
	for child in p.get_children():
		if child is Sprite2D and child.texture:
			var size = child.texture.get_size()
			p.repeat_size = Vector2(size.x, 0)
			return
