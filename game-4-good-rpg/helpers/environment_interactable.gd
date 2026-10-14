extends Area2D
## Qingxi Valley 2.0: scene-object easter-egg interactable.
## Controls visibility by quest state and opens dialogue or the water-sort mini-game.

const DIALOGUE := preload("res://dialogue.dialogue")
const WATER_SORT_SCENE := preload("res://Scenes/ui/ValleyWaterSortMiniGame.tscn")
const TIDE_OBSERVER_SCENE := preload("res://Scenes/ui/TideEcologyObserverMiniGame.tscn")

enum Condition {
	ALWAYS,
	AFTER_QUEST5,
	AFTER_QUEST5_NO_REPEAT,
	AFTER_CHAPTER2_BEACH_CLEANUP,
	AFTER_CHAPTER2_QUEST4,
	AFTER_CHAPTER2_QUEST4_NO_REPEAT,
}

@export var dialogue_title := ""
@export var condition := Condition.ALWAYS
@export var open_minigame := false
@export var minigame_kind := "watersort"

@onready var talk_hint: Control = $TalkHintLayer/TalkHintPanel
@onready var talk_hint_label: Label = $TalkHintLayer/TalkHintPanel/TalkHintLabel

var player_near := false
var _available := false


func _ready() -> void:
	collision_mask = 1
	talk_hint.visible = false
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_sync_state()


func _process(_delta: float) -> void:
	_sync_state()
	if player_near:
		_update_hint()


func _is_available() -> bool:
	match condition:
		Condition.ALWAYS:
			return true
		Condition.AFTER_QUEST5:
			return QuestState.quest5_complete
		Condition.AFTER_QUEST5_NO_REPEAT:
			return QuestState.quest5_complete and not QuestState.flag_minigame_watersort
		Condition.AFTER_CHAPTER2_BEACH_CLEANUP:
			return QuestState.chapter2_beach_cleanup_done
		Condition.AFTER_CHAPTER2_QUEST4:
			return QuestState.chapter2_quest4_meeting_done
		Condition.AFTER_CHAPTER2_QUEST4_NO_REPEAT:
			return QuestState.chapter2_quest4_meeting_done and not QuestState.chapter2_tide_observation_done
	return false


func _sync_state() -> void:
	var available := _is_available()
	if available == _available:
		return
	_available = available
	visible = available
	if available:
		collision_layer = 16
		monitoring = true
		monitorable = true
	else:
		collision_layer = 0
		monitoring = false
		monitorable = false
		player_near = false
		talk_hint.visible = false


func _update_hint() -> void:
	if not player_near or not _available:
		talk_hint.visible = false
		return
	talk_hint.visible = true
	if open_minigame:
		if minigame_kind == "tide":
			talk_hint_label.text = "Press Space to observe the tide"
		else:
			talk_hint_label.text = "Press Space to play Valley Water Sort"
	else:
		talk_hint_label.text = "Press Space to inspect"


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_interaction_area"):
		player_near = true
		_update_hint()


func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("player_interaction_area"):
		player_near = false
		talk_hint.visible = false


func action() -> void:
	if not _available or not player_near:
		return
	if open_minigame:
		_open_minigame()
	elif not dialogue_title.is_empty():
		DialogueManager.show_example_dialogue_balloon(DIALOGUE, dialogue_title)


func _open_minigame() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var minigame: CanvasLayer
	if minigame_kind == "tide":
		minigame = TIDE_OBSERVER_SCENE.instantiate()
	else:
		minigame = WATER_SORT_SCENE.instantiate()
	scene.add_child(minigame)
	minigame.completed.connect(_on_minigame_completed)


func _on_minigame_completed() -> void:
	if minigame_kind == "tide":
		DialogueManager.show_example_dialogue_balloon(DIALOGUE, "tide_observation_complete")
	else:
		DialogueManager.show_example_dialogue_balloon(DIALOGUE, "arden_watersort_start")
