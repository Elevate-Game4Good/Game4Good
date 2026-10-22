extends "res://helpers/actionable.gd"
## The crew prepares the venue; the council opens the festival at the fountain.


func _resolve_dialogue_start() -> String:
	if not _is_chapter3_unlocked():
		return "chapter3_locked_finish_chapter2"
	if not QuestState.is_chapter3_quest1_complete():
		return "chapter3_locked_finish_quest1"
	if not QuestState.is_chapter3_quest2_complete():
		return "chapter3_locked_finish_quest2"
	if not QuestState.chapter3_quest3_festival_setup_done:
		return "chapter3_locked_finish_quest3"
	if not QuestState.chapter3_quest4_town_dialogue_done:
		return "villagers_ch3_festival_setup_start"
	return "star_moon_council_q4_repeat"
