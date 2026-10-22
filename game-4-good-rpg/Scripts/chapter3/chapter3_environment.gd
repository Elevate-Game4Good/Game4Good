extends Node2D
## Builds the town independently of the shared chapter/story controller.
## Festival visuals are derived from QuestState, so save/load needs no new fields.

const Layout = preload("res://Scripts/chapter3/chapter3_layout.gd")
const Ground = preload("res://Scripts/chapter3/chapter3_ground.gd")
const Prop = preload("res://Scripts/chapter3/chapter3_prop.gd")
const ATLAS := preload("res://Sprites/TileMaps/XingyueTown_Tileset.png")
const CROWD_TEXTURES := [
	preload("res://Sprites/Import/Arab girl.png"),
	preload("res://Sprites/Import/Black boy.png"),
	preload("res://Sprites/Import/Asian girl.png"),
	preload("res://Sprites/Import/White boy.png"),
]
const PHASE_NAMES := ["VISIT THE HOUSEHOLDS", "PREPARING TOGETHER", "READY FOR THE FESTIVAL", "HAPPY HARVEST FESTIVAL"]

var festival_phase := -1
var _props: Array[Node2D] = []
var _crowd: Node2D
var _phase_label: Label
var _obstacles: Array[Rect2] = []


func _ready() -> void:
	position = Layout.ORIGIN
	y_sort_enabled = true
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var ground := Ground.new()
	ground.name = "Ground"
	add_child(ground)
	_build_town()
	_build_boundaries()
	_build_labels()
	_build_crowd()
	_build_hud()
	for actor_name in ["Advaita", "Sarina", "Aurora", "MattKaiVillagers", "StarMoonCouncilGroup"]:
		get_parent().get_node(actor_name).set_meta("quest_marker_height", 142.0)
	_sync_phase()
	var timer := Timer.new()
	timer.wait_time = 0.2
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.timeout.connect(_sync_phase)
	add_child(timer)
	timer.start()
	call_deferred("_restore_player_safely")


func _build_town() -> void:
	_add_prop("Fountain", Layout.FOUNTAIN, "fountain", Rect2(-120, -100, 240, 105))
	_add_prop("Stage", Layout.STAGE, "stage", Rect2(-225, -150, 450, 160))
	_add_prop("FoodStall", Layout.FOOD, "food", Rect2(-108, -110, 216, 112))
	_add_prop("SecondFoodStall", Layout.FOOD + Vector2(300, 95), "food", Rect2(-108, -110, 216, 112))
	_add_prop("RitualTable", Layout.RITUAL, "ritual", Rect2(-110, -85, 220, 50))
	# Use complete, known atlas regions. The text-contaminated bottom row is unused.
	_add_atlas_prop("CouncilHouse", Layout.COUNCIL, Rect2(256, 0, 128, 128), 2.7, Rect2(-150, -90, 300, 95))
	_add_atlas_prop("AdvaitaHome", Vector2(-320, -600), Rect2(384, 0, 128, 128), 2.5, Rect2(-140, -80, 280, 85))
	_add_atlas_prop("SarinaHome", Vector2(-1000, 60), Rect2(256, 0, 128, 128), 2.3, Rect2(-125, -75, 250, 80))
	_add_atlas_prop("AuroraHome", Vector2(1040, 670), Rect2(384, 0, 128, 128), 2.3, Rect2(-125, -75, 250, 80))
	for p in [Vector2(-1240, 400), Vector2(-1070, 560), Vector2(-1210, 690), Vector2(1080, -720), Vector2(1260, -610)]:
		_add_atlas_prop("OrchardTree", p, Rect2(384, 128, 128, 128), 1.7, Rect2(-20, -22, 40, 28))
	for p in [Vector2(-1250, -650), Vector2(-550, -780), Vector2(440, -790), Vector2(1250, 80), Vector2(-720, 720), Vector2(480, 750)]:
		_add_atlas_prop("ShadeTree", p, Rect2(256, 128, 128, 128), 1.65, Rect2(-20, -24, 40, 30))
	for p in [Vector2(-1370, -70), Vector2(1340, 830), Vector2(-1300, 900), Vector2(1300, -900)]:
		_add_atlas_prop("Cactus", p, Rect2(768, 256, 128, 128), 1.4, Rect2(-17, -20, 34, 25))
	for p in [Vector2(-290, 160), Vector2(290, 160), Vector2(-300, -170), Vector2(310, -180)]:
		_add_prop("Bench", p, "bench", Rect2(-64, -32, 128, 32))
	for p in [Vector2(-400, 510), Vector2(400, 510), Vector2(-490, -390), Vector2(490, -390), Vector2(-150, 870), Vector2(150, 870)]:
		_add_prop("FestivalLantern", p, "lantern")
	# The pond is genuinely impassable; decorative water is not a walkable tile.
	var water := StaticBody2D.new()
	water.name = "PondCollision"
	water.position = Vector2(-1040, -280)
	var polygon := CollisionPolygon2D.new()
	var points := PackedVector2Array()
	for i in range(24):
		var a := TAU * i / 24.0
		points.append(Vector2(cos(a) * 150, sin(a) * 98))
	polygon.polygon = points
	water.add_child(polygon)
	add_child(water)
	_obstacles.append(Rect2(-1195, -383, 310, 206))


func _add_prop(prop_name: String, at: Vector2, kind: String, footprint := Rect2()) -> Node2D:
	var prop := Prop.new()
	prop.name = prop_name
	prop.kind = kind
	prop.position = at
	add_child(prop, true)
	_props.append(prop)
	if footprint.has_area():
		_add_body(prop, footprint)
	return prop


