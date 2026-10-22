extends Node
## Chapter 1 progression: each quest’s main dialogue unlocks only after the previous quest’s conversations are finished.

const CHAPTER_1_SCENE := "res://Chapter 1/Clear Stream Valley.tscn"
const CHAPTER_2_SCENE := "res://Scenes/chapter_2.tscn"
const CHAPTER1_SPRINKLER_MINIGAME_SCENE := preload("res://Scenes/ui/SprinklerInstallationMiniGame.tscn")

var quest1_maggie_done: bool = false
var quest1_kai_done: bool = false
var quest1_jessica_done: bool = false

var quest2_arden_done: bool = false
var quest2_steven_done: bool = false
var quest2_aurora_done: bool = false
## Set when the player confirms the Quest 2 completion panel (Chapter 1).
var chapter1_quest2_completion_acknowledged: bool = false

var quest3_complete: bool = false
var quest4_complete: bool = false
var quest5_complete: bool = false
var chapter1_sprinkler_minigame_completed: bool = false
var _chapter1_sprinkler_minigame_ui: CanvasLayer = null

# ---- Qingxi Valley 2.0: easter-egg flags & medal state ----
var flag_stone_chat: bool = false
var flag_sign_chat: bool = false
var flag_minigame_watersort: bool = false
var chapter1_medal_shown: bool = false
var chapter1_medal_arden_done: bool = false

# ---- Qingxi Valley 3.0: medal fragments (collect all 3 to unlock the fully-explored medal) ----
var fragment_stone: bool = false
var fragment_sign: bool = false
var fragment_minigame: bool = false
var _pending_fragment_tip: String = ""

var chapter2_quest1_matt_done: bool = false
var chapter2_quest1_kai_done: bool = false
var chapter2_quest1_jessica_done: bool = false
var chapter2_beach_cleanup_started: bool = false
var chapter2_beach_cleanup_done: bool = false
var chapter2_beach_collected_ids: Array[String] = []
var chapter2_quest2_residents_done: bool = false
var chapter2_quest3_matt_done: bool = false
var chapter2_quest3_kai_done: bool = false
var chapter2_quest3_warehouse_done: bool = false
var chapter2_quest4_meeting_done: bool = false
var chapter2_sign_assembled: bool = false
var chapter2_quest5_cleanup_done: bool = false
var chapter2_fishing_boat_inspected: bool = false
var chapter2_rockside_sign_read: bool = false
var chapter2_tide_observation_done: bool = false
var chapter2_description_shown: bool = false
var chapter2_summary_shown: bool = false

var chapter3_quest1_advaita_done: bool = false
var chapter3_quest1_sarina_done: bool = false
var chapter3_quest1_aurora_done: bool = false
var chapter3_quest2_advaita_done: bool = false
var chapter3_quest2_sarina_done: bool = false
var chapter3_quest2_aurora_done: bool = false
var chapter3_quest2_home_visits_done: bool = false
var chapter3_quest3_festival_setup_done: bool = false
var chapter3_quest4_town_dialogue_done: bool = false
var chapter3_quest5_celebration_done: bool = false
var chapter3_description_shown: bool = false
var chapter3_summary_shown: bool = false

var chapter0_traveler_done: bool = false
var chapter0_family_done: bool = false
var chapter0_friend_done: bool = false
var chapter1_description_shown: bool = false
var chapter1_castle_gate_shown: bool = false
var chapter1_castle_puzzle_complete: bool = false
var chapter1_summary_shown: bool = false
var interaction_lock_count: int = 0



#bridge repair - Ayden Tran
var bridge_repaired := false
const BRIDGE_RETURN_POSITION_META := "bridge_puzzle_return_position"

## Chapter 1: broken bridge on the path toward Quest 3 (not part of Quest 2).
## Active only after Quest 2 is done, until the plank puzzle is finished.
func needs_chapter1_bridge_repair() -> bool:
	return is_quest2_complete() and not bridge_repaired


## Player may open the bridge plank puzzle (Quest 2 finished, bridge not yet repaired).
func can_repair_chapter1_bridge() -> bool:
	return needs_chapter1_bridge_repair()


func is_quest1_complete() -> bool:
	return quest1_maggie_done and quest1_kai_done and quest1_jessica_done


func is_quest2_complete() -> bool:
	return quest2_arden_done and quest2_steven_done and quest2_aurora_done


