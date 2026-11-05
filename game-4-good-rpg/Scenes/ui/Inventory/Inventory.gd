extends CanvasLayer
## Inventory with three tabs: Items | Quest Items | Medals.
## The player scripts open/close it with Inventory.toggle_inventory().
## Other scripts can call Inventory.open_inventory("medals") and then `await Inventory.closed`.

signal closed

const MENU_FONT := preload("res://Sprites/Font/VCR_OSD_MONO_1.001.ttf")

const PANEL_BG := Color(0.051, 0.059, 0.078, 0.92)
const BORDER := Color(0.8, 0.8, 0.8)
const GREEN := Color(0.529, 0.639, 0.463)
const GREEN_HOVER := Color(0.396, 0.494, 0.337)
const GREEN_DARK := Color(0.212, 0.271, 0.173)
const CARD_BG := Color(0.09, 0.105, 0.13, 1.0)
const DARK_TEXT := Color(0.05, 0.06, 0.08)
const MUTED := Color(1, 1, 1, 0.6)
const GOLD := Color(0.93, 0.78, 0.35)
const GOLD_RIM := Color(0.72, 0.52, 0.12)

const TAB_ITEMS := "items"
const TAB_QUEST := "quest_items"
const TAB_MEDALS := "medals"

## Fun facts shown when a quest item is clicked. Key = item_id from BeachCleanupConfig.
const FUN_FACTS := {
	"plastic_bottle": "A single plastic bottle can take up to 450 years to decompose in a landfill, but recycling just one saves enough energy to power a 60-watt light bulb for up to six hours.",
	"plastic_bag": "Most plastic bags are used for an average of only 12 minutes, yet they can linger in the environment for up to 500 years because they break down into microplastics rather than fully biodegrading.",
	"glass_bottle": "Glass is 100% recyclable and can be melted down and reused infinitely without ever losing its quality or purity.",
	"metal_can": "Aluminum cans are the ultimate recycling champions: a recycled aluminum can can be melted down, turned into a brand-new can, and placed back on a supermarket shelf in as little as 60 days.",
	"broken_fishing_net": "Abandoned fishing gear, often called \"ghost nets\", makes up about 10% of all marine litter and continues to catch and trap marine life for decades after being lost.",
	"shell_food_waste": "When food waste breaks down in oxygen-starved landfills, it creates methane (a greenhouse gas), but shell waste, like oyster shells, can actually be repurposed to rebuild coastal reefs and restore ocean ecosystems.",
}

var _current_tab := TAB_ITEMS
var _medal_view := ""  # "" = collections overview, "path" or "easter" = one collection
var _selected_item := ""
var _input_locked := false

var _tab_buttons: Dictionary = {}
var _item_cards: Dictionary = {}
var _content: VBoxContainer
var _fact_panel: PanelContainer
var _fact_title: Label
var _fact_text: Label


