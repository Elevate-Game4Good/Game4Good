extends CanvasLayer
## Inventory (autoload). Open with I / Tab, close with I / Tab / Esc.
## Tabs: "Items", "Quest Items", and "Medals".

# ---- Look (matches the story guide panels) ----
const PANEL_BG := Color(0.051, 0.059, 0.078, 0.94)
const BORDER := Color(0.8, 0.8, 0.8)
const GREEN := Color(0.529, 0.639, 0.463)
const GREEN_HOVER := Color(0.396, 0.494, 0.337)
const GREEN_DARK := Color(0.212, 0.271, 0.173)
const SLATE := Color(0.16, 0.18, 0.22)
const SLATE_HOVER := Color(0.25, 0.28, 0.33)
const INNER_BG := Color(0.09, 0.105, 0.13, 0.9)
const YELLOW := Color(1.0, 0.85, 0.45)

const SLOT_SIZE := Vector2(108, 108)
const ICON_SIZE := Vector2(56, 56)
const GRID_COLUMNS := 5

enum Tab { ITEMS, QUEST_ITEMS, MEDALS }

## Fun facts, keyed by the trash item_id from BeachCleanupConfig.
const FUN_FACTS: Dictionary = {
	"plastic_bottle": {
		"title": "Plastic Bottle",
		"text": "A single plastic bottle can take up to 450 years to decompose in a landfill, but recycling just one saves enough energy to power a 60-watt light bulb for up to six hours.",
	},
	"plastic_bag": {
		"title": "Plastic Bags",
		"text": "Most plastic bags are used for an average of only 12 minutes, yet they can linger in the environment for up to 500 years because they break down into microplastics rather than fully biodegrading.",
	},
	"glass_bottle": {
		"title": "Glass Bottle",
		"text": "Glass is 100% recyclable and can be melted down and reused infinitely without ever losing its quality or purity.",
	},
	"metal_can": {
		"title": "Metal Cans",
		"text": "Aluminum cans are the ultimate recycling champions. A recycled aluminum can can be melted down, turned into a brand-new can, and placed back on a supermarket shelf in as little as 60 days.",
	},
	"broken_fishing_net": {
		"title": "Broken Fishing Net (Sea Waste)",
		"text": "Abandoned fishing gear, often called \"ghost nets,\" makes up about 10% of all marine litter and continues to catch and trap marine life for decades after being lost.",
	},
	"shell_food_waste": {
		"title": "Shell / Food Waste",
		"text": "When food waste breaks down in oxygen-starved landfills, it creates methane (a greenhouse gas), but shell waste, like oyster shells, can actually be repurposed to rebuild coastal reefs and restore ocean ecosystems.",
	},
}

const FACT_HINT_TITLE := "Information"
const FACT_HINT_TEXT := "Click an entry to view details."

var _tab: int = Tab.ITEMS
var _tab_chosen := false
var _lock_held := false
var _selected_key := ""

var _items_tab_button: Button
var _quest_tab_button: Button
var _medals_tab_button: Button
var _count_label: Label
var _grid: GridContainer
var _empty_label: Label
var _fact_title: Label
var _fact_text: Label

## key -> PanelContainer (slot), key -> entry Dictionary for the tab on screen
var _slots: Dictionary = {}
var _entries: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
	visible = false
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_build_ui()
	if InventoryManager.has_signal("inventory_changed"):
		InventoryManager.inventory_changed.connect(_on_inventory_changed)
	update_inventory()


# ============================================================================ open / close

func toggle_inventory() -> void:
	if visible:
		close_inventory()
	else:
		open_inventory()


func open_inventory() -> void:
	if not _tab_chosen:
		if InventoryManager.get_items().is_empty() and not _quest_entries().is_empty():
			_tab = Tab.QUEST_ITEMS
	update_inventory()
	visible = true
	_set_lock(true)


func close_inventory() -> void:
	visible = false
	_set_lock(false)


func _set_lock(held: bool) -> void:
	if held == _lock_held:
		return
	_lock_held = held
	if held:
		QuestState.push_interaction_input_lock()
	else:
		QuestState.pop_interaction_input_lock()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	var key := key_event.physical_keycode
	if key == KEY_I or key == KEY_TAB or key == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close_inventory()


func _on_inventory_changed() -> void:
	if visible:
		update_inventory()


# ============================================================================ building the UI

func _box(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	return box


func _label(text: String, font_size: int, color: Color = Color(0.95, 0.96, 0.97)) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _style_button(button: Button, normal: Color, hover: Color, pressed: Color, border: Color) -> void:
	for state in ["normal", "hover", "pressed"]:
		var bg: Color = normal
		var edge: Color = border
		if state == "hover":
			bg = hover
			edge = Color.WHITE
		elif state == "pressed":
			bg = pressed
		var box := _box(bg, edge, 3, 10)
		box.content_margin_left = 14.0
		box.content_margin_right = 14.0
		box.content_margin_top = 8.0
		box.content_margin_bottom = 8.0
		button.add_theme_stylebox_override(state, box)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)


