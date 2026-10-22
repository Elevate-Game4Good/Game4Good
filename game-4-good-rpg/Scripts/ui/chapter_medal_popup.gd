extends CanvasLayer
## Chapter 1 completion medal popup (Qingxi Valley 2.0).
## Shown automatically when Chapter 1 main line closes. Emits `closed` when dismissed.

signal closed

# Same look as the settings menu
const MENU_FONT := preload("res://Sprites/Font/VCR_OSD_MONO_1.001.ttf")
const PANEL_BG := Color(0.051, 0.059, 0.078, 0.784)
const BTN_NORMAL := Color(0.529, 0.639, 0.463)
const BTN_HOVER := Color(0.396, 0.494, 0.337)
const BTN_PRESSED := Color(0.212, 0.271, 0.173)
const BTN_BORDER := Color(0.8, 0.8, 0.8)

var _advanced := false

@onready var medal_draw: Control = $Root/Panel/Margin/MainVBox/MedalHost/MedalDraw
@onready var title_label: Label = $Root/Panel/Margin/MainVBox/TitleLabel
@onready var desc_label: Label = $Root/Panel/Margin/MainVBox/DescLabel
@onready var gallery_label: Label = $Root/Panel/Margin/MainVBox/GalleryLabel
@onready var fragment_hint_label: Label = $Root/Panel/Margin/MainVBox/FragmentHintLabel
@onready var close_button: Button = $Root/Panel/Margin/MainVBox/CloseButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 150
	QuestState.push_interaction_input_lock()
	_apply_menu_style()
	_advanced = QuestState.is_chapter1_medal_advanced()
	medal_draw.set("advanced", _advanced)
	medal_draw.queue_redraw()
	title_label.text = "Valley Water Guardian"
	desc_label.text = "You helped the villagers of Qingxi Valley solve water-related difficulties and learned the importance of cherishing water resources."
	gallery_label.text = "Saved to the Path-of-Humanity Medal Hall"
	if _advanced:
		gallery_label.text += "  [Fully Explored]"
	var frag_count := QuestState.get_chapter1_fragment_count()
	fragment_hint_label.text = "Medal fragments: %d / 3" % frag_count
	_refresh_fragment_icons()
	close_button.pressed.connect(_on_close_pressed)


func _exit_tree() -> void:
	QuestState.pop_interaction_input_lock()


func _make_box(bg: Color, radius: int, border_width: int, border_color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(radius)
	box.set_border_width_all(border_width)
	box.border_color = border_color
	return box


func _apply_menu_style() -> void:
	# Panel: dark, white 4px border, rounded, sized to fit inside 1280x720
	var panel: PanelContainer = $Root/Panel
	panel.add_theme_stylebox_override("panel", _make_box(PANEL_BG, 20, 4, Color.WHITE))
	panel.offset_left = -300.0
	panel.offset_right = 300.0
	panel.offset_top = -300.0
	panel.offset_bottom = 300.0

	var margin: MarginContainer = $Root/Panel/Margin
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)

	var vbox: VBoxContainer = $Root/Panel/Margin/MainVBox
	vbox.add_theme_constant_override("separation", 6)

	# Fonts and sizes
	for label: Label in [title_label, desc_label, gallery_label, fragment_hint_label]:
		label.add_theme_font_override("font", MENU_FONT)
	title_label.add_theme_font_size_override("font_size", 30)
	desc_label.add_theme_font_size_override("font_size", 18)
	gallery_label.add_theme_font_size_override("font_size", 16)
	fragment_hint_label.add_theme_font_size_override("font_size", 16)

	# Smaller medal graphics so everything fits (both draw with `size`)
	medal_draw.custom_minimum_size = Vector2(170, 170)
	$Root/Panel/Margin/MainVBox/FragmentBadge.custom_minimum_size = Vector2(120, 90)

	# Button: same green rounded style as the settings menu
	close_button.custom_minimum_size = Vector2(220, 48)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.add_theme_font_override("font", MENU_FONT)
	close_button.add_theme_font_size_override("font_size", 22)
	close_button.add_theme_stylebox_override("normal", _make_box(BTN_NORMAL, 10, 3, BTN_BORDER))
	close_button.add_theme_stylebox_override("hover", _make_box(BTN_HOVER, 10, 3, BTN_BORDER))
	close_button.add_theme_stylebox_override("pressed", _make_box(BTN_PRESSED, 10, 3, BTN_BORDER))
	close_button.add_theme_stylebox_override("focus", _make_box(BTN_HOVER, 10, 3, Color.WHITE))


func _refresh_fragment_icons() -> void:
	$Root/Panel/Margin/MainVBox/FragmentBadge.queue_redraw()


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
