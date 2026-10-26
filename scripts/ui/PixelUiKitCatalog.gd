extends Control
## Standalone asset review, intentionally independent of player state.
const ROOT := "res://assets/ui/pixel_simple_v1/"

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	theme = load(ROOT + "pixel_theme.tres")
	var background := ColorRect.new()
	background.color = Color("101321")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	scroll.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	var title := Label.new()
	title.text = "EMBERFALL / PIXEL ART SIMPLE"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("42d8e8"))
	column.add_child(title)
	var note := Label.new()
	note.text = "Piedra oscura · Violeta · Cristales discretos · Cantidades y textos dinámicos"
	note.add_theme_color_override("font_color", Color("aaa3b8"))
	column.add_child(note)
	var shell_row := HBoxContainer.new()
	shell_row.add_theme_constant_override("separation", 16)
	column.add_child(shell_row)
	for file in ["frames/hud_frame.png", "frames/footer_frame.png"]:
		var shell := _texture(file, Vector2(0, 120))
		shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell_row.add_child(shell)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	for index in range(4):
		var button := Button.new()
		button.text = ["JUGAR", "VOLVER", "RECLAMADO", "SELECCIONADO"][index]
		button.theme_type_variation = "PixelPrimary" if index == 0 else "PixelSecondary"
		button.custom_minimum_size = Vector2(0, 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = index == 2
		if index == 3:
			button.add_theme_stylebox_override("normal", load(ROOT + "styles/button_primary_hover.tres"))
		buttons.add_child(button)
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "manifest.json"))
	var grid := GridContainer.new()
	grid.columns = 8 if size.x >= 1000 else (4 if size.x >= 600 else 2)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	column.add_child(grid)
	for asset: Dictionary in manifest.assets:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", load(ROOT + "styles/card.tres"))
		card.custom_minimum_size = Vector2(120, 120)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		var box := VBoxContainer.new()
		card.add_child(box)
		box.add_child(_texture(asset.file, Vector2(0, 78)))
		var label := Label.new()
		label.text = asset.name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		box.add_child(label)
	var heading := Label.new()
	heading.text = "EXPERIENCIA / ENERGÍA / VIDA — 0, 25, 50, 75 Y 100 %"
	heading.add_theme_color_override("font_color", Color("42d8e8"))
	column.add_child(heading)
	column.add_child(_texture("previews/fill_states.png", Vector2(0, 400)))

func _texture(file: String, minimum: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = load(ROOT + file)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = minimum
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return rect
