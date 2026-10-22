extends CanvasLayer
## Valley Water Sort mini-game (Qingxi Valley 2.0).
## Sort floating objects into "May stay in nature" / "Needs to be removed".
## Fully optional, no fail state, retries allowed. On completion emits `completed`.

signal completed

# Same look as the settings menu
const MENU_FONT := preload("res://Sprites/Font/VCR_OSD_MONO_1.001.ttf")
const PANEL_BG := Color(0.051, 0.059, 0.078, 0.784)
const BTN_NORMAL := Color(0.529, 0.639, 0.463)
const BTN_HOVER := Color(0.396, 0.494, 0.337)
const BTN_PRESSED := Color(0.212, 0.271, 0.173)
const BTN_BORDER := Color(0.8, 0.8, 0.8)
# Warm variant for the "Needs to be removed" zone
const REMOVE_NORMAL := Color(0.80, 0.52, 0.38)
const REMOVE_HOVER := Color(0.70, 0.44, 0.31)
const REMOVE_PRESSED := Color(0.45, 0.27, 0.19)
const TEXT_DARK := Color(0.05, 0.06, 0.08)

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
	_apply_menu_style()
	_build_object_row()


func _exit_tree() -> void:
	QuestState.pop_interaction_input_lock()


# ---------- styling ----------

func _make_box(bg: Color, radius: int, border_width: int, border_color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(radius)
	box.set_border_width_all(border_width)
	box.border_color = border_color
	box.content_margin_left = 10
	box.content_margin_right = 10
	return box


func _style_button(btn: Button, normal: Color, hover: Color, pressed: Color, font_size: int, border: Color = BTN_BORDER) -> void:
	btn.add_theme_font_override("font", MENU_FONT)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", TEXT_DARK)
	btn.add_theme_color_override("font_hover_color", TEXT_DARK)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.6))
	btn.add_theme_stylebox_override("normal", _make_box(normal, 10, 3, border))
	btn.add_theme_stylebox_override("hover", _make_box(hover, 10, 3, border))
	btn.add_theme_stylebox_override("pressed", _make_box(pressed, 10, 3, border))
	btn.add_theme_stylebox_override("disabled", _make_box(pressed, 10, 3, border))
	btn.add_theme_stylebox_override("focus", _make_box(Color(0, 0, 0, 0), 10, 3, Color.WHITE))


func _apply_menu_style() -> void:
	root_panel.add_theme_stylebox_override("panel", _make_box(PANEL_BG, 20, 4, Color.WHITE))

	var vbox: VBoxContainer = $Root/Panel/Margin/MainVBox
	vbox.add_theme_constant_override("separation", 14)

	title_label.add_theme_font_override("font", MENU_FONT)
	title_label.add_theme_font_size_override("font_size", 30)

	feedback_label.add_theme_font_override("font", MENU_FONT)
	feedback_label.add_theme_font_size_override("font_size", 18)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.custom_minimum_size = Vector2(0, 48)  # stops the panel jumping when text wraps

	# Zone buttons: green = stays, warm orange = removed
	stay_button.custom_minimum_size = Vector2(250, 52)
	remove_button.custom_minimum_size = Vector2(250, 52)
	_style_button(stay_button, BTN_NORMAL, BTN_HOVER, BTN_PRESSED, 20)
	_style_button(remove_button, REMOVE_NORMAL, REMOVE_HOVER, REMOVE_PRESSED, 20)

	close_button.custom_minimum_size = Vector2(200, 48)
	_style_button(close_button, BTN_NORMAL, BTN_HOVER, BTN_PRESSED, 20)


# ---------- object cards ----------

func _build_object_row() -> void:
	for child in object_host.get_children():
		child.queue_free()
	_object_buttons.clear()
	for obj in OBJECTS:
		var btn := Button.new()
		btn.text = obj.label
		btn.custom_minimum_size = Vector2(180, 96)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_object_pressed.bind(obj.id))
		object_host.add_child(btn)
		_object_buttons[obj.id] = btn
	_refresh_selection()


## White border on the selected object card so it's clear what you picked.
func _refresh_selection() -> void:
	for id in _object_buttons:
		var btn: Button = _object_buttons[id]
		var border := Color.WHITE if id == _selected_id else BTN_BORDER
		_style_button(btn, BTN_NORMAL, BTN_HOVER, BTN_PRESSED, 16, border)
		if id == _selected_id:
			btn.add_theme_stylebox_override("normal", _make_box(BTN_HOVER, 10, 5, Color.WHITE))


func _on_object_pressed(obj_id: String) -> void:
	if _finish_pending:
		return
	_selected_id = obj_id
	_refresh_selection()
	feedback_label.text = "Selected: %s. Now choose a zone." % [OBJECTS[_object_index(obj_id)].label]


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
		if stays_in_nature:
			feedback_label.text = "Correct! %s can stay in nature." % [obj.label]
		else:
			feedback_label.text = "Correct! %s needs to be removed." % [obj.label]
		_object_buttons[_selected_id].disabled = true
		_object_buttons[_selected_id].modulate = Color(1, 1, 1, 0.5)
		_sorted_count += 1
		_selected_id = ""
		_refresh_selection()
		if _sorted_count >= OBJECTS.size():
			_finish_pending = true
			feedback_label.text = "All objects sorted! Well done observing what pollutes water."
			close_button.visible = true
	else:
		feedback_label.text = "Think again! %s belongs to the other zone." % [obj.label]
		_selected_id = ""
		_refresh_selection()


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