func is_chapter1_complete() -> bool:
	return is_quest1_complete() and is_quest2_complete() and quest3_complete and quest4_complete and quest5_complete


func is_chapter1_castle_puzzle_complete() -> bool:
	if chapter1_castle_puzzle_complete:
		return true
	var achievement_manager := get_node_or_null("/root/AchievementManager")
	if achievement_manager != null and achievement_manager.has_badge("puzzle_solver"):
		chapter1_castle_puzzle_complete = true
	return chapter1_castle_puzzle_complete


func mark_chapter1_castle_puzzle_complete() -> void:
	chapter1_castle_puzzle_complete = true
	var achievement_manager := get_node_or_null("/root/AchievementManager")
	if achievement_manager != null:
		achievement_manager.unlock_badge("puzzle_solver")


func is_chapter2_quest1_complete() -> bool:
	return chapter2_beach_cleanup_done


func is_chapter2_quest2_complete() -> bool:
	return chapter2_quest1_matt_done


func is_chapter2_quest3_complete() -> bool:
	return chapter2_quest3_matt_done and chapter2_quest3_kai_done


func is_chapter2_complete() -> bool:
	return is_chapter2_quest1_complete() and is_chapter2_quest2_complete() and chapter2_quest3_warehouse_done and chapter2_quest4_meeting_done and chapter2_quest5_cleanup_done


func mark_chapter2_fishing_boat_inspected() -> void:
	chapter2_fishing_boat_inspected = true


func mark_chapter2_rockside_sign_read() -> void:
	chapter2_rockside_sign_read = true


func mark_chapter2_tide_observation_done() -> void:
	chapter2_tide_observation_done = true


func is_chapter3_quest1_complete() -> bool:
	return chapter3_quest1_advaita_done and chapter3_quest1_sarina_done and chapter3_quest1_aurora_done


func is_chapter3_quest2_complete() -> bool:
	return chapter3_quest2_advaita_done and chapter3_quest2_sarina_done and chapter3_quest2_aurora_done


func is_chapter3_complete() -> bool:
	return is_chapter3_quest1_complete() and chapter3_quest2_home_visits_done and chapter3_quest3_festival_setup_done and chapter3_quest4_town_dialogue_done and chapter3_quest5_celebration_done


## Completes the active chapter without opening its normal completion panels.
## Used by the Command+Y accessibility/testing shortcut before changing scenes.
func complete_chapter_for_skip(chapter_id: int) -> void:
	match chapter_id:
		0:
			chapter0_traveler_done = true
			chapter0_family_done = true
			chapter0_friend_done = true
		1:
			quest1_maggie_done = true
			quest1_kai_done = true
			quest1_jessica_done = true
			quest2_arden_done = true
			quest2_steven_done = true
			quest2_aurora_done = true
			chapter1_quest2_completion_acknowledged = true
			quest3_complete = true
			quest4_complete = true
			quest5_complete = true
			chapter1_sprinkler_minigame_completed = true
			bridge_repaired = true
			chapter1_description_shown = true
			chapter1_castle_gate_shown = true
			chapter1_summary_shown = true
			mark_chapter1_castle_puzzle_complete()
		2:
			chapter2_beach_cleanup_started = true
			chapter2_beach_cleanup_done = true
			chapter2_quest1_matt_done = true
			chapter2_quest1_kai_done = true
			chapter2_quest1_jessica_done = true
			chapter2_quest2_residents_done = true
			chapter2_quest3_matt_done = true
			chapter2_quest3_kai_done = true
			chapter2_quest3_warehouse_done = true
			chapter2_quest4_meeting_done = true
			chapter2_sign_assembled = true
			chapter2_quest5_cleanup_done = true
			chapter2_description_shown = true
			chapter2_summary_shown = true
		3:
			chapter3_quest1_advaita_done = true
			chapter3_quest1_sarina_done = true
			chapter3_quest1_aurora_done = true
			chapter3_quest2_advaita_done = true
			chapter3_quest2_sarina_done = true
			chapter3_quest2_aurora_done = true
			chapter3_quest2_home_visits_done = true
			chapter3_quest3_festival_setup_done = true
			chapter3_quest4_town_dialogue_done = true
			chapter3_quest5_celebration_done = true
			chapter3_description_shown = true
			chapter3_summary_shown = true


