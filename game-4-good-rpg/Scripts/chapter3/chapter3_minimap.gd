extends Control
## Fixed overview of the actual town layout, with live quest objectives.

const Layout = preload("res://Scripts/chapter3/chapter3_layout.gd")
var _refresh := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_refresh += delta
	if _refresh >= 0.1:
		_refresh = 0
		queue_redraw()


func _draw() -> void:
	draw_style_box(_panel_style(), Rect2(Vector2.ZERO, size))
	var road := PackedVector2Array()
	for i in range(49):
		var a := TAU * i / 48.0
		road.append(_point(Vector2(cos(a) * 1070, sin(a) * 660)))
	draw_polyline(road, Color("e4d4ad"), 7, true)
	for dest in [Vector2(0, -800), Vector2(-820, -180), Vector2(1050, -150), Vector2(820, 470), Vector2(0, 900)]:
		draw_line(_point(Vector2.ZERO), _point(dest), Color("e4d4ad"), 6, true)
	draw_circle(_point(Layout.FOUNTAIN), 7, Color("79cfcc"))
	for p in [Layout.STAGE, Layout.FOOD, Layout.RITUAL, Layout.COUNCIL]:
		draw_rect(Rect2(_point(p) - Vector2(5, 4), Vector2(10, 8)), Color("c58c68"))
	for marker in get_tree().get_nodes_in_group("minimap_objective"):
		if not (marker is Node2D) or not marker.is_visible_in_tree():
			continue
		var key: StringName = marker.get("objective_key")
		if QuestState.is_minimap_objective_active(key):
			draw_circle(_point(marker.global_position - Layout.ORIGIN), 5, Color("f3cb66"))
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		var p := _point(player.global_position - Layout.ORIGIN)
		draw_circle(p, 6, Color("355d60"))
		draw_circle(p, 4, Color("d2ffff"))


func _point(local_position: Vector2) -> Vector2:
	var uv := (local_position - Layout.BOUNDS.position) / Layout.BOUNDS.size
	return Vector2(12, 12) + uv * (size - Vector2(24, 24))


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("355d60ed")
	style.border_color = Color("e1c689")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style
