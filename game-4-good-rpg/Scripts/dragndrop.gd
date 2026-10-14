extends Node2D

signal plank_placed(plank_id: int)

@export var plank_id: int = 0
@export var snap_distance: float = 52.0
@export var return_speed: float = 18.0
@export var drag_speed: float = 32.0

var selected := false
var placed := false
var start_position: Vector2
var target_position: Vector2

func _ready() -> void:
	add_to_group("bridge_plank")
	start_position = global_position
	target_position = start_position
	# Keep the sprite centred so the diamond tile lines up with the drop zone.
	var sprite := get_node_or_null("Sprite2D")
	if sprite:
		sprite.position = Vector2.ZERO
		sprite.centered = true
	# Wire the Area2D mouse events as a first input path.
	var area := get_node_or_null("Area2D")
	if area is Area2D:
		(area as Area2D).input_pickable = true
		if not (area as Area2D).input_event.is_connected(_on_area_2d_input_event):
			(area as Area2D).input_event.connect(_on_area_2d_input_event)

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	print("plank clicked: ", plank_id)
	if placed:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected = true
		z_index = 999

func _physics_process(delta: float) -> void:
	if placed:
		return
	if selected:
		global_position = global_position.lerp(get_global_mouse_position(), min(drag_speed * delta, 1.0))
	else:
		global_position = global_position.lerp(target_position, min(return_speed * delta, 1.0))

## Global mouse handling: press picks the plank whose Area2D is under the mouse
## (works even when Area2D input picking is unavailable), release drops it.
func _input(event: InputEvent) -> void:
	if placed:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _mouse_over_own_area():
				selected = true
				z_index = 999
				get_viewport().set_input_as_handled()
		elif selected:
			selected = false
			check_drop_zone()

func _mouse_over_own_area() -> bool:
	var area := get_node_or_null("Area2D") as Area2D
	if area == null:
		return false
	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collision_mask = area.collision_layer
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hits := space.intersect_point(query, 8)
	for hit in hits:
		if hit.get("collider") == area:
			return true
	return false

func check_drop_zone() -> void:
	var closest_zone: Node2D = null
	var closest_distance := snap_distance

	for zone in get_tree().get_nodes_in_group("bridge_zone"):
		if not zone is Node2D:
			continue
		if not zone.can_accept(plank_id):
			continue
		var distance := global_position.distance_to(zone.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_zone = zone

	if closest_zone != null:
		global_position = closest_zone.global_position
		target_position = closest_zone.global_position
		placed = true
		# Sort by y so lower tiles draw in front, matching the isometric bridge.
		z_index = int(global_position.y)
		closest_zone.place_plank()
		emit_signal("plank_placed", plank_id)
		_disable_drag_collision()
	else:
		z_index = 50
		target_position = start_position

func _disable_drag_collision() -> void:
	var area := get_node_or_null("Area2D")
	if area:
		area.input_pickable = false