func is_minimap_objective_active(objective_key: StringName) -> bool:
	match objective_key:
		&"ch0_traveller":
			return not chapter0_traveler_done
		&"ch0_family":
			return chapter0_traveler_done and not chapter0_family_done
		&"ch0_friend":
			return chapter0_traveler_done and not chapter0_friend_done
		&"ch1_q1_maggie":
			return not is_quest1_complete() and not quest1_maggie_done
		&"ch1_q1_kai":
			return not is_quest1_complete() and not quest1_kai_done
		&"ch1_q1_jessica":
			return not is_quest1_complete() and not quest1_jessica_done
		&"ch1_q2_arden":
			return is_quest1_complete() and not is_quest2_complete() and not quest2_arden_done
		&"ch1_q2_steven":
			return is_quest1_complete() and not is_quest2_complete() and not quest2_steven_done
		&"ch1_q2_aurora":
			return is_quest1_complete() and not is_quest2_complete() and not quest2_aurora_done
		&"ch1_bridge":
			return needs_chapter1_bridge_repair()
		&"ch1_q3_villagers":
			return is_quest2_complete() and bridge_repaired and not quest3_complete
		&"ch1_q4_council":
			return quest3_complete and not quest4_complete
		&"ch1_q5_villagers":
			return quest4_complete and not quest5_complete
		&"ch1_castle":
			return is_chapter1_complete() and not is_chapter1_castle_puzzle_complete()
		&"ch2_q1_jessica":
			return not chapter2_beach_cleanup_started and not chapter2_beach_cleanup_done
		&"ch2_q1_trash":
			return chapter2_beach_cleanup_started and not chapter2_beach_cleanup_done
		&"ch2_q2_matt":
			return is_chapter2_quest1_complete() and not is_chapter2_quest2_complete()
		&"ch2_q3_matt":
			return is_chapter2_quest2_complete() and not chapter2_quest3_warehouse_done and not chapter2_quest3_matt_done
		&"ch2_q3_kai":
			return is_chapter2_quest2_complete() and not chapter2_quest3_warehouse_done and not chapter2_quest3_kai_done
		&"ch2_q4_group":
			return chapter2_quest3_warehouse_done and not chapter2_quest4_meeting_done
		&"ch2_q5_sign":
			return chapter2_quest4_meeting_done and not chapter2_sign_assembled and not chapter2_quest5_cleanup_done
		&"ch3_q1_advaita":
			return not is_chapter3_quest1_complete() and not chapter3_quest1_advaita_done
		&"ch3_q1_sarina":
			return not is_chapter3_quest1_complete() and not chapter3_quest1_sarina_done
		&"ch3_q1_aurora":
			return not is_chapter3_quest1_complete() and not chapter3_quest1_aurora_done
		&"ch3_q2_advaita":
			return is_chapter3_quest1_complete() and not chapter3_quest2_home_visits_done and not chapter3_quest2_advaita_done
		&"ch3_q2_sarina":
			return is_chapter3_quest1_complete() and not chapter3_quest2_home_visits_done and not chapter3_quest2_sarina_done
		&"ch3_q2_aurora":
			return is_chapter3_quest1_complete() and not chapter3_quest2_home_visits_done and not chapter3_quest2_aurora_done
		&"ch3_q3_council":
			return chapter3_quest2_home_visits_done and not chapter3_quest3_festival_setup_done
		&"ch3_q4_council":
			return chapter3_quest3_festival_setup_done and not chapter3_quest4_town_dialogue_done
		&"ch3_q5_celebration":
			return chapter3_quest4_town_dialogue_done and not chapter3_quest5_celebration_done
		_:
			return false


func mark_quest1_maggie_done() -> void:
	quest1_maggie_done = true


func mark_quest1_kai_done() -> void:
	quest1_kai_done = true


func mark_quest1_jessica_done() -> void:
	quest1_jessica_done = true


func mark_quest2_arden_done() -> void:
	quest2_arden_done = true
	_notify_chapter1_quest2_complete()


func mark_quest2_steven_done() -> void:
	quest2_steven_done = true
	_notify_chapter1_quest2_complete()


func mark_quest2_aurora_done() -> void:
	quest2_aurora_done = true
	_notify_chapter1_quest2_complete()


