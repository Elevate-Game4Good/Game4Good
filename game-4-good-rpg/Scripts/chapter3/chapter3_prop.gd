extends Node2D
## Code-drawn props use a foot origin, matching the characters' Y sorting.
## Only the fountain animates continuously; static props redraw on phase changes.

@export_enum("fountain", "stage", "food", "ritual", "bench", "lantern") var kind := "fountain"
var phase := 0
var _time := 0.0


func _ready() -> void:
	set_process(kind == "fountain")


func set_phase(value: int) -> void:
	phase = value
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
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
	_ellipse(Vector2(12, -8), Vector2(145, 57), Color(0.25, 0.22, 0.17, 0.16))
	_ellipse(Vector2(0, -34), Vector2(133, 77), Color("a58969"))
	_ellipse(Vector2(0, -48), Vector2(133, 77), Color("dfcda9"))
	_ellipse(Vector2(0, -53), Vector2(116, 65), Color("4f9eaa"))
	_ellipse(Vector2(0, -55), Vector2(107, 57), Color("78c8c2"))
	for i in range(3):
		var r := 35.0 + fmod(_time * 12 + i * 24, 70)
		draw_arc(Vector2(0, -57), r, 0.1, PI - 0.1, 24, Color(0.86, 1, 0.94, 0.4), 2, true)
	draw_rect(Rect2(-19, -150, 38, 92), Color("c2b28e"))
	_ellipse(Vector2(0, -144), Vector2(57, 25), Color("eee1bb"))
	_ellipse(Vector2(0, -150), Vector2(46, 17), Color("78c8c2"))
	draw_line(Vector2(0, -150), Vector2(0, -195 + sin(_time * 3) * 4), Color("b6ede0"), 9, true)
	draw_circle(Vector2(0, -195), 8, Color("d4f5df"))


func _draw_stage() -> void:
	_ellipse(Vector2(5, 5), Vector2(235, 63), Color(0.25, 0.22, 0.17, 0.16))
	draw_rect(Rect2(-225, -58, 450, 66), Color("8d5b43"))
	draw_colored_polygon(PackedVector2Array([Vector2(-225, -58), Vector2(-190, -150), Vector2(190, -150), Vector2(225, -58)]), Color("c59665"))
	for i in range(9):
		draw_line(Vector2(-200 + i * 50, -60), Vector2(-173 + i * 43, -146), Color("a8754d"), 2, true)
	draw_rect(Rect2(-75, 8, 150, 16), Color("b88b60"))
	if phase == 0:
		_crate(Vector2(-145, -100))
		_crate(Vector2(115, -94))
		return
	draw_rect(Rect2(-202, -282, 13, 210), Color("866247"))
	draw_rect(Rect2(189, -282, 13, 210), Color("866247"))
	draw_rect(Rect2(-205, -290, 410, 22), Color("95734e"))
	if phase >= 2:
		draw_rect(Rect2(-188, -267, 75, 150), Color("a6505c"))
		draw_rect(Rect2(113, -267, 75, 150), Color("a6505c"))
		for x in [-170, -145, 130, 155]:
			draw_line(Vector2(x, -265), Vector2(x, -120), Color("c57171"), 5, true)
		_bunting(Vector2(-180, -270), Vector2(180, -270))
		# Musical instruments prepared for the shared performance.
		draw_circle(Vector2(-105, -135), 24, Color("b8784e"))
		draw_circle(Vector2(-105, -139), 18, Color("ead5a5"))
		draw_line(Vector2(100, -125), Vector2(100, -195), Color("41646b"), 6, true)
		draw_circle(Vector2(100, -199), 11, Color("41646b"))


func _draw_food() -> void:
	_ellipse(Vector2(8, -1), Vector2(114, 34), Color(0.25, 0.22, 0.17, 0.15))
	draw_rect(Rect2(-100, -95, 200, 95), Color("a67650"))
	draw_rect(Rect2(-108, -106, 216, 20), Color("dbb681"))
	for x in [-92, 82]:
		draw_rect(Rect2(x, -231, 10, 146), Color("805c45"))
	if phase == 0:
		_crate(Vector2(-48, -117))
		return
	for i in range(6):
		var color := Color("568d94") if i % 2 == 0 else Color("f4e4b8")
		draw_colored_polygon(PackedVector2Array([Vector2(-114 + i * 38, -236), Vector2(-76 + i * 38, -236), Vector2(-63 + i * 42, -180), Vector2(-105 + i * 42, -180)]), color)
	if phase >= 2:
		for i in range(6):
			var p := Vector2(-72 + i * 28, -112)
			draw_circle(p, 12, Color("edcd80"))
			draw_arc(p, 7, 0.2, 2.9, 10, Color("b57a47"), 2, true)
		for i in range(4):
			draw_circle(Vector2(-56 + i * 36, -132), 10, Color("d18a52"))


func _draw_ritual() -> void:
	_ellipse(Vector2(0, -45), Vector2(170, 75), Color("c9b58d"))
	_ellipse(Vector2(0, -51), Vector2(156, 65), Color("eee0bb"))
	draw_rect(Rect2(-106, -80, 212, 40), Color("718b83"))
	draw_rect(Rect2(-92, -72, 184, 24), Color("d9c28f"))
	for x in [-128, 128]:
		draw_rect(Rect2(x - 6, -150, 12, 105), Color("a47950"))
		draw_circle(Vector2(x, -157), 15, Color("e3c15f"))
	if phase >= 1:
		for x in [-55, 0, 55]:
			draw_circle(Vector2(x, -82), 17, Color("b98b52"))
			for i in range(3):
				draw_circle(Vector2(x - 9 + i * 9, -91), 8, Color("e4bb55"))
	if phase >= 2:
		_bunting(Vector2(-128, -155), Vector2(128, -155))


func _draw_bench() -> void:
	for x in [-43, 43]:
		draw_rect(Rect2(x - 5, -30, 10, 32), Color("735b44"))
	draw_rect(Rect2(-61, -58, 122, 17), Color("aa8055"))
	draw_rect(Rect2(-64, -31, 128, 18), Color("c49d6b"))


func _draw_lantern() -> void:
	draw_rect(Rect2(-4, -150, 8, 150), Color("856a4b"))
	if phase < 2:
		return
	if phase == 3:
		draw_circle(Vector2(0, -142), 40, Color(1, 0.83, 0.4, 0.12))
	draw_circle(Vector2(0, -142), 18, Color("f2d58a"))
	draw_line(Vector2(-13, -142), Vector2(13, -142), Color("b48a56"), 2, true)
	draw_line(Vector2(0, -125), Vector2(0, -110), Color("a65d59"), 3, true)


func _crate(pos: Vector2) -> void:
	draw_rect(Rect2(pos - Vector2(23, 0), Vector2(46, 32)), Color("b48b5b"))
	draw_rect(Rect2(pos - Vector2(23, 0), Vector2(46, 32)), Color("855f42"), false, 3)
	draw_line(pos + Vector2(-20, 3), pos + Vector2(20, 29), Color("855f42"), 3)


func _bunting(a: Vector2, b: Vector2) -> void:
	draw_line(a, b, Color("79674d"), 2, true)
	var colors := [Color("be6f69"), Color("64949a"), Color("e6bc61")]
	for i in range(9):
		var p := a.lerp(b, (i + 0.5) / 9.0)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-10, 2), p + Vector2(10, 2), p + Vector2(0, 24)]), colors[i % 3])


func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(40):
		var a := TAU * i / 40.0
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(points, color)
