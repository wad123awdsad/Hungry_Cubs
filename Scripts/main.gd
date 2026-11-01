extends Node2D

const MENU_SCENE := "res://menu.tscn"
const OptionsPage := preload("res://options_page.gd")
const DEN_NAMES := ["Simaple Hole", "Cozy Burrow", "Den", "Large Den", "Fox Palace"]
const DEN_CAPACITY := [2, 4, 7, 11, 16]
const DEN_COSTS := [0, 100, 600, 3000, 15000] # cost to reach level i
const BACKGROUND_TEXTURE := preload("res://assets/cave_carne.png")
const MEAT_TEXTURE := preload("res://assets/meat.png")
const MEAT_SIZE := 192

var food := 0.0
var claw_level := 0
var senses_level := 0
var cubs := 0
var den_level := 0
var mode := "casual"

var food_label: Label
var rate_label: Label
var den_label: Label
var cubs_label: Label
var hunt_button: TextureButton
var hunt_tween: Tween
var cub_button: Button
var den_button: Button
var claw_button: Button
var senses_button: Button

var pause_layer: CanvasLayer
var pause_page: VBoxContainer
var pause_options: VBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	mode = Global.mode
	_build_background()
	_build_ui()
	_build_pause_menu()
	_load_game()
	
	if not Global.slot_exists(Global.slot):
		_save_game()
		
	var timer := Timer.new()
	timer.wait_time = Global.AUTOSAVE_SECONDS
	timer.autostart = true
	timer.timeout.connect(_save_game)
	add_child(timer)
	
func _build_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	
	var background := TextureRect.new()
	background.texture = BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	layer.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
func _make_hunt_button() -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = MEAT_TEXTURE
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = Vector2(MEAT_SIZE, MEAT_SIZE)
	b.pivot_offset = Vector2(MEAT_SIZE / 2.0, MEAT_SIZE / 2.0)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = "Hunt!"
	b.pressed.connect(_on_hunt)
	return b
	
func _process(delta: float) -> void:
	if get_tree().paused:
		return
	food += passive_rate() * delta
	_refresh()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		if not get_tree().paused:
			_pause_game()
		elif pause_options.visible:
			_show_pause_page()
		else:
			_resume_game()
		get_viewport().set_input_as_handled()
		
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_game()
		
#Game formulas
func multiplier() -> float:
	return 1.0 + senses_level * 0.25
	
func click_value() -> float:
	return(1 + claw_level) * multiplier()
	
func cub_upkeep() -> float:
	if mode == "survival":
		return 0.3
	return 0.0
	
func passive_rate() -> float:
	return cubs * (0.5 * multiplier() - cub_upkeep())
	
func claw_cost() -> int:
	return int(10 * pow(1.5, claw_level))
	
func senses_cost() -> int:
	return int(50 * pow(1.8, senses_level))
	
func cub_cost() -> int:
	return int(15 * pow(1.25, cubs))
	
func den_is_max() -> bool:
	return den_level >= DEN_NAMES.size() - 1
	
#Actions
func _on_hunt() -> void:
	food += click_value()
	if hunt_tween:
		hunt_tween.kill()
	hunt_tween = create_tween()
	hunt_tween.tween_property(hunt_button, "scale", Vector2(0.9, 0.9), 0.05)
	hunt_tween.tween_property(hunt_button, "scale", Vector2.ONE, 0.1)

func _on_buy_cub() -> void:
	if cubs < DEN_CAPACITY[den_level] and food >= cub_cost():
		food -= cub_cost()
		cubs += 1
		
func _on_upgrade_den() -> void:
	if not den_is_max() and food >= DEN_COSTS[den_level + 1]:
		food -= DEN_COSTS[den_level + 1]
		den_level += 1
		
func _on_upgrade_claws() -> void:
	if food >= claw_cost():
		food -= claw_cost()
		claw_level += 1
		
func _on_upgrade_senses() -> void:
	if food >= senses_cost():
		food -= senses_cost()
		senses_level += 1
		
#Pause menu
func _pause_game() -> void:
	get_tree().paused = true
	_show_pause_page()
	pause_layer.visible = true
	
func _resume_game() -> void:
	get_tree().paused = false
	pause_layer.visible = false
	
func _show_pause_page() -> void:
	pause_page.visible = true
	pause_options.visible = false
	
func _show_pause_options() -> void:
	pause_page.visible = false
	pause_options.visible = true
	
func _on_back_to_menu() -> void:
	_save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
	
