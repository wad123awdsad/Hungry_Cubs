extends VBoxContainer

signal back_requested

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	
	add_child(_make_label("Options", 24))
	
	add_child(_make_label("Volume", 20))
	var volume_slider := HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = Global.volume
	volume_slider.custom_minimum_size = Vector2(0, 40)
	volume_slider.value_changed.connect(_on_volume_changed)
	add_child(volume_slider)
	
	add_child(_make_label("Graphics", 20))
	add_child(_make_dropdown(Global.GRAPHICS_NAMES, Global.graphics, _on_graphics_selected))
	
	add_child(_make_label("Display mode", 20))
	add_child(_make_dropdown(Global.DISPLAY_NAMES, Global.display_mode, _on_display_selected))
	
	add_child(_make_button("Back", _on_back, 60, 20))
	
#Actions
func _on_back() -> void:
	back_requested.emit()
	
func _on_volume_changed(value: float) -> void:
	Global.volume = value
	Global.apply_settings()
	Global.save_settings()
	
func _on_graphics_selected(index: int) -> void:
	Global.graphics = index
	Global.apply_settings()
	Global.save_settings()
	
func _on_display_selected(index: int) -> void:
	Global.display_mode = index
	Global.apply_settings()
	Global.save_settings()
	
#Helpers
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
	
func _make_dropdown(items: Array, selected: int, callback: Callable) -> OptionButton:
	var dropdown := OptionButton.new()
	dropdown.custom_minimum_size = Vector2(0, 50)
	dropdown.add_theme_font_size_override("font_size", 22)
	for item in items:
		dropdown.add_item(item)
	dropdown.selected = selected
	dropdown.item_selected.connect(callback)
	return dropdown
