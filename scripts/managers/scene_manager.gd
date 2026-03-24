extends Node
class_name SceneManager

var current_scene_path : String

func _ready():
	current_scene_path = get_tree().current_scene.scene_file_path

func change_scene(scene_path: String):
	current_scene_path = scene_path
	get_tree().change_scene_to_file(scene_path)
	
func restart_level():
	if current_scene_path != "":
		change_scene(current_scene_path)
