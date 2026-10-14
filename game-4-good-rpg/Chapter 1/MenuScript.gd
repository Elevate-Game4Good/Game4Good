extends CanvasLayer
const PlayerScript = preload("res://Scripts/PlayerScript.gd")

@onready var settings_button = get_node_or_null("SettingsButton")
@onready var settings_menu = $SettingsMenu
@onready var volume_slider = $SettingsMenu/VolumeSlider
@onready var brightness_slider: HSlider = get_node_or_null("SettingsMenu/BrightnessSlider")
@onready var save_game_button: Button = get_node_or_null("SettingsMenu/SaveGame")
@onready var save_and_exit_button: Button = get_node_or_null("SettingsMenu/SaveAndExit")
@onready var save_status_label: Label = get_node_or_null("SettingsMenu/SaveStatus")
var music_player: AudioStreamPlayer
var player: PlayerScript
@onready var sfx_slider = get_node_or_null("SettingsMenu/SFXSlider")
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

var menu_open := false
var _settings_input_locked := false
var _brightness_overlay: ColorRect
var _brightness_value := 100.0

func _ready():
	add_to_group("settings_menu_layer")
	process_mode = Node.PROCESS_MODE_ALWAYS
	settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	if settings_button and not settings_button.pressed.is_connected(_on_settings_button_pressed):
		settings_button.pressed.connect(_on_settings_button_pressed)
	music_player = get_parent().get_node_or_null("MusicPlayer") as AudioStreamPlayer
	player = _resolve_player()
	_update_game_save_controls()
	# Start with menu hidden
	settings_menu.visible = false
	_setup_sfx_slider()
	load_settings()
	load_settings()
	_load_brightness()
	call_deferred("_create_brightness_overlay")
	# Optional: set default volume
	_on_volume_slider_value_changed(volume_slider.value)

func _create_brightness_overlay() -> void:
	# Add a full-screen dim overlay directly to THIS Settings CanvasLayer (self).
	# Reusing the existing CanvasLayer guarantees correct full-screen coverage
	# under all scenes and stretch settings (the settings UI already scales correctly).
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.color = Color(0, 0, 0, 0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	move_child(rect, 0)  # draw behind SettingsButton / SettingsMenu
	_brightness_overlay = rect
	_apply_brightness(_brightness_value)

func _apply_brightness(value: float) -> void:
	_brightness_value = clampf(value, 0.0, 100.0)
	if _brightness_overlay:
		_brightness_overlay.color = Color(0, 0, 0, 1.0 - _brightness_value / 100.0)

func _on_brightness_slider_value_changed(value: float) -> void:
	_apply_brightness(value)

func _load_brightness() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var b: float = config.get_value("video", "brightness", 100.0)
		if brightness_slider:
			brightness_slider.value = b
		_apply_brightness(b)

func _set_settings_menu_open(open: bool) -> void:
	menu_open = open
	settings_menu.visible = open
	get_tree().paused = open
	if open:
		if save_status_label:
			save_status_label.text = ""
		if not _settings_input_locked:
			QuestState.push_interaction_input_lock()
			_settings_input_locked = true
	elif _settings_input_locked:
		QuestState.pop_interaction_input_lock()
		_settings_input_locked = false

# 🔘 When settings button is pressed
func _on_settings_button_pressed():
	_set_settings_menu_open(not menu_open)

# 🔊 When volume slider changes
func _set_bus_volume_from_slider(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	if value <= -40:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, value)

func _on_volume_slider_value_changed(value):
	_set_bus_volume_from_slider(MUSIC_BUS, value)

func _setup_sfx_slider() -> void:
	if sfx_slider == null:
		return
	# The duplicated slider may still be wired to the main volume handler, so clear that first.
	for c in sfx_slider.value_changed.get_connections():
		sfx_slider.value_changed.disconnect(c.callable)
	sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)
	_on_sfx_slider_value_changed(sfx_slider.value)

func _on_sfx_slider_value_changed(value: float) -> void:
	_set_bus_volume_from_slider(SFX_BUS, value)

func _on_close_pressed():
	_set_settings_menu_open(false)


func _update_game_save_controls() -> void:
	var is_gameplay_scene := player != null
	if save_game_button:
		save_game_button.visible = is_gameplay_scene
	if save_and_exit_button:
		save_and_exit_button.visible = is_gameplay_scene
	if save_status_label:
		save_status_label.visible = is_gameplay_scene
		save_status_label.text = ""


func _on_save_game_pressed() -> void:
	var success := SaveManager.save_game()
	if success:
		_set_save_status("Game saved successfully.", true)
	else:
		_set_save_status("Save failed. Please try again.", false)


func _on_save_and_exit_pressed() -> void:
	var success := SaveManager.save_game()
	if not success:
		_set_save_status("Save failed. The game was not closed.", false)
		return
	_set_save_status("Game saved. Exiting...", true)
	if _settings_input_locked:
		QuestState.pop_interaction_input_lock()
		_settings_input_locked = false
	menu_open = false
	get_tree().paused = false
	get_tree().quit()


func _set_save_status(message: String, success: bool) -> void:
	if save_status_label == null:
		return
	save_status_label.text = message
	save_status_label.add_theme_color_override(
		&"font_color",
		Color(0.72, 0.95, 0.72) if success else Color(1.0, 0.55, 0.55)
	)


func _on_change_skin_pressed() -> void:
	if player:
		player.cycle_skin()
		player.save_current_skin()

func _on_save_pressed() -> void:
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("audio", "volume", volume_slider.value)
	if sfx_slider:
		config.set_value("audio", "sfx_volume", sfx_slider.value)
	if brightness_slider:
		config.set_value("video", "brightness", brightness_slider.value)
	if player:
		config.set_value("player", "skin", player.current_skin_index)
	config.save("user://settings.cfg")
	_set_settings_menu_open(false)
	push_warning('Settings saved.')

func load_settings():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		volume_slider.value = config.get_value("audio", "volume", 0)
		if sfx_slider:
			sfx_slider.value = config.get_value("audio", "sfx_volume", sfx_slider.value)

func _resolve_player() -> PlayerScript:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	var found: PlayerScript = scene.get_node_or_null("Player") as PlayerScript
	if found == null:
		found = scene.get_node_or_null("CharacterBody2D") as PlayerScript
	if found == null:
		found = get_tree().get_first_node_in_group("player") as PlayerScript
	return found