func _build_ui() -> void:
	var root := Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.5)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 640)
	panel.add_theme_stylebox_override("panel", _box(PANEL_BG, BORDER, 4, 20))
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)

	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 10)
	margin.add_child(main)

	# --- header ---
	var header := HBoxContainer.new()
	main.add_child(header)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 0)
	header.add_child(title_box)
	title_box.add_child(_label("Your bag", 18, GREEN))
	title_box.add_child(_label("Inventory", 32))
	_count_label = _label("0 items", 18, Color(0.85, 0.87, 0.9))
	_count_label.size_flags_vertical = Control.SIZE_SHRINK_END
	header.add_child(_count_label)

	# --- tabs ---
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	main.add_child(tabs)
	
	_items_tab_button = Button.new()
	_items_tab_button.focus_mode = Control.FOCUS_NONE
	_items_tab_button.pressed.connect(_set_tab.bind(Tab.ITEMS))
	tabs.add_child(_items_tab_button)

	_quest_tab_button = Button.new()
	_quest_tab_button.focus_mode = Control.FOCUS_NONE
	_quest_tab_button.pressed.connect(_set_tab.bind(Tab.QUEST_ITEMS))
	tabs.add_child(_quest_tab_button)

	_medals_tab_button = Button.new()
	_medals_tab_button.focus_mode = Control.FOCUS_NONE
	_medals_tab_button.pressed.connect(_set_tab.bind(Tab.MEDALS))
	tabs.add_child(_medals_tab_button)

	# --- item grid ---
	var grid_panel := PanelContainer.new()
	grid_panel.custom_minimum_size = Vector2(0, 230)
	grid_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var grid_box := _box(INNER_BG, Color(0.45, 0.48, 0.52), 2, 12)
	grid_box.set_content_margin_all(12.0)
	grid_panel.add_theme_stylebox_override("panel", grid_box)
	main.add_child(grid_panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grid_panel.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = GRID_COLUMNS
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(_grid)

	_empty_label = _label("", 18, Color(0.85, 0.87, 0.9))
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid_panel.add_child(_empty_label)

	# --- description / fun fact panel (bottom) ---
	var fact_panel := PanelContainer.new()
	fact_panel.custom_minimum_size = Vector2(0, 150)
	var fact_box := _box(INNER_BG, GREEN, 2, 12)
	fact_box.set_content_margin_all(14.0)
	fact_panel.add_theme_stylebox_override("panel", fact_box)
	main.add_child(fact_panel)

	var fact_vbox := VBoxContainer.new()
	fact_vbox.add_theme_constant_override("separation", 6)
	fact_panel.add_child(fact_vbox)
	_fact_title = _label(FACT_HINT_TITLE, 20, GREEN)
	fact_vbox.add_child(_fact_title)
	_fact_text = _label(FACT_HINT_TEXT, 18)
	_fact_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fact_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fact_vbox.add_child(_fact_text)

	# --- footer ---
	var hint := _label("Press I, Tab or Esc to close", 16, Color(0.85, 0.87, 0.9, 0.7))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.add_child(hint)


# ============================================================================ data providers

func _item_entries() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for item_name in InventoryManager.get_items():
		list.append({
			"key": "item:" + item_name,
			"name": item_name,
			"texture": null,
			"title": item_name,
			"text": "Nothing special to note about this one yet.",
		})
	return list


func _quest_entries() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for trash in QuestState.get_beach_trash_collected_items():
		var item_id: String = trash.get("item_id", "")
		var fact: Dictionary = FUN_FACTS.get(item_id, {})
		list.append({
			"key": "quest:" + item_id,
			"name": trash.get("display_name", "Trash"),
			"texture": BeachTrashAtlas.get_texture(item_id),
			"title": fact.get("title", trash.get("display_name", "Trash")),
			"text": fact.get("text", "No fun fact for this item yet."),
		})
	return list


## Separate total medals for the "Medals" tab, updated dynamically as the player progresses.
func _medal_entries() -> Array[Dictionary]:
	var list: Array[Dictionary] = []

	# 1. Chapter 1 Easter Egg / Fragment Medal Progress
	var frag_count := QuestState.get_chapter1_fragment_count()
	var ch1_complete := QuestState.is_chapter1_medal_advanced()
	list.append({
		"key": "medal:chapter1_easter_egg",
		"name": "Valley Guardian",
		"texture": null,
		"title": "Valley Water Guardian (Chapter 1 Medal)",
		"text": "Easter egg fragments collected: %d / 3. Status: %s" % [
			frag_count, 
			"Fully Explored & Unlocked!" if ch1_complete else "In Progress"
		],
	})

	# 2. Sprinkler Challenge & Chapter 2 Garbage Sorting Medal progression
	var sprinkler_done: bool = QuestState.chapter1_sprinkler_minigame_completed
	var garbage_done: bool = QuestState.chapter2_beach_cleanup_done
	var ch2_mid_status = "Not Started"
	if garbage_done:
		ch2_mid_status = "Part 2 Complete (Garbage Sorting Finished)"
	elif sprinkler_done:
		ch2_mid_status = "Part 1 Complete (Sprinkler Challenge Finished)"
		
	list.append({
		"key": "medal:chapter2_progression",
		"name": "Eco Innovator",
		"texture": null,
		"title": "Sprinkler & Garbage Sorting Progress Medal",
		"text": "Current Progression: %s." % ch2_mid_status,
	})

	# 3. Chapter 2 Final Chapter Completion Medal
	var ch2_end_complete: bool = QuestState.is_chapter2_complete()
	list.append({
		"key": "medal:chapter2_end",
		"name": "Master Conservator",
		"texture": null,
		"title": "Chapter 2 Final Completion Medal",
		"text": "Status: %s. Awarded right before completing Chapter 2." % (
			"Unlocked" if ch2_end_complete else "Locked (Complete Chapter 2 to unlock)"
		),
	})

	return list


# ============================================================================ refreshing

func _set_tab(tab: int) -> void:
	_tab = tab
	_tab_chosen = true
	_selected_key = ""
	update_inventory()


func update_inventory() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_slots.clear()
	_entries.clear()

	var entries: Array[Dictionary] = []
	if _tab == Tab.QUEST_ITEMS:
		entries = _quest_entries()
	elif _tab == Tab.MEDALS:
		entries = _medal_entries()
	else:
		entries = _item_entries()

	for entry in entries:
		var slot := _make_slot(entry)
		_grid.add_child(slot)
		_slots[entry["key"]] = slot
		_entries[entry["key"]] = entry

	var count := entries.size()
	_count_label.text = "%d item%s" % [count, "" if count == 1 else "s"]
	_empty_label.visible = count == 0
	
	if _tab == Tab.QUEST_ITEMS:
		_empty_label.text = "No quest items yet.\nItems you collect for quests will be kept here."
	elif _tab == Tab.MEDALS:
		_empty_label.text = "No medals earned yet.\nComplete chapters and challenges to earn medals."
	else:
		_empty_label.text = "Your bag is empty.\nThings you pick up will appear here."

	var item_count := InventoryManager.get_items().size()
	var quest_count := QuestState.get_beach_trash_collected_count()
	# Count unlocked/total medals for display badge
	var medal_count := _medal_entries().size()
	
	_items_tab_button.text = "Items (%d)" % item_count
	_quest_tab_button.text = "Quest Items (%d)" % quest_count
	_medals_tab_button.text = "Medals (%d)" % medal_count
	
	_apply_tab_style(_items_tab_button, _tab == Tab.ITEMS)
	_apply_tab_style(_quest_tab_button, _tab == Tab.QUEST_ITEMS)
	_apply_tab_style(_medals_tab_button, _tab == Tab.MEDALS)

	if not _entries.has(_selected_key):
		_selected_key = ""
	_refresh_selection()


func _apply_tab_style(button: Button, active: bool) -> void:
	if active:
		_style_button(button, GREEN, GREEN_HOVER, GREEN_DARK, BORDER)
	else:
		_style_button(button, SLATE, SLATE_HOVER, SLATE, Color(0.7, 0.7, 0.7))


func _slot_box(selected: bool) -> StyleBoxFlat:
	if selected:
		return _box(Color(0.2, 0.2, 0.12), YELLOW, 3, 10)
	return _box(Color(0.13, 0.15, 0.18), Color(0.72, 0.76, 0.8), 2, 10)


func _refresh_selection() -> void:
	for key in _slots:
		var slot: PanelContainer = _slots[key]
		slot.add_theme_stylebox_override("panel", _slot_box(key == _selected_key))
	if _selected_key.is_empty():
		_fact_title.text = FACT_HINT_TITLE
		_fact_text.text = FACT_HINT_TEXT
	else:
		var entry: Dictionary = _entries[_selected_key]
		_fact_title.text = entry["title"]
		_fact_text.text = entry["text"]


func _on_slot_pressed(key: String) -> void:
	_selected_key = "" if _selected_key == key else key
	_refresh_selection()


func _make_slot(entry: Dictionary) -> PanelContainer:
	var key: String = entry["key"]
	var item_name: String = entry["name"]
	var texture: Texture2D = entry["texture"]

	var slot := PanelContainer.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.add_theme_stylebox_override("panel", _slot_box(false))

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	slot.add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	if texture != null:
		var icon := TextureRect.new()
		icon.texture = texture
		icon.custom_minimum_size = ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(icon)
	else:
		var letter := _label(item_name.substr(0, 1).to_upper(), 34)
		letter.custom_minimum_size = ICON_SIZE
		letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(letter)

	var name_label := _label(item_name, 14)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(88, 0)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)

	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.pressed.connect(_on_slot_pressed.bind(key))
	button.mouse_entered.connect(func() -> void: slot.modulate = Color(1.12, 1.12, 1.12))
	button.mouse_exited.connect(func() -> void: slot.modulate = Color.WHITE)
	slot.add_child(button)
	return slot
