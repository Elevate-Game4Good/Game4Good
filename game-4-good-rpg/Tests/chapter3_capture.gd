extends SceneTree
## Optional visual review. Requires a real graphics display (not --headless).

const Layout = preload("res://Scripts/chapter3/chapter3_layout.gd")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var state := root.get_node("QuestState")
	state.load_from_dict({})
	state.chapter0_traveler_done = true
	state.chapter0_family_done = true
	state.chapter0_friend_done = true
	state.chapter1_summary_shown = true
	state.chapter2_summary_shown = true
	change_scene_to_file("res://Scenes/chapter_3.tscn")
	await scene_changed
	var town := current_scene
	await process_frame
	town.set_process(false)
	town.is_guide_open = false
	town.get_node("StoryGuideLayer").visible = false
	paused = false
	town.get_node("Player").set_physics_process(false)
	town.get_node("Player/Camera2D").enabled = false
	var camera := Camera2D.new()
	camera.position = Layout.ORIGIN
	camera.zoom = Vector2.ONE * 0.37
	town.add_child(camera)
	camera.make_current()
	var output := "user://chapter3_previews"
	if not OS.get_cmdline_user_args().is_empty():
		output = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	for phase in range(4):
		for person in ["advaita", "sarina", "aurora"]:
			state.set("chapter3_quest1_%s_done" % person, phase > 0)
			state.set("chapter3_quest2_%s_done" % person, phase > 0)
		state.chapter3_quest2_home_visits_done = phase > 0
		state.chapter3_quest3_festival_setup_done = phase >= 1
		state.chapter3_quest4_town_dialogue_done = phase >= 2
		state.chapter3_quest5_celebration_done = phase >= 3
		town.get_node("Environment")._sync_phase()
		root.get_node("QuestLogUI")._refresh()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("chapter3_phase_%d.png" % phase))
	camera.zoom = Vector2.ONE * 0.85
	camera.position = Layout.ORIGIN + Vector2(-440, -165)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("chapter3_stage_detail.png"))
	var music := town.get_node("MusicPlayer") as AudioStreamPlayer
	music.stop()
	music.stream = null
	town.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	await create_timer(0.2).timeout
	print("Chapter 3 previews: ", output)
	quit()
