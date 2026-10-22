extends Node2D
## Pixel-grid props share the ochre outlines, gold highlights and timber shadows
## of the existing house sprites. Festival state and footprints remain separate.

@export_enum("fountain", "stage", "food", "ritual", "bench", "lantern") var kind := "fountain"
const INK := Color("70472c")
const GOLD := Color("f0ca7d")
const WOOD := Color("bb8548")
const LIGHT_WOOD := Color("d9a65c")
const DARK_WOOD := Color("915b34")
const WATER := Color("3ca5b0")
const GRID := 4.0
var phase := 0
var _time := 0.0
var _tick := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(kind == "fountain")


func set_phase(value: int) -> void:
	phase = value
	queue_redraw()


func _process(delta: float) -> void:
	_tick += delta
	if _tick >= 0.16:
		_tick = 0
		_time += 0.16
		queue_redraw()


func _draw() -> void:
	match kind:
		"fountain": _draw_fountain()
		"stage": _draw_stage()
		"food": _draw_food()
		"ritual": _draw_ritual()
		"bench": _draw_bench()
		"lantern": _draw_lantern()


func _draw_fountain() -> void:
	_ellipse(Vector2(12, -4), Vector2(145, 57), Color(0.42, 0.28, 0.14, 0.22))
	_ellipse(Vector2(0, -30), Vector2(136, 78), INK)
	_ellipse(Vector2(0, -36), Vector2(132, 74), Color("b88049"))
	_ellipse(Vector2(0, -48), Vector2(132, 76), GOLD)
	_ellipse(Vector2(0, -52), Vector2(118, 64), INK)
	_ellipse(Vector2(0, -56), Vector2(112, 58), Color("287b90"))
	_ellipse(Vector2(0, -60), Vector2(104, 52), WATER)
	for x in [-92, -48, 0, 48, 92]:
		_line(Vector2(x, -3), Vector2(x, 15), Color("a36b3f"))
	for i in range(3):
		var radius := 30.0 + fmod(_time * 16 + i * 25, 72)
		_arc(Vector2(0, -60), Vector2(radius, radius * 0.42), 0.1, PI - 0.1, Color("95dbcf"))
	_box(Rect2(-20, -152, 40, 96), Color("d5ad64"))
	_rect(Rect2(-12, -144, 8, 76), Color("f2d285"))
	_rect(Rect2(12, -144, 4, 76), Color("ac783f"))
	_ellipse(Vector2(0, -144), Vector2(60, 28), INK)
	_ellipse(Vector2(0, -148), Vector2(56, 24), GOLD)
	_ellipse(Vector2(0, -152), Vector2(44, 16), WATER)
	_line(Vector2(0, -156), Vector2(0, -188 - int(_time * 3) % 2 * 4), Color("9cddd1"), 8)
	_ellipse(Vector2(0, -192), Vector2(8, 8), Color("beeade"))


func _draw_stage() -> void:
	_ellipse(Vector2(8, 8), Vector2(236, 64), Color(0.42, 0.28, 0.14, 0.22))
	_box(Rect2(-228, -60, 456, 72), DARK_WOOD)
	for x in range(-216, 218, 36):
		_rect(Rect2(x, -52, 28, 52), WOOD)
		_rect(Rect2(x + 4, -44, 4, 24), LIGHT_WOOD)
		_line(Vector2(x + 20, -20), Vector2(x + 20, -8), Color("a56f3b"))
	_polygon(PackedVector2Array([Vector2(-228, -60), Vector2(-192, -152), Vector2(192, -152), Vector2(228, -60)]), LIGHT_WOOD)
	for i in range(10):
		_line(Vector2(-208 + i * 44, -64), Vector2(-176 + i * 38, -148), Color("ac793f"))
	_line(Vector2(-224, -60), Vector2(224, -60), GOLD)
	_box(Rect2(-80, 12, 160, 16), WOOD)
	_line(Vector2(-72, 12), Vector2(72, 12), GOLD)
	if phase == 0:
		_crate(Vector2(-144, -104))
		_crate(Vector2(116, -96))
		return
	_box(Rect2(-204, -288, 16, 216), DARK_WOOD)
	_box(Rect2(188, -288, 16, 216), DARK_WOOD)
	_box(Rect2(-208, -296, 416, 28), WOOD)
	_line(Vector2(-200, -288), Vector2(196, -288), GOLD)
	if phase >= 2:
		_box(Rect2(-188, -268, 76, 152), Color("af583d"))
		_box(Rect2(112, -268, 76, 152), Color("af583d"))
		for x in [-172, -148, 128, 152]:
			_rect(Rect2(x, -260, 8, 136), Color("cc7549"))
		_bunting(Vector2(-180, -268), Vector2(180, -268))
		_ellipse(Vector2(-104, -136), Vector2(28, 24), INK)
		_ellipse(Vector2(-104, -140), Vector2(24, 20), Color("c18a4b"))
		_ellipse(Vector2(-104, -144), Vector2(20, 12), GOLD)
		_line(Vector2(100, -124), Vector2(100, -192), INK, 8)
		_ellipse(Vector2(100, -200), Vector2(12, 12), Color("648872"))


