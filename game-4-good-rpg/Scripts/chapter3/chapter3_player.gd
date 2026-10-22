extends "res://Scripts/PlayerScript.gd"
## Retain the shared movement/outfit/save behavior. Loading also restores the map.


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("load_game"):
		if not _is_input_blocked() and SaveManager.load_game():
			var saved_scene := SaveManager.get_pending_scene_path()
			if not saved_scene.is_empty() and ResourceLoader.exists(saved_scene, "PackedScene"):
				FadeTransition.change_scene(saved_scene)
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)
