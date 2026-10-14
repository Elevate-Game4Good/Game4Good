extends Control
## Qingxi Valley 3.0 medal-fragment HUD badge.
## The big medal is shown as ONE circle split into 3 pie slices
## (stone=green top-left, wooden sign=amber top-right, water-sort=blue bottom).
## A slice is dim until its easter-egg is finished, then lights up with its
## color. When all 3 are collected the whole medal is lit (fully explored).
##
## The badge is HIDDEN by default. Call `show_badge()` (e.g. from QuestState
## when an easter-egg completes) to reveal it for a few seconds. In the medal
## popup scene set `auto_hide = false` to keep it visible.

@export var auto_hide: bool = true

const SLICE_COLORS := {
	"stone": Color(0.35, 0.72, 0.42, 1.0),
	"sign": Color(0.95, 0.78, 0.30, 1.0),
	"minigame": Color(0.30, 0.55, 0.85, 1.0),
}
const SLICE_DIM := Color(0.42, 0.44, 0.46, 0.85)
const EDGE_COLOR := Color(0.85, 0.75, 0.45, 1.0)
const EDGE_DIM := Color(0.55, 0.55, 0.58, 0.9)

## Slice start angles (degrees, clockwise): 0 = right, 90 = down.
const SLICE_ANGLES := [-90.0, 30.0, 150.0]  # top-left, top-right, bottom

const HIDE_AFTER := 4.0

var _show_timer := 0.0


func _ready() -> void:
	add_to_group("fragment_medal_hud")
	if auto_hide:
		visible = false
	queue_redraw()


func _process(delta: float) -> void:
	queue_redraw()
	if auto_hide and visible:
		_show_timer += delta
		if _show_timer >= HIDE_AFTER:
			visible = false


## Reveal the medal badge (called when an easter-egg completes).
func show_badge() -> void:
	visible = true
	_show_timer = 0.0
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0 - 4.0
	var collected: Array[bool] = [
		QuestState.fragment_stone,
		QuestState.fragment_sign,
		QuestState.fragment_minigame,
	]
	var keys := ["stone", "sign", "minigame"]

	# Outer gold ring (dimmer until the whole medal is lit)
	var any_collected: bool = collected[0] or collected[1] or collected[2]
	var all_collected: bool = collected[0] and collected[1] and collected[2]
	draw_arc(center, radius, 0, TAU, 96,
		EDGE_COLOR if all_collected else EDGE_DIM, 5.0, true)

	# The three slices, each lights up when its easter-egg is done.
	for i in 3:
		var col: Color = SLICE_COLORS[keys[i]] if collected[i] else SLICE_DIM
		_draw_slice(center, radius, SLICE_ANGLES[i], 120.0, col)

	# Inner ring separates the slices; center drop-dot when fully explored.
	draw_arc(center, radius * 0.5, 0, TAU, 72, EDGE_DIM, 2.0, true)
	if all_collected:
		draw_circle(center, 8.0, Color(0.93, 0.8, 0.4, 1.0))
	elif any_collected:
		draw_circle(center, 4.0, Color(0.6, 0.6, 0.62, 1.0))


## Draw a pie slice: sector from `start_deg` covering `sweep_deg` degrees.
func _draw_slice(center: Vector2, radius: float, start_deg: float, sweep_deg: float, color: Color) -> void:
	var start_rad := deg_to_rad(start_deg)
	var sweep_rad := deg_to_rad(sweep_deg)
	var points := PackedVector2Array([center])
	var steps := 40
	for s in steps + 1:
		var a := start_rad + sweep_rad * s / steps
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(points, color)
