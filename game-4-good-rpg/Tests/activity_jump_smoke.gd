extends SceneTree

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var menu := root.get_node_or_null("ActivityJumpMenu")
	_check(menu != null, "Command-U menu autoload exists")
	if menu != null:
		_check(menu.ACTIVITIES.size() == 11, "All mini-games and easter eggs are listed")
		var ids: Array[String] = []
		for activity in menu.ACTIVITIES:
			ids.append(String(activity.id))
		for required_id in ["bridge", "castle", "sprinkler", "water_sort", "beach_sort", "sign_assembly", "tide", "stone_egg", "sign_egg", "boat_egg", "rock_sign_egg"]:
			_check(required_id in ids, "Destination exists: %s" % required_id)
		menu.open_menu()
		_check(paused, "Opening the menu pauses the game")
		menu.close_menu()
		_check(not paused, "Closing the menu resumes the game")
	print("ACTIVITY_JUMP_CHECKS: %d / FAILURES: %d" % [checks, failures])
	quit(failures)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("ACTIVITY_JUMP_FAILED: %s" % label)