#User interface
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(layer)
	
	var ui := Control.new()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	#Center: the meat button, in the middle of the screen
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	hunt_button = _make_hunt_button()
	center.add_child(hunt_button)
	
	#Top: food and income
	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", 4)
	ui.add_child(top)
	
	food_label = _make_label("", 40)
	top.add_child(food_label)
	
	rate_label = _make_label("", 20)
	top.add_child(rate_label)
	
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 16)
	
	# Left: den info and upgrades
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.custom_minimum_size = Vector2(400, 0)
	ui.add_child(left)
	
	den_label = _make_label("", 22)
	left.add_child(den_label)
	
	cubs_label = _make_label("", 22)
	left.add_child(den_label)
	
	cub_button = _make_button("", _on_buy_cub, 50, 18)
	left.add_child(cub_button)
	
	den_button = _make_button("", _on_upgrade_den, 50, 18)
	left.add_child(den_button)
	
	claw_button = _make_button("", _on_upgrade_claws, 50, 18)
	left.add_child(claw_button)
	
	senses_button = _make_button("", _on_upgrade_senses, 50, 18)
	left.add_child(senses_button)
	
	left.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE, Control.PRESET_MODE_MINSIZE, 16)

func _build_pause_menu() -> void:
	pause_layer = CanvasLayer.new()
	pause_layer.layer = 10
	pause_layer.visible = false
	add_child(pause_layer)
	
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_layer.add_child(dim)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var center := CenterContainer.new()
	pause_layer.add_child(center)
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(420, 0)
	center.add_child(root)
	
	pause_page = VBoxContainer.new()
	pause_page.add_theme_constant_override("separation", 12)
	root.add_child(pause_page)
	
	pause_page.add_child(_make_label("Paused", 40))
	pause_page.add_child(_make_button("Resume", _resume_game, 70, 26))
	pause_page.add_child(_make_button("Options", _show_pause_options, 70, 26))
	pause_page.add_child(_make_button("Back to main menu", _on_back_to_menu, 70, 26))
	
	pause_options = OptionsPage.new()
	pause_options.visible = false
	root.add_child(pause_options)
	pause_options.connect("back_requested", _show_pause_page)
	
func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
	
func _make_button(text: String, callback: Callable, height: int, font_size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, height)
	b.add_theme_font_size_override("font_size", font_size)
	b.pressed.connect(callback)
	return b
	
func _fmt(n: float) -> String:
	if n >= 1000000.0:
		return "%.2fM" % (n / 1000000.0)
	if n >= 1000.0:
		return "%.1fK" % (n / 1000.0)
	return str(int(n))
	
func _refresh() -> void:
	food_label.text = "Food: " + _fmt(food)
	rate_label.text = "+%s / click  |  +%.1f / second" % [_fmt(click_value()), passive_rate()]
	
	den_label.text = "Den: %s  |  Mode: %s" % [DEN_NAMES[den_level], mode.capitalize()]
	cubs_label.text = "Fox cubs: %d / %d" % [cubs, DEN_CAPACITY[den_level]]
	
#feed a new cub
	if cubs >= DEN_CAPACITY[den_level]:
		cub_button.text = "Den is full (upgrade it)"
		cub_button.disabled = true
	else:
		cub_button.text = "Feed a new cub (%s food)" % _fmt(cub_cost())
		cub_button.disabled = food < cub_cost()
	
#Den upgrade
	if den_is_max():
		den_button.text = "Den is at max level"
		den_button.disabled = true
	else:
		var cost: int = DEN_COSTS[den_level + 1]
		den_button.text = "Upgrade den: %s (%s)" % [DEN_NAMES[den_level + 1], _fmt(cost)]
		den_button.disabled = food < cost
	
#Fox upgrades
	claw_button.text = "Sharp Claw 1v. %d (%s)  +1 / click" % [claw_level, _fmt(claw_cost())]
	claw_button.disabled = food < claw_cost()

	senses_button.text = "keen senses 1v. %d (%s)  +25%% food" % [senses_level, _fmt(senses_cost())]
	senses_button.disabled = food < senses_cost()
	
#Saving
func _save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "mode", mode)
	cfg.set_value("game", "food", food)
	cfg.set_value("game", "claw_level", claw_level)
	cfg.set_value("game", "senses_level", senses_level)
	cfg.set_value("game", "cubs", cubs)
	cfg.set_value("game", "den_level", den_level)
	cfg.save(Global.slot_path(Global.slot))
	
func _load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(Global.slot_path(Global.slot)) != OK:
		return
	mode = cfg.get_value("game", "mode", mode)
	food = cfg.get_value("game", "food", 0.0)
	claw_level = cfg.get_value("game", "claw_level", 0)
	senses_level = cfg.get_value("game", "senses_level", 0)
	cubs = cfg.get_value("game", "cubs", 0)
	den_level = cfg.get_value("game", "den_level", 0)