func _notify_chapter1_quest2_complete() -> void:
	if not is_quest2_complete() or chapter1_quest2_completion_acknowledged:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for node in tree.get_nodes_in_group("story_guide_panel"):
		if node.has_method("_queue_chapter1_quest2_completion_panel"):
			node.call_deferred("_queue_chapter1_quest2_completion_panel")
			return


func acknowledge_chapter1_quest2_completion() -> void:
	chapter1_quest2_completion_acknowledged = true


func mark_quest3_complete() -> void:
	quest3_complete = true


func mark_quest4_complete() -> void:
	quest4_complete = true


func mark_quest5_complete() -> void:
	if _should_open_chapter1_sprinkler_minigame():
		_open_chapter1_sprinkler_minigame()
		return
	quest5_complete = true
	_maybe_show_chapter1_medal()


func _should_open_chapter1_sprinkler_minigame() -> bool:
	if chapter1_sprinkler_minigame_completed or quest5_complete:
		return false
	if not quest4_complete:
		return false
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return false
	return tree.current_scene.scene_file_path == CHAPTER_1_SCENE


func _open_chapter1_sprinkler_minigame() -> void:
	if is_instance_valid(_chapter1_sprinkler_minigame_ui):
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	_chapter1_sprinkler_minigame_ui = CHAPTER1_SPRINKLER_MINIGAME_SCENE.instantiate()
	tree.current_scene.add_child(_chapter1_sprinkler_minigame_ui)
	_chapter1_sprinkler_minigame_ui.completed.connect(_on_chapter1_sprinkler_minigame_completed)


func _on_chapter1_sprinkler_minigame_completed() -> void:
	chapter1_sprinkler_minigame_completed = true
	quest5_complete = true
	_chapter1_sprinkler_minigame_ui = null
	_maybe_show_chapter1_medal()


## ---- Qingxi Valley 2.0 flag helpers ----

func mark_stone_chat_done() -> void:
	flag_stone_chat = true
	fragment_stone = true
	_pending_fragment_tip = "You obtained a Valley Water Guardian medal fragment. After the canal is cleaned, check the wooden sign — there might be a surprise there."
	_show_medal_badge()


func mark_sign_chat_done() -> void:
	flag_sign_chat = true
	fragment_sign = true
	_pending_fragment_tip = "You have obtained one Valley Water Guardian medal fragment. Maybe you can try the mini-game at the canal entrance, there might be a nice surprise over there."
	_show_medal_badge()


func mark_minigame_watersort_done() -> void:
	flag_minigame_watersort = true
	fragment_minigame = true
	_pending_fragment_tip = "You obtained a Valley Water Guardian medal fragment. You have collected all easter-egg fragments for this chapter. Go check your medal gallery later."
	_show_medal_badge()


## Reveal the in-game medal HUD after an easter-egg is finished.
## Pop the screen-center medal popup after an easter-egg is finished.
func _show_medal_badge() -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var popup_scene := preload("res://Scenes/ui/FragmentMedalPopup.tscn")
	var popup: CanvasLayer = popup_scene.instantiate()
	popup.tip_text = _pending_fragment_tip
	tree.current_scene.add_child(popup)


## Number of Valley Water Guardian medal fragments collected (0-3).
func get_chapter1_fragment_count() -> int:
	var count := 0
	if fragment_stone:
		count += 1
	if fragment_sign:
		count += 1
	if fragment_minigame:
		count += 1
	return count


## Qingxi Valley 3.0: the fully-explored medal appearance unlocks only when all 3 fragments are collected.
func is_chapter1_medal_advanced() -> bool:
	return fragment_stone and fragment_sign and fragment_minigame


func mark_chapter1_medal_arden_done() -> void:
	chapter1_medal_arden_done = true


## How many of the optional Qingxi Valley 2.0 exploration flags the player has earned.
func get_chapter1_exploration_flag_count() -> int:
	var count := 0
	if flag_stone_chat:
		count += 1
	if flag_sign_chat:
		count += 1
	if flag_minigame_watersort:
		count += 1
	return count




## Pop the medal window once, right after Chapter 1 main line closes.
func _maybe_show_chapter1_medal() -> void:
	if chapter1_medal_shown:
		return
	if not is_chapter1_complete():
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	if tree.current_scene.scene_file_path != CHAPTER_1_SCENE:
		return
	chapter1_medal_shown = true
	var medal_scene := preload("res://Scenes/ui/ChapterMedalPopup.tscn")
	var popup: CanvasLayer = medal_scene.instantiate()
	tree.current_scene.add_child(popup)
	popup.closed.connect(_on_chapter1_medal_closed)


