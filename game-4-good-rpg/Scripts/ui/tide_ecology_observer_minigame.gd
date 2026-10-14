extends CanvasLayer
## Optional Chapter 2 activity: identify the four stages of a tide cycle.

signal completed

const STAGES: Array[Dictionary] = [
	{
		"title": "Stage 1 of 4",
		"question": "The water is at its lowest and tide pools are exposed. Which stage is this?",
		"answers": ["Low tide", "High tide", "Rising tide"],
		"correct": 0,
		"fact": "Low tide exposes the intertidal zone. Observe its wildlife without removing it.",
	},
	{
		"title": "Stage 2 of 4",
		"question": "Water moves back toward the shore and fish return to feed. Which stage follows?",
		"answers": ["Falling tide", "Rising tide", "Low tide"],
		"correct": 1,
		"fact": "During a rising tide, safe paths can disappear quickly, so fishers watch the waterline.",
	},
	{
		"title": "Stage 3 of 4",
		"question": "The water reaches its highest point and covers most shoreline rocks. What is it?",
		"answers": ["High tide", "Low tide", "Falling tide"],
		"correct": 0,
		"fact": "High tide gives many coastal animals access to food and shelter.",
	},
	{
		"title": "Stage 4 of 4",
		"question": "Water retreats from the shore and flows back to sea. Which stage completes the cycle?",
		"answers": ["Rising tide", "High tide", "Falling tide"],
		"correct": 2,
		"fact": "A falling tide reveals the shore again and completes the repeating cycle.",
	},
]

var _stage_index := 0
var _finished := false

@onready var stage_label: Label = $Root/Panel/Margin/MainVBox/StageLabel
@onready var question_label: Label = $Root/Panel/Margin/MainVBox/QuestionLabel
@onready var answer_buttons: Array[Button] = [
	$Root/Panel/Margin/MainVBox/Answers/Answer1,
	$Root/Panel/Margin/MainVBox/Answers/Answer2,
	$Root/Panel/Margin/MainVBox/Answers/Answer3,
]
@onready var feedback_label: Label = $Root/Panel/Margin/MainVBox/FeedbackLabel
@onready var next_button: Button = $Root/Panel/Margin/MainVBox/ActionRow/NextButton
@onready var close_button: Button = $Root/Panel/Margin/MainVBox/ActionRow/CloseButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 130
	QuestState.push_interaction_input_lock()
	for index in answer_buttons.size():
		answer_buttons[index].pressed.connect(_on_answer_pressed.bind(index))
	next_button.pressed.connect(_on_next_pressed)
	close_button.pressed.connect(_on_close_pressed)
	_show_stage()


func _exit_tree() -> void:
	QuestState.pop_interaction_input_lock()


func _show_stage() -> void:
	var stage: Dictionary = STAGES[_stage_index]
	stage_label.text = stage.title
	question_label.text = stage.question
	feedback_label.text = "Choose the best answer."
	next_button.visible = false
	close_button.visible = false
	for index in answer_buttons.size():
		answer_buttons[index].text = stage.answers[index]
		answer_buttons[index].disabled = false


func _on_answer_pressed(answer_index: int) -> void:
	var stage: Dictionary = STAGES[_stage_index]
	if answer_index != int(stage.correct):
		feedback_label.text = "Not quite. Watch how the water is moving and try again."
		return
	feedback_label.text = "Correct! %s" % stage.fact
	for button in answer_buttons:
		button.disabled = true
	if _stage_index == STAGES.size() - 1:
		_finished = true
		close_button.visible = true
	else:
		next_button.visible = true


func _on_next_pressed() -> void:
	_stage_index += 1
	_show_stage()


func _on_close_pressed() -> void:
	QuestState.mark_chapter2_tide_observation_done()
	completed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and not _finished:
		queue_free()
