extends CanvasLayer
## Qingxi Valley 3.0: screen-center medal popup.
## Shows the full "Valley Water Guardian" medal (the user's three pie-slice
## images merged) when an easter-egg is finished. Slices that are collected
## are full-color; uncollected slices stay dimmed. Auto-fades out.

const LIFETIME := 5.5

const DIM := Color(0.45, 0.45, 0.5, 1.0)
const FULL := Color(1.0, 1.0, 1.0, 1.0)

## Tip line under the medal, set by QuestState before adding the popup.
@export var tip_text: String = ""

var _timer := 0.0
var _fading := false
var _alpha := 0.0

@onready var medal_ring: Control = $Root/Center/VBox/MedalRing
@onready var slice_stone: TextureRect = $Root/Center/VBox/MedalRing/SliceStone
@onready var slice_sign: TextureRect = $Root/Center/VBox/MedalRing/SliceSign
@onready var slice_minigame: TextureRect = $Root/Center/VBox/MedalRing/SliceMinigame
@onready var tip_label: Label = $Root/Center/VBox/TipLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 165
	tip_label.text = tip_text
	_refresh_slices()
	_fading = true
	_alpha = 0.0


func _process(delta: float) -> void:
	_refresh_slices()
	if _fading:
		_alpha = minf(_alpha + delta * 3.0, 1.0)
		medal_ring.modulate.a = _alpha
		tip_label.modulate.a = _alpha
		if _alpha >= 1.0:
			_fading = false
			_timer = 0.0
	else:
		_timer += delta
		if _timer >= LIFETIME:
			medal_ring.modulate.a = maxf(0.0, 1.0 - (_timer - LIFETIME) / 0.5)
			tip_label.modulate.a = medal_ring.modulate.a
			if _timer >= LIFETIME + 0.5:
				queue_free()


func _refresh_slices() -> void:
	if not is_inside_tree():
		return
	slice_stone.modulate = FULL if QuestState.fragment_stone else DIM
	slice_sign.modulate = FULL if QuestState.fragment_sign else DIM
	slice_minigame.modulate = FULL if QuestState.fragment_minigame else DIM