func _on_chapter1_medal_closed() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var dialogue := preload("res://dialogue.dialogue")
	DialogueManager.show_example_dialogue_balloon(dialogue, "arden_medal_start")


func mark_chapter2_quest1_matt_done() -> void:
	chapter2_quest1_matt_done = true
	_notify_chapter2_cast_refresh()


func mark_chapter2_quest1_kai_done() -> void:
	chapter2_quest1_kai_done = true
	_update_chapter2_quest1_completion()


func mark_chapter2_quest1_jessica_done() -> void:
	chapter2_quest1_jessica_done = true
	_update_chapter2_quest1_completion()


func mark_chapter2_beach_cleanup_started() -> void:
	chapter2_beach_cleanup_started = true
	_notify_beach_cleanup_refresh()
	_notify_chapter2_cast_refresh()


func mark_chapter2_beach_cleanup_done() -> void:
	chapter2_beach_cleanup_done = true
	_notify_chapter2_cast_refresh()


func collect_beach_trash_item(item_id: String) -> void:
	if item_id.is_empty() or item_id in chapter2_beach_collected_ids:
		return
	chapter2_beach_collected_ids.append(item_id)


func is_beach_trash_collected(item_id: String) -> bool:
	return item_id in chapter2_beach_collected_ids


func get_beach_trash_collected_count() -> int:
	return chapter2_beach_collected_ids.size()


func get_beach_trash_collected_items() -> Array[Dictionary]:
	return BeachCleanupConfig.get_collected_items(chapter2_beach_collected_ids)


func has_collected_all_beach_trash() -> bool:
	return get_beach_trash_collected_count() >= BeachCleanupConfig.TRASH_ITEMS.size()


func mark_chapter2_quest2_residents_done() -> void:
	chapter2_quest2_residents_done = true
	_notify_chapter2_cast_refresh()


func _update_chapter2_quest1_completion() -> void:
	if is_chapter2_quest1_complete():
		_notify_chapter2_cast_refresh()


func mark_chapter2_quest3_matt_done() -> void:
	chapter2_quest3_matt_done = true
	_update_chapter2_quest3_completion()


func mark_chapter2_quest3_kai_done() -> void:
	chapter2_quest3_kai_done = true
	_update_chapter2_quest3_completion()


func mark_chapter2_quest3_warehouse_done() -> void:
	chapter2_quest3_matt_done = true
	chapter2_quest3_kai_done = true
	chapter2_quest3_warehouse_done = true


func _update_chapter2_quest3_completion() -> void:
	if is_chapter2_quest3_complete():
		chapter2_quest3_warehouse_done = true
		_notify_chapter2_cast_refresh()


func _notify_chapter2_cast_refresh() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for node in tree.get_nodes_in_group("story_guide_panel"):
		if node.has_method("_refresh_chapter2_cast_visibility"):
			node.call_deferred("_refresh_chapter2_cast_visibility")
			return


func _notify_beach_cleanup_refresh() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for node in tree.get_nodes_in_group("beach_cleanup_manager"):
		if node.has_method("refresh_trash_visibility"):
			node.call_deferred("refresh_trash_visibility")


func mark_chapter2_quest4_meeting_done() -> void:
	chapter2_quest4_meeting_done = true
	_notify_chapter2_cast_refresh()


func mark_chapter2_quest5_cleanup_done() -> void:
	if not chapter2_sign_assembled:
		return
	chapter2_quest5_cleanup_done = true
	_notify_chapter2_cast_refresh()


func mark_chapter2_sign_assembled() -> void:
	chapter2_sign_assembled = true


func mark_chapter3_quest1_advaita_done() -> void:
	chapter3_quest1_advaita_done = true


func mark_chapter3_quest1_sarina_done() -> void:
	chapter3_quest1_sarina_done = true


func mark_chapter3_quest1_aurora_done() -> void:
	chapter3_quest1_aurora_done = true


func mark_chapter3_quest2_home_visits_done() -> void:
	chapter3_quest2_home_visits_done = true


func mark_chapter3_quest2_advaita_done() -> void:
	chapter3_quest2_advaita_done = true
	_update_chapter3_quest2_completion()


func mark_chapter3_quest2_sarina_done() -> void:
	chapter3_quest2_sarina_done = true
	_update_chapter3_quest2_completion()