func _draw_food() -> void:
	_ellipse(Vector2(8, 0), Vector2(116, 36), Color(0.42, 0.28, 0.14, 0.22))
	_box(Rect2(-100, -96, 200, 100), WOOD)
	for x in range(-92, 100, 28):
		_rect(Rect2(x, -84, 20, 76), LIGHT_WOOD)
		_line(Vector2(x + 4, -72), Vector2(x + 4, -24), Color("c4904e"))
	_box(Rect2(-108, -108, 216, 20), GOLD)
	for x in [-92, 80]:
		_box(Rect2(x, -236, 12, 148), DARK_WOOD)
	if phase == 0:
		_crate(Vector2(-48, -120))
		return
	for i in range(6):
		var color := Color("648c70") if i % 2 == 0 else Color("f0d48f")
		_polygon(PackedVector2Array([Vector2(-116 + i * 38, -240), Vector2(-78 + i * 38, -240), Vector2(-64 + i * 42, -180), Vector2(-106 + i * 42, -180)]), color)
		_rect(Rect2(-108 + i * 40, -184, 36, 12), color.darkened(0.13))
	if phase >= 2:
		for i in range(6):
			var p := Vector2(-72 + i * 28, -116)
			_ellipse(p, Vector2(12, 12), INK)
			_ellipse(p + Vector2(0, -4), Vector2(12, 8), GOLD)
			_rect(Rect2(p + Vector2(-4, -8), Vector2(8, 4)), Color("fff0b0"))
		for i in range(4):
			_ellipse(Vector2(-56 + i * 36, -136), Vector2(12, 12), Color("c9823f"))
			_rect(Rect2(-60 + i * 36, -144, 4, 4), Color("f3cb74"))


func _draw_ritual() -> void:
	_ellipse(Vector2(0, -44), Vector2(172, 76), Color("b98649"))
	_ellipse(Vector2(0, -52), Vector2(160, 68), GOLD)
	for x in range(-128, 130, 32):
		_line(Vector2(x, -16), Vector2(x + 16, -32), Color("d6a562"))
	_box(Rect2(-108, -84, 216, 44), Color("9b623b"))
	_rect(Rect2(-96, -76, 192, 28), Color("bd7748"))
	for x in range(-80, 88, 24):
		_rect(Rect2(x, -72, 8, 20), GOLD)
	for x in [-128, 128]:
		_box(Rect2(x - 8, -152, 16, 108), WOOD)
		_ellipse(Vector2(x, -160), Vector2(16, 16), INK)
		_ellipse(Vector2(x, -164), Vector2(12, 12), GOLD)
	if phase >= 1:
		for x in [-56, 0, 56]:
			_ellipse(Vector2(x, -84), Vector2(20, 16), INK)
			_ellipse(Vector2(x, -88), Vector2(16, 12), WOOD)
			for i in range(3):
				_ellipse(Vector2(x - 8 + i * 8, -96), Vector2(8, 8), Color("ecc266"))
	if phase >= 2:
		_bunting(Vector2(-128, -156), Vector2(128, -156))


