extends CanvasLayer

signal sign_assembly_completed

# --- Shared UI style (same values as the settings menu / story guide / puzzles) ---
const UI_FONT: Font = preload("res://Sprites/Font/VCR_OSD_MONO_1.001.ttf")
const UI_PANEL_BG := Color(0.051, 0.059, 0.078, 0.784)
const UI_BORDER := Color(0.8, 0.8, 0.8)
const UI_GREEN := Color(0.529, 0.639, 0.463)
const UI_GREEN_HOVER := Color(0.396, 0.494, 0.337)
const UI_GREEN_DARK := Color(0.212, 0.271, 0.173)
const UI_GOLD := Color(1.0, 0.85, 0.45)
const UI_SLOT_EMPTY := Color(0.05, 0.06, 0.08, 0.9)

@onready var helper_label: Label = $Root/Panel/MarginContainer/MainVBox/HelperLabel
@onready var slot_1: Button = $Root/Panel/MarginContainer/MainVBox/SlotsRow/SignSlot1
@onready var slot_2: Button = $Root/Panel/MarginContainer/MainVBox/SlotsRow/SignSlot2
@onready var slot_3: Button = $Root/Panel/MarginContainer/MainVBox/SlotsRow/SignSlot3
@onready var piece_protect: Button = $Root/Panel/MarginContainer/MainVBox/PiecesRow/PieceProtect
@onready var piece_the_blue: Button = $Root/Panel/MarginContainer/MainVBox/PiecesRow/PieceTheBlue
@onready var piece_coast: Button = $Root/Panel/MarginContainer/MainVBox/PiecesRow/PieceCoast

var _selected_piece := ""
var _slot_contents := {
	1: "",
	2: "",
	3: "",
}


func _ready() -> void:
	# Must be ALWAYS: game is not paused while this UI is open.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_process_mode_recursive(self, Node.PROCESS_MODE_ALWAYS)
	layer = 130
	_configure_mouse_filters()
	_apply_style()
	QuestState.push_interaction_input_lock()
	_bind_piece(piece_protect, "Protect")
	_bind_piece(piece_the_blue, "the Blue")
	_bind_piece(piece_coast, "Coast")
	slot_1.pressed.connect(_on_slot_pressed.bind(1))
	slot_2.pressed.connect(_on_slot_pressed.bind(2))
	slot_3.pressed.connect(_on_slot_pressed.bind(3))
	_refresh_piece_highlight()


func _exit_tree() -> void:
	QuestState.pop_interaction_input_lock()


# =============================================================================
# STYLE
# =============================================================================

func _make_box(bg: Color, radius: int, border: int, border_color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border_color
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	return box


func _focus_box() -> StyleBoxFlat:
	var box := _make_box(Color(0, 0, 0, 0), 10, 3, Color.WHITE)
	box.draw_center = false
	return box


func _set_button_styles(button: Button, normal: StyleBox, hover: StyleBox, pressed: StyleBox, disabled: StyleBox) -> void:
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", _focus_box())


## Empty sign slot: dark box that lights up green on hover.
func _style_slot_empty(button: Button) -> void:
	_set_button_styles(
		button,
		_make_box(UI_SLOT_EMPTY, 10, 3, UI_BORDER),
		_make_box(Color(0.12, 0.14, 0.18, 0.95), 10, 3, UI_GREEN),
		_make_box(UI_GREEN_DARK, 10, 3, UI_GREEN),
		_make_box(UI_SLOT_EMPTY, 10, 3, UI_BORDER)
	)


## Slot after a correct piece was placed: solid green.
func _style_slot_filled(button: Button) -> void:
	var filled := _make_box(UI_GREEN, 10, 3, UI_BORDER)
	_set_button_styles(button, filled, filled, filled, filled)
	button.add_theme_color_override("font_disabled_color", Color.WHITE)


## Piece button: green like every other button; gold border while selected.
func _style_piece_button(button: Button, selected: bool = false) -> void:
	var normal: StyleBoxFlat
	if selected:
		normal = _make_box(UI_GREEN_HOVER, 10, 4, UI_GOLD)
	else:
		normal = _make_box(UI_GREEN, 10, 3, UI_BORDER)
	_set_button_styles(
		button,
		normal,
		_make_box(UI_GREEN_HOVER, 10, 3, UI_BORDER),
		_make_box(UI_GREEN_DARK, 10, 3, UI_BORDER),
		_make_box(UI_GREEN_DARK, 10, 3, Color(0.5, 0.5, 0.5))
	)
	button.add_theme_color_override("font_disabled_color", Color(0.75, 0.75, 0.75))


func _apply_font_recursive(node: Node) -> void:
	if node is Label or node is Button:
		(node as Control).add_theme_font_override("font", UI_FONT)
	for child in node.get_children():
		_apply_font_recursive(child)


func _apply_style() -> void:
	_apply_font_recursive($Root/Panel)
	$Root/Dimmer.color = Color(0.02, 0.03, 0.04, 0.65)

	var panel: PanelContainer = $Root/Panel
	panel.add_theme_stylebox_override("panel", _make_box(UI_PANEL_BG, 20, 4, UI_BORDER))
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.offset_left = -430.0
	panel.offset_right = 430.0
	panel.offset_top = -230.0
	panel.offset_bottom = 230.0

	var margin: MarginContainer = $Root/Panel/MarginContainer
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 30)

	var vbox: VBoxContainer = $Root/Panel/MarginContainer/MainVBox
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)

	var title: Label = vbox.get_node("TitleLabel")
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)

	(vbox.get_node("BoardLabel") as Label).add_theme_font_size_override("font_size", 18)

	helper_label.add_theme_font_size_override("font_size", 18)
	helper_label.add_theme_color_override("font_color", UI_GOLD)

	var pieces_title: Label = vbox.get_node("PiecesTitle")
	pieces_title.add_theme_font_size_override("font_size", 20)
	pieces_title.add_theme_color_override("font_color", UI_GREEN)

	for slot: Button in [slot_1, slot_2, slot_3]:
		slot.custom_minimum_size = Vector2(240, 72)
		slot.add_theme_font_size_override("font_size", 20)
		_style_slot_empty(slot)

	for piece: Button in [piece_protect, piece_the_blue, piece_coast]:
		piece.custom_minimum_size = Vector2(200, 60)
		piece.add_theme_font_size_override("font_size", 22)
		_style_piece_button(piece)