func mark_chapter3_quest2_aurora_done() -> void:
	chapter3_quest2_aurora_done = true
	_update_chapter3_quest2_completion()


func mark_chapter3_quest3_festival_setup_done() -> void:
	chapter3_quest3_festival_setup_done = true


func mark_chapter3_quest4_town_dialogue_done() -> void:
	chapter3_quest4_town_dialogue_done = true


func mark_chapter3_quest5_celebration_done() -> void:
	chapter3_quest5_celebration_done = true


func mark_chapter0_traveler_done() -> void:
	chapter0_traveler_done = true


func mark_chapter0_family_done() -> void:
	chapter0_family_done = true


func mark_chapter0_friend_done() -> void:
	chapter0_friend_done = true


func is_chapter0_complete() -> bool:
	return chapter0_traveler_done and chapter0_family_done and chapter0_friend_done


## True while story guide / quest description panel is open (blocks player movement).
func is_story_guide_blocking_input() -> bool:
	if is_interaction_input_locked():
		return true
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	for node in tree.get_nodes_in_group("story_guide_panel"):
		if "is_guide_open" in node and node.is_guide_open:
			return true
	return false


func push_interaction_input_lock() -> void:
	interaction_lock_count += 1


func pop_interaction_input_lock() -> void:
	interaction_lock_count = maxi(0, interaction_lock_count - 1)


func is_interaction_input_locked() -> bool:
	return interaction_lock_count > 0


func _update_chapter3_quest2_completion() -> void:
	if is_chapter3_quest2_complete():
		chapter3_quest2_home_visits_done = true
		
func to_dict() -> Dictionary:
	return {
		"chapter_0": {
			"traveler_done": chapter0_traveler_done,
			"family_done": chapter0_family_done,
			"friend_done": chapter0_friend_done,
		},

		"chapter_1": {
			"quest1_maggie_done": quest1_maggie_done,
			"quest1_kai_done": quest1_kai_done,
			"quest1_jessica_done": quest1_jessica_done,

			"quest2_arden_done": quest2_arden_done,
			"quest2_steven_done": quest2_steven_done,
			"quest2_aurora_done": quest2_aurora_done,

			"quest3_complete": quest3_complete,
			"quest4_complete": quest4_complete,
			"quest5_complete": quest5_complete,
			"quest2_completion_acknowledged": chapter1_quest2_completion_acknowledged,
			"sprinkler_minigame_completed": chapter1_sprinkler_minigame_completed,

			"bridge_repaired": bridge_repaired,
			"castle_puzzle_complete":
				chapter1_castle_puzzle_complete,
			"summary_shown": chapter1_summary_shown,
			"description_shown": chapter1_description_shown,
			"castle_gate_shown": chapter1_castle_gate_shown,
			"flag_stone_chat": flag_stone_chat,
			"flag_sign_chat": flag_sign_chat,
			"flag_minigame_watersort": flag_minigame_watersort,
			"chapter1_medal_shown": chapter1_medal_shown,
			"chapter1_medal_arden_done": chapter1_medal_arden_done,
			"fragment_stone": fragment_stone,
			"fragment_sign": fragment_sign,
			"fragment_minigame": fragment_minigame,
		},

		"chapter_2": {
			"beach_cleanup_started":
				chapter2_beach_cleanup_started,
			"beach_cleanup_done":
				chapter2_beach_cleanup_done,
			"collected_trash":
				chapter2_beach_collected_ids.duplicate(),

			"quest1_matt_done":
				chapter2_quest1_matt_done,
			"quest1_kai_done":
				chapter2_quest1_kai_done,
			"quest1_jessica_done":
				chapter2_quest1_jessica_done,
			"quest2_residents_done":
				chapter2_quest2_residents_done,
			"quest3_matt_done":
				chapter2_quest3_matt_done,
			"quest3_kai_done":
				chapter2_quest3_kai_done,
			"quest3_warehouse_done":
				chapter2_quest3_warehouse_done,
			"quest4_meeting_done":
				chapter2_quest4_meeting_done,
			"sign_assembled":
				chapter2_sign_assembled,
			"quest5_cleanup_done":
				chapter2_quest5_cleanup_done,
			"fishing_boat_inspected":
				chapter2_fishing_boat_inspected,
			"rockside_sign_read":
				chapter2_rockside_sign_read,
			"tide_observation_done":
				chapter2_tide_observation_done,
			"summary_shown":
				chapter2_summary_shown,
			"description_shown":
				chapter2_description_shown,
		},

		"chapter_3": {
			"quest1_advaita_done":
				chapter3_quest1_advaita_done,
			"quest1_sarina_done":
				chapter3_quest1_sarina_done,
			"quest1_aurora_done":
				chapter3_quest1_aurora_done,
			"quest2_home_visits_done":
				chapter3_quest2_home_visits_done,
			"quest2_advaita_done":
				chapter3_quest2_advaita_done,
			"quest2_sarina_done":
				chapter3_quest2_sarina_done,
			"quest2_aurora_done":
				chapter3_quest2_aurora_done,
			"quest3_festival_setup_done":
				chapter3_quest3_festival_setup_done,
			"quest4_town_dialogue_done":
				chapter3_quest4_town_dialogue_done,
			"quest5_celebration_done":
				chapter3_quest5_celebration_done,
			"summary_shown":
				chapter3_summary_shown,
			"description_shown":
				chapter3_description_shown,
		},
	}