## Round medal drawn in code: gold/green when earned, dark "?" when locked.
class MedalIcon extends Control:
	var earned := false
	var fill := Color(0.93, 0.78, 0.35)
	var rim := Color(0.72, 0.52, 0.12)
	var glyph := ""  # "" draws a diamond

	func _init(p_earned: bool, p_fill: Color, p_rim: Color, p_glyph: String, p_size: float) -> void:
		earned = p_earned
		fill = p_fill
		rim = p_rim
		glyph = p_glyph
		custom_minimum_size = Vector2(p_size, p_size)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0 - 4.0
		if r <= 0.0:
			return
		var ink := Color(0.25, 0.17, 0.05)
		if earned:
			draw_circle(c, r, fill)
			draw_arc(c, r, 0.0, TAU, 64, rim, 5.0, true)
			draw_arc(c, r * 0.72, 0.0, TAU, 64, rim, 2.0, true)
		else:
			ink = Color(0.5, 0.52, 0.57)
			draw_circle(c, r, Color(0.16, 0.18, 0.22))
			draw_arc(c, r, 0.0, TAU, 64, Color(0.35, 0.38, 0.43), 4.0, true)
		if not earned:
			_draw_text("?", c, r, ink)
		elif glyph == "":
			var d := r * 0.38
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -d * 1.3),
				c + Vector2(d, 0),
				c + Vector2(0, d * 1.3),
				c + Vector2(-d, 0),
			]), ink)
		else:
			_draw_text(glyph, c, r, ink)

	func _draw_text(text: String, c: Vector2, r: float, color: Color) -> void:
		var font := ThemeDB.fallback_font
		var fs := int(r * 0.95)
		var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var baseline := c.y + (font.get_ascent(fs) - font.get_descent(fs)) / 2.0
		draw_string(font, Vector2(c.x - ts.x / 2.0, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	visible = false
	_build_ui()


# ---------- public API ----------

func toggle_inventory() -> void:
	if visible:
		close_inventory()
	else:
		open_inventory()


## tab: "items", "quest_items" or "medals" (empty = keep the last tab)
func open_inventory(tab: String = "") -> void:
	if tab != "":
		_current_tab = tab
		_medal_view = ""
	visible = true
	_set_input_locked(true)
	_refresh()


func close_inventory() -> void:
	if not visible:
		return
	visible = false
	_set_input_locked(false)
	closed.emit()


func update_inventory() -> void:
	if visible:
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		close_inventory()
		get_viewport().set_input_as_handled()


func _set_input_locked(locked: bool) -> void:
	if locked == _input_locked:
		return
	_input_locked = locked
	if locked:
		QuestState.push_interaction_input_lock()
	else:
		QuestState.pop_interaction_input_lock()


# ---------- UI construction ----------

func _build_ui() -> void:
	# The old scene tree is replaced by this one
	var old := get_node_or_null("Control")
	if old != null:
		old.queue_free()

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(820, 580)
	panel.add_theme_stylebox_override("panel", _box(PANEL_BG, 20, 4, Color.WHITE))
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)
	var title := _make_label("Inventory", 32)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var hint := _make_label("I / Esc to close", 14, MUTED)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(hint)
	var close_btn := Button.new()
	close_btn.text = "X"
	_style_button(close_btn, 18, Vector2(44, 40))
	close_btn.pressed.connect(close_inventory)
	header.add_child(close_btn)

	# Tabs
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	vbox.add_child(tabs)
	for entry in [[TAB_ITEMS, "Items"], [TAB_QUEST, "Quest Items"], [TAB_MEDALS, "Medals"]]:
		var btn := Button.new()
		btn.text = entry[1]
		btn.pressed.connect(_on_tab_pressed.bind(entry[0]))
		tabs.add_child(btn)
		_tab_buttons[entry[0]] = btn

	# Scrollable content area
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	scroll.add_child(_content)

	# Fun-fact panel (only shown on the Quest Items tab)
	_fact_panel = PanelContainer.new()
	_fact_panel.custom_minimum_size = Vector2(0, 112)
	_fact_panel.add_theme_stylebox_override("panel", _box(CARD_BG, 12, 3, GREEN))
	vbox.add_child(_fact_panel)
	var fact_margin := MarginContainer.new()
	fact_margin.add_theme_constant_override("margin_left", 8)
	fact_margin.add_theme_constant_override("margin_right", 8)
	_fact_panel.add_child(fact_margin)
	var fact_box := VBoxContainer.new()
	fact_box.add_theme_constant_override("separation", 4)
	fact_margin.add_child(fact_box)
	_fact_title = _make_label("Fun fact", 18, GREEN)
	fact_box.add_child(_fact_title)
	_fact_text = _make_label("", 16)
	_fact_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fact_box.add_child(_fact_text)


func _refresh() -> void:
	for id in _tab_buttons:
		_style_tab(_tab_buttons[id], id == _current_tab)
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_item_cards.clear()
	_fact_panel.visible = _current_tab == TAB_QUEST
	match _current_tab:
		TAB_QUEST:
			_build_quest_items()
		TAB_MEDALS:
			_build_medals()
		_:
			_build_items()


func _on_tab_pressed(tab: String) -> void:
	_current_tab = tab
	_medal_view = ""
	_refresh()


# ---------- Items tab ----------

func _build_items() -> void:
	var items: Array = InventoryManager.get_items()
	if items.is_empty():
		_content.add_child(_make_label("Nothing here yet.", 18, MUTED))
		return
	for item_name in items:
		_content.add_child(_make_label("- " + str(item_name), 20))


# ---------- Quest Items tab ----------

func _build_quest_items() -> void:
	var items: Array[Dictionary] = QuestState.get_beach_trash_collected_items()
	if items.is_empty():
		_content.add_child(_make_label("No quest items yet.\nItems you collect on quests are kept here.", 18, MUTED))
		_update_fact()
		return
	_content.add_child(_make_label("Tap an item to learn a fun fact!", 16, MUTED))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	_content.add_child(grid)
	for item in items:
		var item_id := str(item.get("item_id", ""))
		var card := _make_item_card(item_id, str(item.get("display_name", item_id)))
		grid.add_child(card)
		_item_cards[item_id] = card
	_update_fact()


func _make_item_card(item_id: String, display_name: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(230, 128)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.add_theme_stylebox_override("panel", _item_card_box(item_id == _selected_item, false))
	card.gui_input.connect(_on_item_card_input.bind(item_id))
	card.mouse_entered.connect(_restyle_item_card.bind(item_id, true))
	card.mouse_exited.connect(_restyle_item_card.bind(item_id, false))

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)

	var tex := TextureRect.new()
	tex.texture = BeachTrashAtlas.get_texture(item_id)
	tex.custom_minimum_size = Vector2(56, 56)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(tex)

	var name_label := _make_label(display_name, 18)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	return card


func _item_card_box(selected: bool, hovered: bool) -> StyleBoxFlat:
	if selected:
		return _box(Color(0.15, 0.2, 0.15), 14, 4, Color.WHITE)
	if hovered:
		return _box(CARD_BG.lightened(0.08), 14, 3, Color.WHITE)
	return _box(CARD_BG, 14, 3, Color(0.45, 0.48, 0.52))


func _restyle_item_card(item_id: String, hovered: bool) -> void:
	if not _item_cards.has(item_id):
		return
	var card: PanelContainer = _item_cards[item_id]
	card.add_theme_stylebox_override("panel", _item_card_box(item_id == _selected_item, hovered))


func _on_item_card_input(event: InputEvent, item_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_item = item_id
		for id in _item_cards:
			_restyle_item_card(id, id == item_id)
		_update_fact()
		_pop_fact()


func _update_fact() -> void:
	if _selected_item == "" or not _item_cards.has(_selected_item):
		_fact_title.text = "Fun fact"
		_fact_text.text = "Tap an item above to learn something about it."
		return
	var config := BeachCleanupConfig.get_item_by_id(_selected_item)
	_fact_title.text = str(config.get("display_name", _selected_item))
	_fact_text.text = str(FUN_FACTS.get(_selected_item, "No fun fact for this one yet!"))


func _pop_fact() -> void:
	_fact_panel.pivot_offset = _fact_panel.size / 2.0
	_fact_panel.scale = Vector2(0.97, 0.9)
	_fact_panel.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_fact_panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_fact_panel, "modulate:a", 1.0, 0.15)


# ---------- Medals tab ----------

func _build_medals() -> void:
	match _medal_view:
		"path":
			_build_medal_detail("Path of Humanity", _path_entries(), GOLD, GOLD_RIM, "You collected every Path of Humanity medal!")
		"easter":
			_build_medal_detail("Easter Eggs", _easter_entries(), GREEN, GREEN_DARK, "You found every hidden easter egg. Great exploring!")
		_:
			_build_medal_overview()


func _path_entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in QuestState.PATH_MEDAL_INFO.size():
		var info: Dictionary = QuestState.PATH_MEDAL_INFO[i]
		out.append({
			"name": info["name"],
			"sub": info["place"],
			"hint": info["hint"],
			"earned": QuestState.has_path_medal(i + 1),
			"glyph": str(i + 1),
		})
	return out


func _easter_entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for info in QuestState.EASTER_EGG_MEDALS:
		out.append({
			"name": info["name"],
			"sub": "Clear Stream Valley",
			"hint": info["hint"],
			"earned": bool(QuestState.get(info["key"])),
			"glyph": "",
		})
	return out


func _count_earned(entries: Array[Dictionary]) -> int:
	var total := 0
	for entry in entries:
		if entry["earned"]:
			total += 1
	return total


func _build_medal_overview() -> void:
	var hint := _make_label("Tap a collection to see its medals.", 16, MUTED)
	_content.add_child(hint)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	center.add_child(row)
	row.add_child(_make_collection_card("Path of Humanity", _path_entries(), GOLD, GOLD_RIM, "path"))
	row.add_child(_make_collection_card("Easter Eggs", _easter_entries(), GREEN, GREEN_DARK, "easter"))


func _make_collection_card(title: String, entries: Array[Dictionary], fill: Color, rim: Color, view: String) -> PanelContainer:
	var earned := _count_earned(entries)
	var complete := earned == entries.size()
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 270)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := _box(CARD_BG, 16, 3, fill if complete else BORDER)
	var hover := _box(CARD_BG.lightened(0.08), 16, 3, Color.WHITE)
	card.add_theme_stylebox_override("panel", normal)
	card.mouse_entered.connect(func() -> void: card.add_theme_stylebox_override("panel", hover))
	card.mouse_exited.connect(func() -> void: card.add_theme_stylebox_override("panel", normal))
	card.gui_input.connect(_on_collection_input.bind(view))

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	box.add_child(MedalIcon.new(earned > 0, fill, rim, "", 120))
	var title_label := _make_label(title, 22)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)
	var count_label := _make_label("%d / %d" % [earned, entries.size()], 20, fill)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(count_label)
	return card


