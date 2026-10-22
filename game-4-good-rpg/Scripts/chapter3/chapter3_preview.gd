extends "res://Steven/main/story_guide_panel.gd"
## Optional F6 preview only. The real Chapter 3 scene does not skip earlier chapters.


func _ready() -> void:
	# Objective lookup and any preview save should use the real map's path.
	scene_file_path = "res://Scenes/chapter_3.tscn"
	QuestState.chapter0_traveler_done = true
	QuestState.chapter0_family_done = true
	QuestState.chapter0_friend_done = true
	QuestState.chapter1_summary_shown = true
	QuestState.chapter2_summary_shown = true
	super._ready()