# =============================================================================
# PUZZLE LOGIC
# =============================================================================

func _configure_mouse_filters() -> void:
	var root: Control = $Root
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	$Root/Dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	$Root/Panel.mouse_filter = Control.MOUSE_FILTER_STOP


func _apply_process_mode_recursive(node: Node, mode: Node.ProcessMode) -> void:
	node.process_mode = mode
	for child in node.get_children():
		_apply_process_mode_recursive(child, mode)


func _bind_piece(button: Button, piece_text: String) -> void:
	button.pressed.connect(_on_piece_selected.bind(piece_text))


func _on_piece_selected(piece_text: String) -> void:
	if _is_piece_placed(piece_text):
		return
	_selected_piece = piece_text
	helper_label.text = "Selected: %s. Choose a slot." % piece_text
	_refresh_piece_highlight()


func _on_slot_pressed(slot_index: int) -> void:
	if _selected_piece.is_empty():
		helper_label.text = "Select a piece first."
		return
	if not _slot_contents[slot_index].is_empty():
		helper_label.text = "This slot is already filled."
		return
	if not _is_correct_for_slot(_selected_piece, slot_index):
		helper_label.text = "Try another spot. The sign should read: Protect the Blue Coast."
		return
	_slot_contents[slot_index] = _selected_piece
	_lock_piece(_selected_piece)
	_update_slot_text(slot_index, _selected_piece)
	helper_label.text = "Good placement."
	_selected_piece = ""
	_refresh_piece_highlight()
	if _all_slots_correct():
		_finish_success()


func _refresh_piece_highlight() -> void:
	var pieces := [
		{"button": piece_protect, "text": "Protect"},
		{"button": piece_the_blue, "text": "the Blue"},
		{"button": piece_coast, "text": "Coast"},
	]
	for entry in pieces:
		var button: Button = entry["button"]
		button.modulate = Color.WHITE
		_style_piece_button(button, not button.disabled and entry["text"] == _selected_piece)


func _is_correct_for_slot(piece_text: String, slot_index: int) -> bool:
	if slot_index == 1:
		return piece_text == "Protect"
	if slot_index == 2:
		return piece_text == "the Blue"
	return piece_text == "Coast"


func _update_slot_text(slot_index: int, piece_text: String) -> void:
	var slot: Button = [slot_1, slot_2, slot_3][slot_index - 1]
	slot.text = "Slot %d: %s" % [slot_index, piece_text]
	_style_slot_filled(slot)


func _lock_piece(piece_text: String) -> void:
	var button := _piece_button(piece_text)
	if button == null:
		return
	button.disabled = true
	button.text = "%s ✓" % piece_text
	_refresh_piece_highlight()


func _piece_button(piece_text: String) -> Button:
	match piece_text:
		"Protect":
			return piece_protect
		"the Blue":
			return piece_the_blue
		"Coast":
			return piece_coast
		_:
			return null


func _is_piece_placed(piece_text: String) -> bool:
	return _slot_contents[1] == piece_text or _slot_contents[2] == piece_text or _slot_contents[3] == piece_text


func _all_slots_correct() -> bool:
	return (
		_slot_contents[1] == "Protect"
		and _slot_contents[2] == "the Blue"
		and _slot_contents[3] == "Coast"
	)


func _finish_success() -> void:
	helper_label.text = "The sign is ready!"
	slot_1.disabled = true
	slot_2.disabled = true
	slot_3.disabled = true
	piece_protect.disabled = true
	piece_the_blue.disabled = true
	piece_coast.disabled = true
	await get_tree().create_timer(0.7).timeout
	if not is_inside_tree():
		return
	sign_assembly_completed.emit()
	queue_free()
