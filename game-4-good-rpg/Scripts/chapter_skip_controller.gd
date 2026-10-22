extends Node

const MENU_SCENE := "res://Scenes/Menu/menu.tscn"
const CHAPTER_0_SCENES := [
	"res://Scenes/start.tscn",
	"res://Scenes/game.tscn",
]
const CHAPTER_1_SCENE := "res://Chapter 1/Clear Stream Valley.tscn"
const CHAPTER_2_SCENE := "res://Scenes/chapter_2.tscn"
const CHAPTER_3_SCENE := "res://Scenes/chapter_3.tscn"

var _is_skipping := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_install_web_shortcut_guard()


func _input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	var is_y_key := key_event.keycode == KEY_Y or key_event.physical_keycode == KEY_Y
	if not key_event.meta_pressed or not is_y_key:
		return
	if key_event.alt_pressed or key_event.ctrl_pressed or key_event.shift_pressed:
		return
	get_viewport().set_input_as_handled()
	skip_current_chapter()


func skip_current_chapter() -> void:
	if _is_skipping:
		return
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path == MENU_SCENE:
		return

	var chapter_id := _current_chapter_id(scene.scene_file_path)
	_is_skipping = true
	get_tree().paused = false
	QuestState.complete_chapter_for_skip(chapter_id)

	if chapter_id == 0:
		await _change_scene(CHAPTER_1_SCENE)
	elif chapter_id == 1:
		await _change_scene(CHAPTER_2_SCENE)
	elif chapter_id == 2:
		await _change_scene(CHAPTER_3_SCENE)
	else:
		SaveManager.save_game()
		get_tree().change_scene_to_file(MENU_SCENE)

	if chapter_id < 3:
		SaveManager.save_game()
	_is_skipping = false


func _current_chapter_id(scene_path: String) -> int:
	if scene_path in CHAPTER_0_SCENES:
		return 0
	if scene_path == CHAPTER_1_SCENE:
		return 1
	if scene_path == CHAPTER_2_SCENE:
		return 2
	if scene_path == CHAPTER_3_SCENE:
		return 3

	# Puzzle and helper scenes do not carry their chapter number. Infer it from
	# the highest chapter the player has unlocked so the shortcut still works.
	if QuestState.chapter2_summary_shown:
		return 3
	if QuestState.chapter1_summary_shown:
		return 2
	if QuestState.is_chapter0_complete():
		return 1
	return 0


func _change_scene(scene_path: String) -> void:
	if FadeTransition != null and FadeTransition.has_method("change_scene"):
		await FadeTransition.change_scene(scene_path)
	else:
		get_tree().change_scene_to_file(scene_path)
		await get_tree().process_frame


func _install_web_shortcut_guard() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
		(() => {
			if (window.__game4goodCommandYGuard) return;
			window.__game4goodCommandYGuard = true;
			window.addEventListener('keydown', (event) => {
				if (event.metaKey && !event.altKey && !event.ctrlKey && !event.shiftKey && event.key.toLowerCase() === 'y') {
					event.preventDefault();
				}
			}, { capture: true });
		})();
	""")
