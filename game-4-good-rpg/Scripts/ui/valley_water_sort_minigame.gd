extends CanvasLayer
## Valley Water Sort mini-game (Qingxi Valley 2.0).
## Sort floating objects into "May stay in nature" / "Needs to be removed".
## Fully optional, no fail state, retries allowed. On completion emits `completed`.

signal completed

const STAY_COLOR := Color(0.35, 0.75, 0.45, 1.0)
const REMOVE_COLOR := Color(0.85, 0.45, 0.35, 1.0)
const PANEL_BG := Color(0.1, 0.12, 0.16, 0.96)

## Objects shown in the canal scene. key = id, label = display name, stays_in_nature = answer.
const OBJECTS: Array[Dictionary] = [
	{"id": "leaves", "label": "Clean fallen leaves", "stays_in_nature": true},
	{"id": "soil", "label": "Soil clumps", "stays_in_nature": false},
	{"id": "rubbish", "label": "Man-made household rubbish", "stays_in_nature": false},
	{"id": "twigs", "label": "Dry twigs", "stays_in_nature": true},
]

var _object_buttons: Dictionary = {}
var _sorted_count := 0
var _finish_pending := false

@onready var root_panel: PanelContainer = $Root/Panel
@onready var title_label: Label = $Root/Panel/Margin/MainVBox/TitleLabel
@onready var object_host: HBoxContainer = $Root/Panel/Margin/MainVBox/ObjectRow
@onready var stay_button: Button = $Root/Panel/Margin/MainVBox/ButtonRow/StayButton
@onready var remove_button: Button = $Root/Panel/Margin/MainVBox/ButtonRow/RemoveButton
@onready var feedback_label: Label = $Root/Panel/Margin/MainVBox/FeedbackLabel
@onready var close_button: Button = $Root/Panel/Margin/MainVBox/CloseRow/CloseButton

var _selected_id: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 130
	QuestState.push_interaction_input_lock()
	title_label.text = "Valley Water Sort"
	feedback_label.text = "Click an object, then choose a zone."
	close_button.visible = false
	stay_button.pressed.connect(_on_zone_pressed.bind(true))
	remove_button.pressed.connect(_on_zone_pressed.bind(false))
	close_button.pressed.connect(_on_close_pressed)
	_build_object_row()


func _exit_tree() -> void:
	QuestState.pop_interaction_input_lock()


func _build_object_row() -> void:
	for child in object_host.get_children():
		child.queue_free()
	_object_buttons.clear()
	for obj in OBJECTS:
		var btn := Button.new()
		btn.text = obj.label
		btn.custom_minimum_size = Vector2(170, 90)
		btn.add_theme_font_size_override("font_size", 18)
		btn.add_theme_color_override("font_color", Color(0.05, 0.4, 0.3))
		btn.pressed.connect(_on_object_pressed.bind(obj.id))
		object_host.add_child(btn)
		_object_buttons[obj.id] = btn


func _on_object_pressed(obj_id: String) -> void:
	if _finish_pending:
		return
	_selected_id = obj_id
	feedback_label.text = "Selected: %s — now choose a zone." % [OBJECTS[_object_index(obj_id)].label]


func _object_index(obj_id: String) -> int:
	for i in OBJECTS.size():
		if OBJECTS[i].id == obj_id:
			return i
	return 0


func _on_zone_pressed(stays_in_nature: bool) -> void:
	if _selected_id.is_empty() or _finish_pending:
		return
	var idx := _object_index(_selected_id)
	var obj: Dictionary = OBJECTS[idx]
	var correct: bool = obj.stays_in_nature == stays_in_nature
	if correct:
		feedback_label.text = "Correct! %s is fine / removed properly." % [obj.label]
		_object_buttons[_selected_id].disabled = true
		_object_buttons[_selected_id].modulate = Color(1, 1, 1, 0.4)
		_sorted_count += 1
		_selected_id = ""
		if _sorted_count >= OBJECTS.size():
			_finish_pending = true
			feedback_label.text = "All objects sorted! Well done observing what pollutes water."
			close_button.visible = true
	else:
		feedback_label.text = "Think again! %s belongs to the other zone." % [obj.label]
		_selected_id = ""


func _on_close_pressed() -> void:
	QuestState.mark_minigame_watersort_done()
	completed.emit()
	queue_free()


## ESC exits the mini-game without marking it done.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		if _finish_pending:
			return  # already finished -> use the close button instead
		queue_free()
