extends StaticBody2D
## Decorative villager that idles around the stone and occasionally
## "discusses" water-saving ideas via a speech bubble.
## No interaction: the player can NOT talk to these villagers.

const TOPICS: Array[String] = [
	"I think collecting rainwater is a good idea.",
	"The canal should be fixed soon.",
	"We should share water fairly in dry days.",
	"Planting more trees keeps the stream clean.",
	"Small water-saving habits help a lot.",
	"Reusing water for plants is smart.",
]

@onready var bubble: Label = $Bubble
@onready var bubble_timer: Timer = $BubbleTimer

var _index := 0


func _ready() -> void:
	bubble.visible = false
	bubble_timer.timeout.connect(_on_bubble_timer_timeout)
	bubble_timer.start()


func _on_bubble_timer_timeout() -> void:
	if bubble.visible:
		bubble.visible = false
		bubble_timer.start(2.5)
		return
	bubble.text = TOPICS[_index % TOPICS.size()]
	_index += 1
	bubble.visible = true
	bubble_timer.start(3.0)
