extends CanvasLayer
## Chapter 1 completion medal popup (Qingxi Valley 2.0).
## Shown automatically when Chapter 1 main line closes. Emits `closed` when dismissed.

signal closed

var _advanced := false

@onready var medal_draw: Control = $Root/Panel/Margin/MainVBox/MedalHost/MedalDraw
@onready var title_label: Label = $Root/Panel/Margin/MainVBox/TitleLabel
@onready var desc_label: Label = $Root/Panel/Margin/MainVBox/DescLabel
@onready var gallery_label: Label = $Root/Panel/Margin/MainVBox/GalleryLabel
@onready var fragment_hint_label: Label = $Root/Panel/Margin/MainVBox/FragmentHintLabel
@onready var close_button: Button = $Root/Panel/Margin/MainVBox/CloseButton



func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 150
	QuestState.push_interaction_input_lock()
	_advanced = QuestState.is_chapter1_medal_advanced()
	medal_draw.set("advanced", _advanced)
	medal_draw.queue_redraw()
	title_label.text = "Valley Water Guardian"
	desc_label.text = "You helped the villagers of Qingxi Valley solve water-related difficulties and learned the importance of cherishing water resources."
	gallery_label.text = "Saved to the Path-of-Humanity Medal Hall"
	if _advanced:
		gallery_label.text += "  [Fully Explored]"
	var frag_count := QuestState.get_chapter1_fragment_count()
	fragment_hint_label.text = "Medal fragments: %d / 3" % frag_count
	_refresh_fragment_icons()
	close_button.pressed.connect(_on_close_pressed)


func _exit_tree() -> void:
	QuestState.pop_interaction_input_lock()


func _refresh_fragment_icons() -> void:
	$Root/Panel/Margin/MainVBox/FragmentBadge.queue_redraw()


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
