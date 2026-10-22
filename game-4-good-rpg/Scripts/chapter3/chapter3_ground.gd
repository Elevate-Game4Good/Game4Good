extends Node2D
## Static ground only. Buildings, stalls and people are separate sortable nodes.

const Layout = preload("res://Scripts/chapter3/chapter3_layout.gd")

func _ready() -> void:
	z_index = -20


func _draw() -> void:
	draw_rect(Rect2(-8000, -8000, 16000, 16000), Color("e4c997"))
	# Deterministic ground detail: reloading a save never changes the landscape.
	var rng := RandomNumberGenerator.new()
	rng.seed = 307
	for i in range(190):
		var p := Vector2(rng.randf_range(-1540, 1540), rng.randf_range(-1100, 1100))
		draw_line(p, p + Vector2(rng.randf_range(5, 18), 2), Color("d8bb85"), 2, true)

	_ellipse(Vector2.ZERO, Vector2(1230, 810), Color("d6c28c"))
	_ellipse(Vector2.ZERO, Vector2(1110, 710), Color("ead8ad"))
	var ring := _ellipse_points(Vector2.ZERO, Vector2(1070, 660))
	draw_polyline(ring, Color("b79c76"), 170, true)
	draw_polyline(ring, Color("d5c6a6"), 150, true)
	draw_polyline(ring, Color("e9dfc9"), 116, true)
	for dest in [Vector2(0, -800), Vector2(-820, -180), Vector2(1050, -150), Vector2(820, 470), Vector2(0, 1020)]:
		draw_line(Vector2.ZERO, dest, Color("bda782"), 155, true)
		draw_line(Vector2.ZERO, dest, Color("e9dfc9"), 137, true)

	_ellipse(Vector2.ZERO, Vector2(445, 285), Color("bfa885"))
	_ellipse(Vector2.ZERO, Vector2(430, 272), Color("eee4cf"))
	for radius in [170, 270, 370]:
		draw_polyline(_ellipse_points(Vector2.ZERO, Vector2(radius, radius * 0.63)), Color("d1bea0"), 2, true)
	for i in range(12):
		var a := TAU * i / 12.0
		draw_line(Vector2(cos(a) * 145, sin(a) * 92), Vector2(cos(a) * 425, sin(a) * 268), Color("d1bea0"), 2, true)

	# Quiet planted gardens, separate from the busy food and performance areas.
	_ellipse(Vector2(80, -640), Vector2(335, 180), Color("b9c696"))
	_ellipse(Vector2(-1130, 440), Vector2(210, 260), Color("b5c08d"))
	_ellipse(Vector2(1110, -740), Vector2(230, 170), Color("b5c08d"))
	_ellipse(Vector2(-1040, -270), Vector2(165, 115), Color("bfae85"))
	_ellipse(Vector2(-1040, -280), Vector2(150, 98), Color("7dbab2"))
	_ellipse(Vector2(-1040, -286), Vector2(130, 78), Color("94cfc0"))
	for i in range(5):
		var p := Vector2(-1120 + i * 32, -290 + sin(i) * 18)
		draw_line(p, p + Vector2(25, 0), Color("c4e6ce"), 3, true)

	# Entrance carpet and a small star motif create a recognisable town identity.
	draw_rect(Rect2(-88, 790, 176, 135), Color("467e82"))
	for x in [-70, 70]:
		draw_line(Vector2(x, 800), Vector2(x, 915), Color("e5c17c"), 4, true)
	var star := PackedVector2Array()
	for i in range(10):
		var a := -PI / 2 + i * PI / 5
		var radius := 26.0 if i % 2 == 0 else 12.0
		star.append(Vector2(0, 850) + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(star, Color("f7df9e"))


func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	draw_colored_polygon(_ellipse_points(center, radius), color)


func _ellipse_points(center: Vector2, radius: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(65):
		var a := TAU * i / 64.0
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	return points
