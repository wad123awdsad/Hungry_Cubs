extends Node

const SETTINGS_PATH := "user://settings.cfg"
const SLOT_COUNT := 3
const AUTOSAVE_SECONDS := 300.0 # 5 minutes
const GRAPHICS_NAMES := ["Low", "Medium", "High"]
const DISPLAY_NAMES := ["Windowed", "Window Fullscreen", "Fullscreen"]

var slot := 1
var mode := "casual"
var volume := 1.0
var graphics := 2
var display_mode := 0

func _ready() -> void:
	_setup_keybinds()
	load_settings()
	apply_settings()
	
#Keybinds
func _setup_keybinds() -> void:
	_add_key_action("pause_game", KEY_ESCAPE)
	_add_key_action("delete_slot", KEY_X)
	
func _add_key_action(action: String, keycode: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event := InputEventKey.new()
	event.keycode = keycode
	InputMap.action_add_event(action, event)
	
#Save slots
func slot_path(index: int) -> String:
	return "user://hungry_cubs_slot%d.cfg" % index
	
func slot_exists(index: int) -> bool:
	return FileAccess.file_exists(slot_path(index))
	
func delete_slot(index: int) -> void:
	if slot_exists(index):
		DirAccess.remove_absolute(slot_path(index))
		
func slot_info(index: int) -> String:
	if not slot_exists(index):
		return "Slot %d - Empty" % index
	var cfg := ConfigFile.new()
	cfg.load(slot_path(index))
	var slot_mode: String = cfg.get_value("game", "mode", "casual")
	var cubs: int = cfg.get_value("game", "cubs", 0)
	return "Slot %d - %s -%d cubs" % [index, slot_mode.capitalize(), cubs]
		
#Settings
func apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	_apply_display_mode()
	_apply_graphics()
	
func _apply_display_mode() -> void:
	match display_mode:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			
func _apply_graphics() -> void:
	var viewport := get_viewport()
	match graphics:
		0:
			viewport.msaa_2d = Viewport.MSAA_DISABLED
		1:
			viewport.msaa_2d = Viewport.MSAA_2X
		2:
			viewport.msaa_2d = Viewport.MSAA_4X
			
func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "volume", volume)
	cfg.set_value("settings", "graphics", graphics)
	cfg.set_value("settings", "display_mode", display_mode)
	cfg.save(SETTINGS_PATH)
	
func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	volume = cfg.get_value("settings", "volume", 1.0)
	graphics = cfg.get_value("settings", "graphics", 2)
	display_mode = cfg.get_value("settings", "display_mode", 0)
