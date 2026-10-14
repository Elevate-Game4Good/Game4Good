extends Control
## Draws the Chapter 1 completion medal.
## Basic: stream + valley outline + water-drop core on a round medal.
## Advanced: adds vine/lace outer ring + canal silhouette corner mark.

var advanced := false


func _ready() -> void:
	queue_redraw()


func set_advanced(value: bool) -> void:
	advanced = value
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0 - 8.0

	# Medal body
	draw_circle(center, radius, Color(0.93, 0.78, 0.35, 1.0))
	draw_arc(center, radius, 0, TAU, 96, Color(0.72, 0.52, 0.12, 1.0), 6.0, true)

	if advanced:
		# Vine/lace ring on outer edge (small alternating dots)
		var ring_radius := radius - 14.0
		for i in 36:
			var ang := TAU * i / 36.0
			var dot := center + Vector2(cos(ang), sin(ang)) * ring_radius
			draw_circle(dot, 4.5, Color(0.25, 0.6, 0.35, 1.0))
		# Canal silhouette corner mark (small zigzag at bottom-right)
		var mrk := center + Vector2(radius * 0.62, radius * 0.62)
		var zig: PackedVector2Array = [
			mrk + Vector2(-26, 6), mrk + Vector2(-10, -12), mrk + Vector2(2, 4), mrk + Vector2(16, -12), mrk + Vector2(28, 8),
		]
		draw_polyline(zig, Color(0.45, 0.62, 0.85, 1.0), 4.0, true)

	var inner_radius := radius - 26.0

	# Valley outline (arcs above the drop)
	draw_arc(center + Vector2(-inner_radius * 0.55, -inner_radius * 0.35), inner_radius * 0.55, PI * 0.15, PI * 0.85, 32, Color(0.30, 0.55, 0.30, 1.0), 5.0, true)
	draw_arc(center + Vector2(inner_radius * 0.55, -inner_radius * 0.35), inner_radius * 0.55, PI * 1.15, PI * 1.85, 32, Color(0.30, 0.55, 0.30, 1.0), 5.0, true)

	# Stream (flowing line across the bottom)
	var stream: PackedVector2Array = []
	for i in 24:
		var t := i / 23.0
		var x := lerpf(-inner_radius * 0.8, inner_radius * 0.8, t)
		var y := lerpf(inner_radius * 0.25, inner_radius * 0.45, t) + sin(t * TAU * 1.5) * 6.0
		stream.append(center + Vector2(x, y))
	draw_polyline(stream, Color(0.30, 0.62, 0.90, 1.0), 6.0, true)

	# Water drop core
	var drop := PackedVector2Array([
		center + Vector2(0, -inner_radius * 0.55),
		center + Vector2(inner_radius * 0.34, inner_radius * 0.05),
		center + Vector2(0, inner_radius * 0.45),
		center + Vector2(-inner_radius * 0.34, inner_radius * 0.05),
	])
	draw_colored_polygon(drop, Color(0.22, 0.58, 0.92, 1.0))
	draw_polyline(drop + PackedVector2Array([drop[0]]), Color(0.10, 0.40, 0.72, 1.0), 2.0, true)
