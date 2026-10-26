extends Control

const FillBar := preload("res://scripts/ui/HudFillBar.gd")
const ASSETS := "res://assets/ui/pixel_simple_v1/"

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("101321")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var title := Label.new()
	title.text = "TopHUD · Assets modulares"
	column.add_child(title)
	var preview := TextureRect.new()
	preview.texture = load(ASSETS + "frames/hud_frame.png")
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(preview)
	_add_bar(column, "Experiencia", "fill_xp.png", 100)
	_add_bar(column, "Energía", "fill_energy.png", 25)

func _add_bar(parent: Control, title: String, fill_file: String, maximum: int) -> void:
	var label := Label.new()
	parent.add_child(label)
	var bar := FillBar.new()
	bar.custom_minimum_size = Vector2(0, 32)
	bar.track_texture = load(ASSETS + "bars/bar_track.png")
	bar.fill_texture = load(ASSETS + "bars/" + fill_file)
	parent.add_child(bar)
	var slider := HSlider.new()
	slider.max_value = maximum
	slider.step = 1
	parent.add_child(slider)
	var update := func(value: float):
		bar.set_amount(value, maximum)
		label.text = "%s: %d/%d · %.0f%%" % [title, int(value), maximum, bar.ratio * 100]
	slider.value_changed.connect(update)
	slider.value = roundi(maximum * 0.5)
	update.call(slider.value)
