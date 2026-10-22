extends SceneTree
## Run with an isolated user directory: this integration test saves and reloads.
## godot --headless --path game-4-good-rpg --script res://Tests/chapter3_smoke.gd

const Layout = preload("res://Scripts/chapter3/chapter3_layout.gd")
const MAP := "res://Scenes/chapter_3.tscn"
var _checks := 0
var _failures := 0
var _state: Node
var _scene: Node
var _marker: Node
var _dialogue: Resource


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL: ", message)


func _run() -> void:
	_state = root.get_node("QuestState")
	_marker = root.get_node("QuestMarkerManager")
	_dialogue = load("res://dialogue.dialogue")
	_state.load_from_dict({})
	_state.chapter0_traveler_done = true
	_state.chapter0_family_done = true
	_state.chapter0_friend_done = true
	_state.chapter1_summary_shown = true
	_state.chapter2_summary_shown = true
	_state.chapter3_description_shown = true
	_check(change_scene_to_file(MAP) == OK, "Chapter 3 loads")
	await scene_changed
	_scene = current_scene
	await process_frame
	await physics_frame
	_close_guide()
	_check(_scene.active_chapter_id == 3, "dedicated map selects Chapter 3")
	_check(_scene.CHAPTER_3_SCENE == MAP, "Chapter 2 transition points to dedicated map")
	_check(_scene.get_node("Player").has_method("cycle_skin"), "player retains outfits and save controls")
	_check(_scene.get_node("Environment").festival_phase == 0, "initial survey phase")
	_check(not root.get_node("Inventory").visible, "inventory starts closed")
	_check(_marker._current_targets().size() == 3, "three first-visit objectives")
	_check(_scene.get_node("Environment").get_node_or_null("CouncilHouse") != null, "independent council building")
	_check(_scene.get_node("Environment").get_node("FestivalCrowd").visible == false, "crowd hidden before festival")
	_check(_all_objectives_reachable(), "all households, council and crew reachable from entrance")
	_check(_blocked(Vector2(-1040, -280)), "pond blocks walking")
	_check(_blocked(Layout.COUNCIL + Vector2(0, -35)), "building footprint blocks walking")
	_check(_blocked(Vector2(Layout.BOUNDS.end.x + 10, 0)), "town boundary blocks walking")
	# Run real compiled dialogue lines, including QuestState mutations at the end.
	for name in ["Advaita", "Sarina", "Aurora"]:
		var actor := _scene.get_node(name)
		_check(actor.get_node_or_null("PlaceholderBody") == null, name + " has a real sprite")
		var title: String = actor.get_node("Actionable2")._resolve_dialogue_start()
		_check(title.ends_with("_ch3_start"), name + " resolves first visit")
		await _play_dialogue(title)
		if name == "Advaita":
			_check(_marker._current_targets().size() == 2, "finished household arrow disappears")
			_check(root.get_node("QuestLogUI")._progress_for(["Advaita", "Sarina", "Aurora"], {"Advaita": "chapter3_quest1_advaita_done", "Sarina": "chapter3_quest1_sarina_done", "Aurora": "chapter3_quest1_aurora_done"}) == "1 / 3 done", "Chapter 3 progress uses its own flags")
	_check(_state.is_chapter3_quest1_complete(), "all first visits complete")
	_check(_marker._current_targets().size() == 3, "quest 2 returns to the three households")
	for name in ["Aurora", "Advaita", "Sarina"]:
		var title: String = _scene.get_node(name).get_node("Actionable2")._resolve_dialogue_start()
		_check(title.ends_with("_ch3_q2_collect_needs_start"), name + " resolves needs collection")
		await _play_dialogue(title)
	_check(_state.chapter3_quest2_home_visits_done, "needs collection complete")
	_check(_marker._current_targets() == ["StarMoonCouncilGroup"], "quest 3 points to council")
	await _play_dialogue(_scene.get_node("StarMoonCouncilGroup/Actionable2")._resolve_dialogue_start())
	_scene.get_node("Environment")._sync_phase()
	_check(_state.chapter3_quest3_festival_setup_done, "council agreement complete")
	_check(_scene.get_node("Environment").festival_phase == 1, "agreement starts preparation visuals")
	_check(_scene.get_node("StarMoonCouncilGroup/Actionable2")._resolve_dialogue_start() == "star_moon_council_q4_repeat", "council does not bypass preparation crew")
	_check(_marker._current_targets() == ["MattKaiVillagers"], "quest 4 points to preparation crew")
	var preparation: String = _scene.get_node("MattKaiVillagers/Actionable2")._resolve_dialogue_start()
	_check(preparation == "villagers_ch3_festival_setup_start", "crew uses Chapter 3 dialogue")
	await _play_dialogue(preparation)
	_scene.get_node("Environment")._sync_phase()
	_check(_scene.get_node("Environment").festival_phase == 2, "preparation completes venue")
	_check(_scene.get_node("MattKaiVillagers/Actionable2")._resolve_dialogue_start() == "star_moon_council_q4_repeat", "crew does not bypass the festival opening")
	_check(_marker._current_targets() == ["StarMoonCouncilGroup"], "quest 5 has an opening objective")
	_check(_scene.get_node("StarMoonCouncilGroup").global_position.is_equal_approx(Layout.ORIGIN + Layout.CELEBRATION), "council gathers at fountain for opening")
	await _play_dialogue(_scene.get_node("StarMoonCouncilGroup/Actionable2")._resolve_dialogue_start())
	_scene.get_node("Environment")._sync_phase()
	_check(_state.is_chapter3_complete(), "all five quests complete through real dialogue")
	_check(_scene.get_node("Environment").festival_phase == 3, "celebration visuals activate")
	_check(_scene.get_node("Environment/FestivalCrowd").visible, "festival crowd appears")
	_check(_marker._current_targets().is_empty(), "finished chapter clears arrows")
	_marker._process(0)
	_check(not _marker.get_node("QuestMarkerLayer/Markers").visible, "last drawn arrow is hidden after completion")
	# Actual JSON save/load and scene reload: no custom map state is required.
	var saved_position := Layout.ORIGIN + Vector2(220, 510)
	_scene.get_node("Player").global_position = saved_position
	var saver := root.get_node("SaveManager")
	_check(saver.save_game(), "save succeeds")
	_state.chapter3_quest5_celebration_done = false
	_check(saver.load_game(), "load succeeds")
	_check(saver.get_pending_scene_path() == MAP, "save retains dedicated map path")
	var legacy_save: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://savegame.json"))
	legacy_save["scene_path"] = "res://Steven/main/Main.tscn"
	var legacy_file := FileAccess.open("user://savegame.json", FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(legacy_save))
	legacy_file.close()
	_check(saver.load_game(), "legacy Chapter 3 save loads")
	_check(saver.get_pending_scene_path() == MAP, "legacy temporary scene migrates to the dedicated map")
	_check(saver.save_game(), "migrated save retains the current canonical map")
	_stop_music()
	_check(change_scene_to_file(MAP) == OK, "saved map reloads")
	await scene_changed
	_scene = current_scene
	await process_frame
	await process_frame
	await physics_frame
	_close_guide()
	_check(_scene.get_node("Player").global_position.is_equal_approx(saved_position), "saved player position restores")
	_check(_scene.get_node("Environment").festival_phase == 3, "festival restores from saved quest flags")
	_check(_scene.get_node("Environment/FestivalCrowd").visible, "saved celebration crowd restores")
	# The actual L key goes through FadeTransition and restores the saved position.
	_scene.get_node("Player").global_position = Layout.ORIGIN + Vector2(-220, 510)
	var load_key := InputEventKey.new()
	load_key.pressed = true
	load_key.physical_keycode = KEY_L
	load_key.keycode = KEY_L
	_check(load_key.is_action_pressed("load_game"), "L is bound to loading")
	_stop_music()
	_scene.get_node("Player")._unhandled_input(load_key)
	await scene_changed
	_scene = current_scene
	await process_frame
	await process_frame
	_close_guide()
	await create_timer(0.6).timeout
	_check(_scene.get_node("Player").global_position.is_equal_approx(saved_position), "L key restores saved map and player position")
	_check(not root.get_node("FadeTransition").is_transitioning, "fade completes while a chapter guide pauses the map")
	# Old saves inside the new fountain footprint are migrated to a safe entrance.
	_scene.get_node("Player").global_position = Layout.ORIGIN + Layout.FOUNTAIN
	await _scene.get_node("Environment")._restore_player_safely()
	_check(_scene.get_node("Player").global_position.is_equal_approx(Layout.ORIGIN + Layout.SPAWN), "blocked legacy save is relocated safely")
	_stop_music()
	_state.load_from_dict({})
	_check(change_scene_to_file("res://Scenes/chapter3/chapter3_preview.tscn") == OK, "optional preview scene loads")
	await scene_changed
	_scene = current_scene
	await process_frame
	await process_frame
	_close_guide()
	_check(_scene.scene_file_path == MAP, "preview uses canonical objective and save path")
	_check(_marker._current_targets().size() == 3, "preview shows real chapter objectives")
	_check(_scene.get_node("Advaita/Actionable2")._resolve_dialogue_start() == "advaita_ch3_start", "preview temporarily unlocks the earlier chapters")
	_stop_music()
	_scene.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.1).timeout
	print("CHAPTER3_CHECKS: ", _checks, " / FAILURES: ", _failures)
	quit(0 if _failures == 0 else 1)


