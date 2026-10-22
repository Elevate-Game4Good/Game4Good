extends SceneTree
## godot --headless --path game-4-good-rpg --script res://Tests/chapter_skip_smoke.gd

var _checks := 0
var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL: ", message)


func _run() -> void:
	var state := root.get_node("QuestState")
	var controller := root.get_node("ChapterSkipController")

	_check(controller._current_chapter_id("res://Scenes/start.tscn") == 0, "Chapter 0 scene detected")
	_check(controller._current_chapter_id(controller.CHAPTER_1_SCENE) == 1, "Chapter 1 scene detected")
	_check(controller._current_chapter_id(controller.CHAPTER_2_SCENE) == 2, "Chapter 2 scene detected")
	_check(controller._current_chapter_id(controller.CHAPTER_3_SCENE) == 3, "Chapter 3 scene detected")

	state.load_from_dict({})
	state.complete_chapter_for_skip(0)
	_check(state.is_chapter0_complete(), "Chapter 0 skip completes progress")

	state.load_from_dict({})
	state.complete_chapter_for_skip(1)
	_check(state.is_chapter1_complete(), "Chapter 1 skip completes quests")
	_check(state.bridge_repaired and state.is_chapter1_castle_puzzle_complete(), "Chapter 1 skip completes gates")

	state.load_from_dict({})
	state.complete_chapter_for_skip(2)
	_check(state.is_chapter2_complete(), "Chapter 2 skip completes quests")
	_check(state.chapter2_summary_shown, "Chapter 2 skip unlocks Chapter 3")

	state.load_from_dict({})
	state.complete_chapter_for_skip(3)
	_check(state.is_chapter3_complete(), "Chapter 3 skip completes quests")
	_check(state.chapter3_summary_shown, "Chapter 3 skip records completion")

	print("CHAPTER_SKIP_CHECKS: ", _checks, " / FAILURES: ", _failures)
	quit(0 if _failures == 0 else 1)