func _on_collection_input(event: InputEvent, view: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_medal_view = view
		_refresh()


func _build_medal_detail(title: String, entries: Array[Dictionary], fill: Color, rim: Color, complete_text: String) -> void:
	var earned := _count_earned(entries)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	_content.add_child(top)
	var back := Button.new()
	back.text = "< Back"
	_style_button(back, 18, Vector2(120, 40))
	back.pressed.connect(_on_medal_back)
	top.add_child(back)
	var heading := _make_label("%s   %d / %d" % [title, earned, entries.size()], 24)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(heading)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(120, 0)
	top.add_child(spacer)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	center.add_child(row)
	for entry in entries:
		row.add_child(_make_medal_slot(entry, fill, rim))

	if earned == entries.size():
		var done := _make_label(complete_text, 16, fill)
		done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_content.add_child(done)


func _make_medal_slot(entry: Dictionary, fill: Color, rim: Color) -> VBoxContainer:
	var earned: bool = entry["earned"]
	var slot := VBoxContainer.new()
	slot.custom_minimum_size = Vector2(190, 0)
	slot.add_theme_constant_override("separation", 8)
	slot.add_child(MedalIcon.new(earned, fill, rim, str(entry.get("glyph", "")), 110))

	var name_label := _make_label(str(entry["name"]) if earned else "???", 18)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slot.add_child(name_label)

	var sub_label := _make_label(str(entry["sub"]) if earned else str(entry["hint"]), 14, MUTED)
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slot.add_child(sub_label)
	return slot


func _on_medal_back() -> void:
	_medal_view = ""
	_refresh()


# ---------- style helpers ----------

func _box(bg: Color, radius: int, border: int, border_color: Color) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.set_corner_radius_all(radius)
	b.set_border_width_all(border)
	b.border_color = border_color
	b.content_margin_left = 10
	b.content_margin_right = 10
	b.content_margin_top = 10
	b.content_margin_bottom = 10
	return b


func _make_label(text: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", MENU_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _style_button(btn: Button, font_size: int, min_size: Vector2) -> void:
	btn.custom_minimum_size = min_size
	btn.add_theme_font_override("font", MENU_FONT)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", DARK_TEXT)
	btn.add_theme_color_override("font_hover_color", DARK_TEXT)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal", _box(GREEN, 10, 3, BORDER))
	btn.add_theme_stylebox_override("hover", _box(GREEN_HOVER, 10, 3, BORDER))
	btn.add_theme_stylebox_override("pressed", _box(GREEN_DARK, 10, 3, BORDER))
	btn.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), 10, 3, Color.WHITE))


func _style_tab(btn: Button, selected: bool) -> void:
	btn.custom_minimum_size = Vector2(170, 42)
	btn.add_theme_font_override("font", MENU_FONT)
	btn.add_theme_font_size_override("font_size", 20)
	var text_color := DARK_TEXT if selected else Color.WHITE
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", DARK_TEXT)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	var normal_bg := GREEN if selected else CARD_BG
	var normal_border := Color.WHITE if selected else Color(0.45, 0.48, 0.52)
	btn.add_theme_stylebox_override("normal", _box(normal_bg, 10, 3, normal_border))
	btn.add_theme_stylebox_override("hover", _box(GREEN_HOVER, 10, 3, Color.WHITE))
	btn.add_theme_stylebox_override("pressed", _box(GREEN_DARK, 10, 3, Color.WHITE))
	btn.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), 10, 3, Color.WHITE))
