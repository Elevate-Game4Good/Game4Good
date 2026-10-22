extends Node2D
## Native pixel-art terrain on a four-world-pixel grid.
## Warm sandstone and ochre follow the Chapter 1/2 terrain and existing houses.

const PIXEL_SIZE := 4
const IMAGE_SIZE := Vector2i(776, 556)
const IMAGE_ORIGIN := Vector2(-1552, -1112)
const SAND := [Color("e6b76b"), Color("e9bd74"), Color("dfaa60"), Color("d39c54"), Color("f0c57f")]
const STONE := [Color("edc786"), Color("e7bc78"), Color("dfaf68"), Color("f1cf94"), Color("d8a261")]
const GRASS := [Color("a7b55b"), Color("aebb62"), Color("95a34d"), Color("bcc972"), Color("879448")]
const WATER := [Color("359fad"), Color("3ba9b3"), Color("50b7bc"), Color("79cfcc"), Color("277f94")]
const PATH_ENDS := [Vector2(0, -800), Vector2(-820, -180), Vector2(1050, -150), Vector2(820, 470), Vector2(0, 1020)]

static var _cached_texture: ImageTexture


func _ready() -> void:
	z_index = -20
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _cached_texture == null:
		_cached_texture = ImageTexture.create_from_image(_build_ground())
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-8000, -8000, 16000, 16000), SAND[0])
	if _cached_texture != null:
		draw_texture_rect(_cached_texture, Rect2(IMAGE_ORIGIN, Vector2(IMAGE_SIZE) * PIXEL_SIZE), false)


func _build_ground() -> Image:
	var image := Image.create(IMAGE_SIZE.x, IMAGE_SIZE.y, false, Image.FORMAT_RGBA8)
	for y in range(IMAGE_SIZE.y):
		for x in range(IMAGE_SIZE.x):
			var point := IMAGE_ORIGIN + Vector2(x * PIXEL_SIZE, y * PIXEL_SIZE)
			var noise := _noise(x, y)
			var color := _sand_color(x, y, noise)
			var garden := _garden_distance(point)
			if garden < 1.06:
				color = _grass_color(x, y, noise) if garden < 0.96 else SAND[2]
			if _is_path(point):
				color = _paving_color(point, noise, false)
			var plaza := (point / Vector2(445, 285)).length_squared()
			if plaza < 1.05:
				color = Color("bd884c") if plaza > 0.97 else _paving_color(point, noise, true)
			var pond := ((point - Vector2(-1040, -280)) / Vector2(150, 98)).length_squared()
			if pond < 1.18:
				color = Color("b68047")
			if pond < 1.07:
				color = Color("f0cd89")
			if pond < 0.92:
				color = _water_color(x, y, noise)
			if absf(point.x) <= 88 and point.y >= 790 and point.y < 925:
				color = _carpet_color(point)
			image.set_pixel(x, y, color)
	return image


func _sand_color(x: int, y: int, noise: int) -> Color:
	# Connected grain clusters resemble the scuffs on Chapter 2 sand tiles.
	var cluster := _noise(x >> 2, y >> 2)
	if noise < 140:
		return SAND[3]
	if noise > 9650:
		return SAND[4]
	if cluster < 900 and (x + y) % 3 != 0:
		return SAND[2]
	if cluster > 8200:
		return SAND[1]
	return SAND[0]


func _paving_color(point: Vector2, noise: int, plaza: bool) -> Color:
	# Staggered isometric sandstone blocks, like the first chapters' tile tops.
	var u := point.x / 80.0 + point.y / 40.0
	var v := point.y / 40.0 - point.x / 80.0
	var tile_x := floori(u)
	var tile_y := floori(v)
	var fu := u - floorf(u)
	var fv := v - floorf(v)
	var shade := _noise(tile_x + 200, tile_y + 200) % 4
	if fu < 0.045 or fv < 0.045:
		return Color("bd8b50")
	if fu < 0.105 or fv < 0.105:
		return Color("f5d69b")
	if fu > 0.93 or fv > 0.93:
		return STONE[4]
	if noise < 180:
		return STONE[4]
	if noise > 9750:
		return Color("f5d69b")
	return STONE[(shade + (1 if plaza else 0)) % 4]


func _grass_color(x: int, y: int, noise: int) -> Color:
	var cluster := _noise(x >> 1, y >> 1)
	if noise < 550:
		return GRASS[4]
	if noise > 9200:
		return GRASS[3]
	return GRASS[cluster % 3]


func _water_color(x: int, y: int, noise: int) -> Color:
	var row := posmod(y + (x >> 3), 13)
	if row == 0 and posmod(x, 19) < 10:
		return Color("a0e3d3")
	if row == 1 and posmod(x, 19) < 12:
		return WATER[3]
	return WATER[1 if noise > 2600 else 0]


func _carpet_color(point: Vector2) -> Color:
	if absf(point.x) > 76 or point.y < 802 or point.y > 912:
		return Color("73452f")
	if absf(point.x) > 64 or point.y < 810 or point.y > 904:
		return Color("efc776")
	var p := point - Vector2(0, 855)
	if (absf(p.x) < 8 and absf(p.y) < 28) or (absf(p.y) < 8 and absf(p.x) < 28) or absf(p.x) + absf(p.y) < 23:
		return Color("f4d78a")
	return Color("a4553b") if (floori(point.x / 8) + floori(point.y / 8)) % 2 == 0 else Color("b36040")


func _is_path(point: Vector2) -> bool:
	var radius := (point / Vector2(1070, 660)).length()
	if radius > 0.91 and radius < 1.09:
		return true
	for end in PATH_ENDS:
		var t := clampf(point.dot(end) / end.length_squared(), 0, 1)
		if point.distance_squared_to(end * t) < 4900:
			return true
	return false


func _garden_distance(point: Vector2) -> float:
	var a := ((point - Vector2(80, -640)) / Vector2(335, 180)).length_squared()
	var b := ((point - Vector2(-1130, 440)) / Vector2(210, 260)).length_squared()
	var c := ((point - Vector2(1110, -740)) / Vector2(230, 170)).length_squared()
	return minf(a, minf(b, c))


func _noise(x: int, y: int) -> int:
	return posmod((x * 73856093) ^ (y * 19349663), 9973)