func load_from_dict(data: Dictionary) -> void:
	var chapter_0: Dictionary = data.get(
		"chapter_0",
		{}
	)
	var chapter_1: Dictionary = data.get(
		"chapter_1",
		{}
	)
	var chapter_2: Dictionary = data.get(
		"chapter_2",
		{}
	)
	var chapter_3: Dictionary = data.get(
		"chapter_3",
		{}
	)

	# Chapter 0
	chapter0_traveler_done = bool(
		chapter_0.get(
			"traveler_done",
			false
		)
	)
	chapter0_family_done = bool(
		chapter_0.get(
			"family_done",
			false
		)
	)
	chapter0_friend_done = bool(
		chapter_0.get(
			"friend_done",
			false
		)
	)

	# Chapter 1
	quest1_maggie_done = bool(
		chapter_1.get(
			"quest1_maggie_done",
			false
		)
	)
	quest1_kai_done = bool(
		chapter_1.get(
			"quest1_kai_done",
			false
		)
	)
	quest1_jessica_done = bool(
		chapter_1.get(
			"quest1_jessica_done",
			false
		)
	)

	quest2_arden_done = bool(
		chapter_1.get(
			"quest2_arden_done",
			false
		)
	)
	quest2_steven_done = bool(
		chapter_1.get(
			"quest2_steven_done",
			false
		)
	)
	quest2_aurora_done = bool(
		chapter_1.get(
			"quest2_aurora_done",
			false
		)
	)

	quest3_complete = bool(
		chapter_1.get(
			"quest3_complete",
			false
		)
	)
	quest4_complete = bool(
		chapter_1.get(
			"quest4_complete",
			false
		)
	)
	quest5_complete = bool(
		chapter_1.get(
			"quest5_complete",
			false
		)
	)

	bridge_repaired = bool(
		chapter_1.get(
			"bridge_repaired",
			false
		)
	)
	chapter1_castle_puzzle_complete = bool(
		chapter_1.get(
			"castle_puzzle_complete",
			false
		)
	)
	chapter1_summary_shown = bool(
		chapter_1.get(
			"summary_shown",
			false
		)
	)

	chapter1_description_shown = bool(
		chapter_1.get(
			"description_shown",
			false
		)
	)
	chapter1_castle_gate_shown = bool(
		chapter_1.get(
			"castle_gate_shown",
			false
		)
	)

	chapter1_quest2_completion_acknowledged = bool(
		chapter_1.get(
			"quest2_completion_acknowledged",
			false
		)
	)
	chapter1_sprinkler_minigame_completed = bool(
		chapter_1.get(
			"sprinkler_minigame_completed",
			false
		)
	)
	flag_stone_chat = bool(
		chapter_1.get(
			"flag_stone_chat",
			false
		)
	)
	flag_sign_chat = bool(
		chapter_1.get(
			"flag_sign_chat",
			false
		)
	)
	flag_minigame_watersort = bool(
		chapter_1.get(
			"flag_minigame_watersort",
			false
		)
	)
	chapter1_medal_shown = bool(
		chapter_1.get(
			"chapter1_medal_shown",
			false
		)
	)
	chapter1_medal_arden_done = bool(
		chapter_1.get(
			"chapter1_medal_arden_done",
			false
		)
	)
	fragment_stone = bool(
		chapter_1.get(
			"fragment_stone",
			false
		)
	)
	fragment_sign = bool(
		chapter_1.get(
			"fragment_sign",
			false
		)
	)
	fragment_minigame = bool(
		chapter_1.get(
			"fragment_minigame",
			false
		)
	)

	# Chapter 2
	chapter2_beach_cleanup_started = bool(
		chapter_2.get(
			"beach_cleanup_started",
			false
		)
	)
	chapter2_beach_cleanup_done = bool(
		chapter_2.get(
			"beach_cleanup_done",
			false
		)
	)

	var saved_trash: Variant = chapter_2.get(
		"collected_trash",
		[]
	)

	if saved_trash is Array:
		chapter2_beach_collected_ids.clear()

		for item_id in saved_trash:
			chapter2_beach_collected_ids.append(
				str(item_id)
			)

	chapter2_quest1_matt_done = bool(
		chapter_2.get(
			"quest1_matt_done",
			false
		)
	)

	chapter2_quest1_kai_done = bool(
		chapter_2.get(
			"quest1_kai_done",
			false
		)
	)
	chapter2_quest1_jessica_done = bool(
		chapter_2.get(
			"quest1_jessica_done",
			false
		)
	)
	chapter2_quest2_residents_done = bool(
		chapter_2.get(
			"quest2_residents_done",
			false
		)
	)
	chapter2_quest3_matt_done = bool(
		chapter_2.get(
			"quest3_matt_done",
			false
		)
	)
	chapter2_quest3_kai_done = bool(
		chapter_2.get(
			"quest3_kai_done",
			false
		)
	)
	chapter2_quest3_warehouse_done = bool(
		chapter_2.get(
			"quest3_warehouse_done",
			false
		)
	)
	chapter2_quest4_meeting_done = bool(
		chapter_2.get(
			"quest4_meeting_done",
			false
		)
	)
	chapter2_sign_assembled = bool(
		chapter_2.get(
			"sign_assembled",
			false
		)
	)
	chapter2_quest5_cleanup_done = bool(
		chapter_2.get(
			"quest5_cleanup_done",
			false
		)
	)
	chapter2_fishing_boat_inspected = bool(
		chapter_2.get(
			"fishing_boat_inspected",
			false
		)
	)
	chapter2_rockside_sign_read = bool(
		chapter_2.get(
			"rockside_sign_read",
			false
		)
	)
	chapter2_tide_observation_done = bool(
		chapter_2.get(
			"tide_observation_done",
			false
		)
	)
	chapter2_summary_shown = bool(
		chapter_2.get(
			"summary_shown",
			false
		)
	)
	chapter2_description_shown = bool(
		chapter_2.get(
			"description_shown",
			false
		)
	)

	# Chapter 3
	chapter3_quest1_advaita_done = bool(
		chapter_3.get(
			"quest1_advaita_done",
			false
		)
	)
	chapter3_quest1_sarina_done = bool(
		chapter_3.get(
			"quest1_sarina_done",
			false
		)
	)
	chapter3_quest1_aurora_done = bool(
		chapter_3.get(
			"quest1_aurora_done",
			false
		)
	)
	chapter3_quest2_home_visits_done = bool(
		chapter_3.get(
			"quest2_home_visits_done",
			false
		)
	)

	chapter3_quest2_advaita_done = bool(
		chapter_3.get(
			"quest2_advaita_done",
			false
		)
	)
	chapter3_quest2_sarina_done = bool(
		chapter_3.get(
			"quest2_sarina_done",
			false
		)
	)
	chapter3_quest2_aurora_done = bool(
		chapter_3.get(
			"quest2_aurora_done",
			false
		)
	)
	chapter3_quest3_festival_setup_done = bool(
		chapter_3.get(
			"quest3_festival_setup_done",
			false
		)
	)
	chapter3_quest4_town_dialogue_done = bool(
		chapter_3.get(
			"quest4_town_dialogue_done",
			false
		)
	)
	chapter3_quest5_celebration_done = bool(
		chapter_3.get(
			"quest5_celebration_done",
			false
		)
	)
	chapter3_summary_shown = bool(
		chapter_3.get(
			"summary_shown",
			false
		)
	)
	chapter3_description_shown = bool(
		chapter_3.get(
			"description_shown",
			false
		)
	)