func _close_guide() -> void:
	_scene.set_process(false)
	_scene.is_guide_open = false
	_scene.get_node("StoryGuideLayer").visible = false
	paused = false
	_scene.get_node("Player").set_physics_process(false)


func _play_dialogue(title: String) -> void:
	_check(_dialogue.titles.has(title), "compiled dialogue exists: " + title)
	var line = await _dialogue.get_next_dialogue_line(title)
	var count := 0
	while line != null and count < 40:
		count += 1
		var next_id: String = line.next_id
		if not line.responses.is_empty():
			next_id = line.responses[0].next_id
		line = await _dialogue.get_next_dialogue_line(next_id)
	_check(count < 40, "dialogue terminates: " + title)


func _blocked(local_point: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = Layout.ORIGIN + local_point
	query.collision_mask = 1
	query.exclude = [_scene.get_node("Player").get_rid()]
	return not root.world_2d.direct_space_state.intersect_point(query, 1).is_empty()


func _all_objectives_reachable() -> bool:
	var start := Vector2i(0, 11)
	var visited := {start: true}
	var queue: Array[Vector2i] = [start]
	var cursor := 0
	while cursor < queue.size():
		var cell: Vector2i = queue[cursor]
		cursor += 1
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + direction
			if visited.has(next) or absi(next.x) > 23 or absi(next.y) > 16:
				continue
			var point := Vector2(next) * 60.0
			if not _blocked(point):
				visited[next] = true
				queue.append(next)
	for name in ["Advaita", "Sarina", "Aurora", "StarMoonCouncilGroup", "MattKaiVillagers"]:
		var at: Vector2 = _scene.get_node(name).global_position - Layout.ORIGIN
		var reachable := false
		for cell in visited:
			if (Vector2(cell) * 60.0).distance_to(at) < 110:
				reachable = true
				break
		if not reachable:
			return false
	return true


func _stop_music() -> void:
	var music := _scene.get_node_or_null("MusicPlayer") as AudioStreamPlayer
	if music != null:
		music.stop()
		music.stream = null
