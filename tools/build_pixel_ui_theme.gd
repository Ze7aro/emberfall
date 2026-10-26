extends SceneTree
## Run after the PNG import. Styles keep pixel corners intact through nine-slice.

const ROOT := "res://assets/ui/pixel_simple_v1/"
var _styles: Dictionary = {}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ROOT + "styles")
	_save("panel", _style("frames/panel.png", 10, 12))
	_save("card", _style("frames/panel.png", 10, 10))
	_save("slot", _style("frames/slot.png", 6, 6))
	var selected := _style("frames/selection.png", 6, 6)
	selected.draw_center = false
	_save("selection", selected)
	_save("button_primary", _style("buttons/button_primary.png", 8, 10))
	_save("button_secondary", _style("buttons/button_secondary.png", 8, 10))
	for family in ["primary", "secondary"]:
		for state in ["hover", "pressed", "disabled"]:
			var style: StyleBoxTexture = _styles["button_" + family].duplicate()
			match state:
				"hover": style.modulate_color = Color(1.15, 1.15, 1.15)
				"pressed": style.modulate_color = Color(0.65, 0.75, 0.85)
				"disabled": style.modulate_color = Color(0.42, 0.42, 0.48)
			_save("button_%s_%s" % [family, state], style)
	for rarity in ["common", "rare", "epic"]:
		var slot: StyleBoxTexture = _styles.slot.duplicate()
		slot.modulate_color = {"common": Color(0.8, 0.8, 0.85), "rare": Color(0.6, 1.2, 1.5), "epic": Color(1.25, 0.85, 1.5)}[rarity]
		_save("rarity_" + rarity, slot)
	var locked: StyleBoxTexture = _styles.slot.duplicate()
	locked.modulate_color = Color(0.45, 0.45, 0.5)
	_save("slot_locked", locked)
	var bar_background := _style("bars/bar_track.png", 4, 4)
	bar_background.content_margin_top = 3
	bar_background.content_margin_bottom = 3
	_save("bar_background", bar_background)
	for kind in ["xp", "energy", "health"]:
		_save("fill_" + kind, _style("bars/fill_" + kind + ".png", 2, 0))
	var theme := Theme.new()
	theme.default_font_size = 12
	theme.set_stylebox("panel", "PanelContainer", _styles.panel)
	theme.set_stylebox("panel", "Panel", _styles.panel)
	theme.set_stylebox("panel", "PopupPanel", _styles.panel)
	theme.set_color("font_color", "Label", Color("ecedf4"))
	theme.set_color("font_shadow_color", "Label", Color("101321"))
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_type_variation("PixelPrimary", "Button")
	theme.set_type_variation("PixelSecondary", "Button")
	for type in ["Button", "PixelPrimary", "PixelSecondary"]:
		var family := "primary" if type == "PixelPrimary" else "secondary"
		theme.set_stylebox("normal", type, _styles["button_" + family])
		for state in ["hover", "pressed", "disabled"]:
			theme.set_stylebox(state, type, _styles["button_%s_%s" % [family, state]])
		theme.set_stylebox("focus", type, _styles.selection)
		theme.set_color("font_color", type, Color("ecedf4"))
		theme.set_color("font_hover_color", type, Color.WHITE)
		theme.set_color("font_pressed_color", type, Color.WHITE)
		theme.set_color("font_disabled_color", type, Color("848396"))
	ResourceSaver.save(theme, ROOT + "pixel_theme.tres")
	print("Pixel theme: %d nine-slice/state resources and shared Theme exported." % _styles.size())
	quit()

func _style(file: String, border: int, content: int) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(ROOT + file)
	style.texture_margin_left = border
	style.texture_margin_right = border
	style.texture_margin_top = border
	style.texture_margin_bottom = border
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, content)
	return style

func _save(name: String, style: StyleBoxTexture) -> void:
	_styles[name] = style
	ResourceSaver.save(style, ROOT + "styles/" + name + ".tres")