func _add_atlas_prop(prop_name: String, at: Vector2, region: Rect2, sprite_scale: float, footprint: Rect2) -> void:
	var prop := Node2D.new()
	prop.name = prop_name
	prop.position = at
	var sprite := Sprite2D.new()
	sprite.texture = ATLAS
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.position = Vector2(-region.size.x * sprite_scale / 2, -region.size.y * sprite_scale + 12)
	prop.add_child(sprite)
	add_child(prop, true)
	_add_body(prop, footprint)


func _add_body(prop: Node2D, footprint: Rect2) -> void:
	var body := StaticBody2D.new()
	body.name = "Footprint"
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = footprint.size
	collider.shape = shape
	collider.position = footprint.get_center()
	body.add_child(collider)
	prop.add_child(body)
	_obstacles.append(Rect2(prop.position + footprint.position, footprint.size))


func _build_boundaries() -> void:
	var bounds := Layout.BOUNDS
	for rect in [Rect2(bounds.position - Vector2(40, 40), Vector2(bounds.size.x + 80, 40)), Rect2(Vector2(bounds.position.x - 40, bounds.end.y), Vector2(bounds.size.x + 80, 40)), Rect2(bounds.position - Vector2(40, 0), Vector2(40, bounds.size.y)), Rect2(Vector2(bounds.end.x, bounds.position.y), Vector2(40, bounds.size.y))]:
		var holder := Node2D.new()
		holder.name = "TownBoundary"
		add_child(holder, true)
		_add_body(holder, rect)


func _build_labels() -> void:
	for title in Layout.REGION_LABELS:
		_add_label(title, Layout.REGION_LABELS[title], 20)
	_add_label("STAR & MOON TOWN", Vector2(0, 920), 26)


func _add_label(title: String, at: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.text = title
	label.position = at - Vector2(160, 0)
	label.size = Vector2(320, 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("f9f0d4"))
	label.add_theme_color_override("font_outline_color", Color("4a625d"))
	label.add_theme_constant_override("outline_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 5
	add_child(label)


func _build_crowd() -> void:
	_crowd = Node2D.new()
	_crowd.name = "FestivalCrowd"
	_crowd.y_sort_enabled = true
	add_child(_crowd)
	var locations := [Vector2(-800, -40), Vector2(-490, 0), Vector2(-760, 100), Vector2(-540, 180), Vector2(480, 440), Vector2(870, 520), Vector2(180, 370), Vector2(-170, 350)]
	for i in range(locations.size()):
		var person := Node2D.new()
		person.position = locations[i]
		var sprite := Sprite2D.new()
		sprite.texture = CROWD_TEXTURES[i % CROWD_TEXTURES.size()]
		sprite.position.y = -50
		sprite.scale = Vector2.ONE * 1.3
		person.add_child(sprite)
		_crowd.add_child(person)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TownStatus"
	layer.layer = 89
	add_child(layer)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -230
	panel.offset_right = 230
	panel.offset_top = 16
	panel.offset_bottom = 76
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("355d60e8")
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)
	var title := Label.new()
	title.text = "STAR & MOON TOWN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	box.add_child(title)
	_phase_label = Label.new()
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.add_theme_font_size_override("font_size", 12)
	_phase_label.add_theme_color_override("font_color", Color("f1d793"))
	box.add_child(_phase_label)
	var help_label := Label.new()
	help_label.text = "Arrows / click: move    Space: talk    Q: outfit    K / L: save / load"
	help_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	help_label.offset_left = -350
	help_label.offset_right = 350
	help_label.offset_top = -33
	help_label.offset_bottom = -8
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label.add_theme_font_size_override("font_size", 13)
	help_label.add_theme_color_override("font_color", Color("fff4d6"))
	help_label.add_theme_color_override("font_outline_color", Color("4a625d"))
	help_label.add_theme_constant_override("outline_size", 6)
	help_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(help_label)


func _sync_phase() -> void:
	var next_phase := Layout.phase_from_state(QuestState)
	if next_phase == festival_phase:
		return
	festival_phase = next_phase
	for prop in _props:
		prop.set_phase(festival_phase)
	_crowd.visible = festival_phase == 3
	_phase_label.text = PHASE_NAMES[festival_phase]
	var council := get_parent().get_node_or_null("StarMoonCouncilGroup") as Node2D
	if council != null:
		var local_at := Layout.CELEBRATION if festival_phase >= 2 else Vector2(950, -110)
		council.global_position = Layout.ORIGIN + local_at


func _restore_player_safely() -> void:
	# Wait until the shared story controller has applied a pending save position.
	if not is_inside_tree():
		return
	var tree := get_tree()
	await tree.process_frame
	if not is_inside_tree():
		return
	await tree.process_frame
	if not is_inside_tree():
		return
	var player := tree.get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var at := to_local(player.global_position)
	var safe_bounds := Layout.BOUNDS.grow(-45)
	var needs_reset := not safe_bounds.has_point(at)
	for obstacle in _obstacles:
		if obstacle.grow(22).has_point(at):
			needs_reset = true
			break
	if needs_reset:
		player.global_position = Layout.ORIGIN + Layout.SPAWN
		player.set("target_position", player.global_position)
		player.set("using_mouse", false)
		var camera := player.get_node_or_null("Camera2D") as Camera2D
		if camera != null:
			camera.reset_smoothing()