func _draw_bench() -> void:
	for x in [-44, 44]:
		_box(Rect2(x - 4, -32, 12, 36), DARK_WOOD)
	_box(Rect2(-64, -60, 128, 20), WOOD)
	_line(Vector2(-56, -56), Vector2(56, -56), GOLD)
	_box(Rect2(-68, -32, 136, 20), LIGHT_WOOD)
	_line(Vector2(-60, -28), Vector2(60, -28), GOLD)


func _draw_lantern() -> void:
	_box(Rect2(-4, -152, 12, 156), WOOD)
	if phase < 2:
		return
	if phase == 3:
		_ellipse(Vector2(0, -144), Vector2(36, 32), Color(1, 0.79, 0.32, 0.12))
	_ellipse(Vector2(0, -144), Vector2(20, 20), INK)
	_ellipse(Vector2(0, -144), Vector2(16, 16), Color("edbd66"))
	_rect(Rect2(-8, -152, 8, 12), Color("f9dd8d"))
	_line(Vector2(-12, -144), Vector2(12, -144), Color("c08a43"))
	_line(Vector2(0, -124), Vector2(0, -108), Color("b35e3f"))


func _crate(pos: Vector2) -> void:
	_box(Rect2(pos - Vector2(24, 0), Vector2(48, 32)), WOOD)
	_line(pos + Vector2(-16, 4), pos + Vector2(16, 28), GOLD)
	_line(pos + Vector2(-16, 28), pos + Vector2(16, 4), DARK_WOOD)


func _bunting(a: Vector2, b: Vector2) -> void:
	_line(a, b, INK)
	var colors := [Color("c46b43"), Color("698d61"), Color("ecc265")]
	for i in range(9):
		var p := a.lerp(b, (i + 0.5) / 9.0)
		_polygon(PackedVector2Array([p + Vector2(-12, 4), p + Vector2(12, 4), p + Vector2(0, 24)]), colors[i % 3])


func _box(rect: Rect2, color: Color) -> void:
	_rect(rect, INK)
	_rect(rect.grow(-4), color)


func _rect(rect: Rect2, color: Color) -> void:
	draw_rect(Rect2(rect.position.snapped(Vector2.ONE * GRID), rect.size.snapped(Vector2.ONE * GRID)), color)


func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	for y in range(-int(radius.y), int(radius.y) + 1, 4):
		var normal_y := float(y) / radius.y
		var half_width := floorf(radius.x * sqrt(maxf(0, 1 - normal_y * normal_y)) / GRID) * GRID
		_rect(Rect2(center + Vector2(-half_width, y), Vector2(maxf(4, half_width * 2), 4)), color)


func _line(a: Vector2, b: Vector2, color: Color, width := 4.0) -> void:
	var steps := maxi(1, ceili(maxf(absf(b.x - a.x), absf(b.y - a.y)) / GRID))
	for i in range(steps + 1):
		var p := a.lerp(b, float(i) / steps).snapped(Vector2.ONE * GRID)
		_rect(Rect2(p, Vector2.ONE * width), color)


func _arc(center: Vector2, radius: Vector2, start: float, end: float, color: Color) -> void:
	var previous := center + Vector2(cos(start), sin(start)) * radius
	for i in range(1, 21):
		var angle := lerpf(start, end, i / 20.0)
		var point := center + Vector2(cos(angle), sin(angle)) * radius
		_line(previous, point, color)
		previous = point


func _polygon(points: PackedVector2Array, color: Color) -> void:
	var min_y := points[0].y
	var max_y := min_y
	for point in points:
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
	for y in range(floori(min_y / GRID) * 4, ceili(max_y / GRID) * 4, 4):
		var intersections: Array[float] = []
		for i in range(points.size()):
			var a := points[i]
			var b := points[(i + 1) % points.size()]
			if (a.y <= y and b.y > y) or (b.y <= y and a.y > y):
				intersections.append(a.x + (y - a.y) * (b.x - a.x) / (b.y - a.y))
		intersections.sort()
		for i in range(0, intersections.size() - 1, 2):
			_rect(Rect2(intersections[i], y, intersections[i + 1] - intersections[i], 4), color)
	for i in range(points.size()):
		_line(points[i], points[(i + 1) % points.size()], INK)
