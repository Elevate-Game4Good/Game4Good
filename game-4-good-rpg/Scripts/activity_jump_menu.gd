extends CanvasLayer

const CHAPTER_1_SCENE := "res://Chapter 1/Clear Stream Valley.tscn"
const BRIDGE_PUZZLE_SCENE := "res://Scenes/PuzzlePrototype/bridge_repair_puzzle.tscn"
const CASTLE_PUZZLE_SCENE := "res://Scenes/PuzzlePrototype/slide_puzzle_main.tscn"
const SPRINKLER_SCENE := preload("res://Scenes/ui/SprinklerInstallationMiniGame.tscn")
const WATER_SORT_SCENE := preload("res://Scenes/ui/ValleyWaterSortMiniGame.tscn")
const GARBAGE_SORTING_SCENE := preload("res://Scenes/ui/GarbageSortingUI.tscn")
const SIGN_ASSEMBLY_SCENE := preload("res://Scenes/ui/SignAssemblyPuzzleUI.tscn")
const TIDE_OBSERVER_SCENE := preload("res://Scenes/ui/TideEcologyObserverMiniGame.tscn")
const DIALOGUE := preload("res://dialogue.dialogue")
const BRIDGE_RETURN_SCENE_META := "bridge_puzzle_return_scene"
const CASTLE_RETURN_SCENE_META := "castle_puzzle_return_scene"

const ACTIVITIES: Array[Dictionary] = [
	{"id": "bridge", "label": "Bridge Repair Puzzle"},
	{"id": "castle", "label": "Castle Slide Puzzle"},
	{"id": "sprinkler", "label": "Sprinkler Installation"},
	{"id": "water_sort", "label": "Valley Water Sort"},
	{"id": "beach_sort", "label": "Beach Cleanup Sorting"},
	{"id": "sign_assembly", "label": "Coastal Sign Assembly"},
	{"id": "tide", "label": "Tide Ecology Observer"},
	{"id": "stone_egg", "label": "Easter Egg: Stream Stone"},
	{"id": "sign_egg", "label": "Easter Egg: Canal Sign"},
	{"id": "boat_egg", "label": "Easter Egg: Fishing Boat"},
	{"id": "rock_sign_egg", "label": "Easter Egg: Rockside Sign"},
]

var _panel_root: Control
var _is_open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 240
	_build_menu()
	_install_web_shortcut_guard()


func _input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	var is_u_key := key_event.keycode == KEY_U or key_event.physical_keycode == KEY_U
	if key_event.meta_pressed and is_u_key and not key_event.alt_pressed and not key_event.ctrl_pressed and not key_event.shift_pressed:
		get_viewport().set_input_as_handled()
		toggle_menu()
		return
	if _is_open and key_event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close_menu()


func toggle_menu() -> void:
	if _is_open:
		close_menu()
	else:
		open_menu()


func open_menu() -> void:
	_is_open = true
	_panel_root.visible = true
	get_tree().paused = true


func close_menu() -> void:
	_is_open = false
	_panel_root.visible = false
	get_tree().paused = false


func launch_activity(activity_id: String) -> void:
	close_menu()
	_cleanup_previous_debug_activity()
	match activity_id:
		"bridge":
			get_tree().set_meta(BRIDGE_RETURN_SCENE_META, CHAPTER_1_SCENE)
			get_tree().change_scene_to_file(BRIDGE_PUZZLE_SCENE)
		"castle":
			get_tree().set_meta(CASTLE_RETURN_SCENE_META, CHAPTER_1_SCENE)
			get_tree().change_scene_to_file(CASTLE_PUZZLE_SCENE)
		"sprinkler":
			_add_activity_overlay(SPRINKLER_SCENE.instantiate())
		"water_sort":
			_launch_with_restored_flag(WATER_SORT_SCENE.instantiate(), "flag_minigame_watersort")
		"beach_sort":
			_launch_beach_sorting()
		"sign_assembly":
			_add_activity_overlay(SIGN_ASSEMBLY_SCENE.instantiate())
		"tide":
			_launch_with_restored_flag(TIDE_OBSERVER_SCENE.instantiate(), "chapter2_tide_observation_done")
		"stone_egg":
			DialogueManager.show_example_dialogue_balloon(DIALOGUE, "stone_start")
		"sign_egg":
			DialogueManager.show_example_dialogue_balloon(DIALOGUE, "sign_start")
		"boat_egg":
			DialogueManager.show_example_dialogue_balloon(DIALOGUE, "fishing_boat_start")
		"rock_sign_egg":
			DialogueManager.show_example_dialogue_balloon(DIALOGUE, "rockside_sign_start")


func _add_activity_overlay(activity: Node) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	activity.add_to_group("command_u_debug_activity")
	scene.add_child(activity)


func _launch_with_restored_flag(activity: Node, property_name: StringName) -> void:
	var previous_value: Variant = QuestState.get(property_name)
	activity.tree_exited.connect(func() -> void: QuestState.set(property_name, previous_value), CONNECT_ONE_SHOT)
	_add_activity_overlay(activity)


func _launch_beach_sorting() -> void:
	var previous_ids: Array[String] = QuestState.chapter2_beach_collected_ids.duplicate()
	var debug_ids: Array[String] = []
	for item in BeachCleanupConfig.TRASH_ITEMS:
		debug_ids.append(String(item.get("item_id", "")))
	QuestState.chapter2_beach_collected_ids = debug_ids
	var activity := GARBAGE_SORTING_SCENE.instantiate()
	activity.tree_exited.connect(
		func() -> void: QuestState.chapter2_beach_collected_ids = previous_ids,
		CONNECT_ONE_SHOT
	)
	_add_activity_overlay(activity)


func _cleanup_previous_debug_activity() -> void:
	for activity in get_tree().get_nodes_in_group("command_u_debug_activity"):
		if is_instance_valid(activity):
			activity.queue_free()


func _build_menu() -> void:
	_panel_root = Control.new()
	_panel_root.name = "ActivityJumpMenu"
	_panel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel_root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_panel_root)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.02, 0.04, 0.05, 0.88)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel_root.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 620)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var title := Label.new()
	title.text = "Mini-games & Easter Eggs"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	content.add_child(title)

	var help := Label.new()
	help.text = "Choose a destination. Press Command + U or Esc to close."
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 16)
	content.add_child(help)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	for activity in ACTIVITIES:
		var button := Button.new()
		button.text = String(activity.label)
		button.custom_minimum_size = Vector2(310, 62)
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(launch_activity.bind(String(activity.id)))
		grid.add_child(button)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(0, 54)
	close_button.pressed.connect(close_menu)
	content.add_child(close_button)

	_panel_root.visible = false


func _install_web_shortcut_guard() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
		(() => {
			if (window.__game4goodCommandUGuard) return;
			window.__game4goodCommandUGuard = true;
			window.addEventListener('keydown', (event) => {
				if (event.metaKey && !event.altKey && !event.ctrlKey && !event.shiftKey && event.key.toLowerCase() === 'u') {
					event.preventDefault();
				}
			}, { capture: true });
		})();
	""")
