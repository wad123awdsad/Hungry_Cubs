extends Node2D

const GAME_SCENE := "res://main.tscn"
const OptionsPage := preload("res://options_page.gd")

var main_page: VBoxContainer
var slots_page: VBoxContainer
var mode_page: VBoxContainer
var options_page: VBoxContainer
var current_page: VBoxContainer

var slot_buttons: Array[Button] = []
var delete_buttons: Array[Button] = []
var selected_slot := 1
var slot_to_delete := 0
var confirm_dialog: ConfirmationDialog

func _ready() -> void:
	selected_slot = Global.slot
	_build_ui()
	_show_page(main_page)
	
func _input(event: InputEvent) -> void:
	if confirm_dialog.visible:
		return
		
	if event.is_action_pressed("ui_cancel"):
		_go_back()
		get_viewport().set_input_as_handled()
		return
		
	if current_page != slots_page:
		return
		
	if event.is_action_pressed("ui_accept"):
		_open_selected_slot()
		get_viewport().set_input_as_handled()
	elif  event.is_action_pressed("delete_slot"):
		_ask_delete(selected_slot)
		get_viewport().set_input_as_handled()
	elif  event.is_action_pressed("ui_down"):
		_select_slot(clampi(selected_slot + 1, 1, Global.SLOT_COUNT))
		get_viewport().set_input_as_handled()
	elif  event.is_action_pressed("ui_up"):
		_select_slot(clampi(selected_slot - 1, 1, Global.SLOT_COUNT))
		get_viewport().set_input_as_handled()
		
#Navigation
func _show_page(page: VBoxContainer) -> void:
	current_page = page
	for p in [main_page, slots_page, mode_page, options_page]:
		p.visible = (p == page)
	if page == slots_page:
		_refresh_slots()
		
func _go_back() -> void:
	if current_page == mode_page:
		_show_page(slots_page)
	elif current_page == slots_page or current_page == options_page:
		_show_page(main_page)
		
func _refresh_slots() -> void:
	for i in range(slot_buttons.size()):
		var index := i + 1
		var prefix := ">" if index == selected_slot else ""
		slot_buttons[i].text = prefix + Global.slot_info(index)
		slot_buttons[i].modulate = Color(1.0, 0.85, 0.4) if index == selected_slot else Color.WHITE
		delete_buttons[i].disabled = not Global.slot_exists(index)
		
#Actions
func _select_slot(index:int) -> void:
	selected_slot = index
	_refresh_slots()
	
func _open_selected_slot() -> void:
	Global.slot = selected_slot
	if Global.slot_exists(selected_slot):
		_start_game()
	else:
		_show_page(mode_page)
		
func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.double_click and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		_select_slot(index)
		_open_selected_slot()
		
func _ask_delete(index: int) -> void:
	if not Global.slot_exists(index):
		return
	_select_slot(index)
	slot_to_delete = index
	confirm_dialog.dialog_text = "Delete slot %d? This cannot be undone." % index
	confirm_dialog.popup_centered()
	
func _on_delete_confirmed() -> void:
	Global.delete_slot(slot_to_delete)
	_refresh_slots()
	
func _on_mode_chosen(chosen_mode: String) -> void:
	Global.mode = chosen_mode
	_start_game()
	
func _start_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)
	
func _on_exit() -> void:
	get_tree().quit()
	
#User interface
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	
	var center := CenterContainer.new()
	layer.add_child(center)
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(420, 0)
	root.add_theme_constant_override("separation", 16)
	center.add_child(root)
	
	root.add_child(_make_label("Hungry Cubs", 48))
	
	main_page = _make_page(root)
	slots_page = _make_page(root)
	mode_page = _make_page(root)
	
	var options: VBoxContainer = OptionsPage.new()
	root.add_child(options)
	options.connect("back_requested", _show_page.bind(main_page))
	options_page = options
	
	_build_main_page()
	_build_slots_page()
	_build_mode_page()
	
	confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "Delete save"
	confirm_dialog.ok_button_text = "Delete"
	confirm_dialog.confirmed.connect(_on_delete_confirmed)
	add_child(confirm_dialog)
	
func _build_main_page() -> void:
	main_page.add_child(_make_button("Play", _show_page.bind(slots_page), 80, 30))
	main_page.add_child(_make_button("Options", _show_page.bind(options_page), 80, 30))
	main_page.add_child(_make_button("Exit", _on_exit, 80, 30))
	
func _build_slots_page() -> void:
	slots_page.add_child(_make_label("Select a save slot", 24))
	
	for i in range(1, Global.SLOT_COUNT + 1):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		slots_page.add_child(row)
		
		var slot_button := _make_button("", _select_slot.bind(i), 70, 20)
		slot_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_button.focus_mode = Control.FOCUS_NONE
		slot_button.gui_input.connect(_on_slot_gui_input.bind(i))
		row.add_child(slot_button)
		slot_buttons.append(slot_button)
		
		var delete_button := _make_button("Delete", _ask_delete.bind(i), 70, 20)
		delete_button.focus_mode = Control.FOCUS_NONE
		row.add_child(delete_button)
		delete_buttons.append(delete_button)
		
	var hint := _make_label("Enter / double click: oppen   x: delete   Esc: back", 16)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slots_page.add_child(_make_button("Back", _show_page.bind(main_page), 60, 20))
	
func _build_mode_page() -> void:
	mode_page.add_child(_make_label("Choose a game mode", 24))
	mode_page.add_child(_make_button("Casual\nRelax, no pressure", _on_mode_chosen.bind("casual"), 90, 22))
	mode_page.add_child(_make_button("Survival\nCubs eat food, so feed them well", _on_mode_chosen.bind("survival"), 90, 22))
	mode_page.add_child(_make_button("Back", _show_page.bind(slots_page), 60, 20))
	
func _make_page(parent: Node) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	parent.add_child(page)
	return page
	
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
	
