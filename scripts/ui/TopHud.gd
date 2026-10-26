class_name TopHud
extends PanelContainer

const UiTheme := preload("res://scripts/ui/UiTheme.gd")
const FillBar := preload("res://scripts/ui/HudFillBar.gd")
const ART_DIR := "res://assets/ui/pixel_simple_v1/"
const DESIGN_WIDTH := 390.0

signal profile_pressed
signal shop_pressed
signal settings_pressed

var _canvas: Control
var _safe_top := 0.0
var _level_label: Label
var _xp_progress_material: ShaderMaterial
var _energy_bar: HudFillBar
var _energy_label: Label
var _gold_label: Label
var _gems_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_safe_top = _safe_area_top_inset()
	custom_minimum_size.y = UiTheme.HUD_HEIGHT + _safe_top
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	theme = UiTheme.make_theme()
	var host := Control.new()
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(host)
	_canvas = Control.new()
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(_canvas)
	_build()
	resized.connect(_layout_canvas)
	_layout_canvas()
	var state := get_node("/root/GameState")
	set_level(state.level)
	set_experience(state.experience, state.experience_to_next)
	set_energy(state.energy, state.MAX_ENERGY)
	set_gold(state.gold)
	set_gems(state.gems)

func _layout_canvas() -> void:
	if not is_instance_valid(_canvas):
		return
	# Scale the row together below 390px; wider screens expand resource slots.
	var factor := minf(size.x / DESIGN_WIDTH, 1.0)
	_canvas.size = Vector2(maxf(size.x, DESIGN_WIDTH), UiTheme.HUD_HEIGHT)
	_canvas.scale = Vector2.ONE * factor
	_canvas.position = Vector2(0, _safe_top + maxf(0.0, (size.y - _safe_top - UiTheme.HUD_HEIGHT * factor) * 0.5))

func _safe_area_top_inset() -> float:
	if not OS.has_feature("mobile"):
		return 0.0
	return maxf(0.0, float(DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen()).position.y))

func set_level(value: int) -> void:
	_level_label.text = str(value)

func set_experience(current: int, needed: int) -> void:
	var progress := 0.0 if needed <= 0 else clampf(float(current) / float(needed), 0.0, 1.0)
	if _xp_progress_material != null:
		_xp_progress_material.set_shader_parameter("progress", progress)

func set_energy(current: int, maximum: int) -> void:
	_energy_label.text = "%d/%d" % [current, maximum]
	_energy_bar.set_amount(current, maximum)

func set_gold(value: int) -> void:
	_gold_label.text = _compact_number(value)

func set_gems(value: int) -> void:
	_gems_label.text = _compact_number(value)

func set_energy_countdown(_seconds_left: int) -> void:
	pass

func _build() -> void:
	var frame := _art("frame.png")
	frame.name = "HudFrame"
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	frame.offset_left = 2
	frame.offset_right = -2
	frame.offset_top = 4
	frame.offset_bottom = 66
	_canvas.add_child(frame)
	var row := HBoxContainer.new()
	row.name = "Content"
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 2
	row.offset_right = -2
	row.offset_top = 4
	row.offset_bottom = 66
	row.add_theme_constant_override("separation", 4)
	_canvas.add_child(row)
	row.add_child(_level_tile())
	row.add_child(_resource_tile("energy_icon.png", "energy", 108))
	row.add_child(_resource_tile("coin_icon.png", "gold", 102))
	row.add_child(_resource_tile("gem_icon.png", "gems", 102))
	var settings := Button.new()
	settings.name = "Settings"
	settings.tooltip_text = "Configuración"
	settings.accessibility_name = "Abrir configuración"
	settings.icon = load(ART_DIR + "icons/settings.png") as Texture2D
	settings.icon_max_width = 22
	settings.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	settings.offset_left = -44
	settings.offset_right = -4
	settings.offset_top = 64
	settings.offset_bottom = 100
	settings.focus_mode = Control.FOCUS_ALL
	UiTheme.apply_secondary(settings, 4.0)
	settings.pressed.connect(func(): settings_pressed.emit())
	_canvas.add_child(settings)

func _level_tile() -> Control:
	var tile := Control.new()
	tile.name = "Level"
	tile.custom_minimum_size = Vector2(62, 62)
	var art := _art("hud/level_xp_ring.png")
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.modulate = Color(0.2, 0.18, 0.32, 1.0)
	tile.add_child(art)
	var xp_ring := _art("hud/level_xp_ring.png")
	xp_ring.name = "ExperienceRing"
	xp_ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ring_shader := Shader.new()
	ring_shader.code = """
shader_type canvas_item;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec2 point = UV - vec2(0.5);
	float radius = length(point);
	if (radius < 0.31 || radius > 0.51) {
		discard;
	}
	float angle = mod(atan(point.x, -point.y) + 6.2831853, 6.2831853);
	if (angle > progress * 6.2831853) {
		discard;
	}
	COLOR = texture(TEXTURE, UV);
}
"""
	_xp_progress_material = ShaderMaterial.new()
	_xp_progress_material.shader = ring_shader
	xp_ring.material = _xp_progress_material
	tile.add_child(xp_ring)
	_level_label = _label(21)
	_level_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_level_label.offset_top = 2
	tile.add_child(_level_label)
	var hit := _hit_button()
	hit.tooltip_text = "Perfil"
	hit.accessibility_name = "Abrir perfil"
	hit.pressed.connect(func(): profile_pressed.emit())
	tile.add_child(hit)
	return tile

func _resource_tile(icon_file: String, kind: String, width: float) -> Control:
	var tile := Control.new()
	tile.name = kind.capitalize()
	tile.custom_minimum_size = Vector2(width, 58)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if kind == "energy":
		_energy_bar = _bar("energy_fill.png")
		_center_strip(_energy_bar, 42)
		tile.add_child(_energy_bar)
	else:
		var track := _art("track.png")
		track.stretch_mode = TextureRect.STRETCH_SCALE
		_center_strip(track, 42)
		tile.add_child(track)
	var icon := _art(icon_file)
	icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	icon.offset_left = 8
	icon.offset_right = 30
	icon.offset_top = -12
	icon.offset_bottom = 12
	tile.add_child(icon)
	var amount := _label(14)
	amount.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	amount.offset_left = 31
	amount.offset_right = -34
	tile.add_child(amount)
	match kind:
		"energy": _energy_label = amount
		"gold": _gold_label = amount
		"gems": _gems_label = amount
	var plus := _art("add.png")
	plus.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	plus.offset_left = -30
	plus.offset_right = -3
	plus.offset_top = -15
	plus.offset_bottom = 15
	tile.add_child(plus)
	var hit := _hit_button()
	hit.pressed.connect(func(): shop_pressed.emit())
	hit.mouse_entered.connect(func(): plus.modulate = Color(1.2, 1.2, 1.2))
	hit.mouse_exited.connect(func(): plus.modulate = Color.WHITE)
	hit.button_down.connect(func(): plus.modulate = Color(0.65, 0.85, 1.0))
	hit.button_up.connect(func(): plus.modulate = Color.WHITE)
	tile.add_child(hit)
	return tile

func _bar(fill_file: String) -> HudFillBar:
	var bar := FillBar.new()
	bar.track_texture = load(ART_DIR + "bars/bar_track.png")
	var fills := {"xp_fill.png": "fill_xp.png", "energy_fill.png": "fill_energy.png"}
	bar.fill_texture = load(ART_DIR + "bars/" + str(fills.get(fill_file, "fill_xp.png")))
	return bar

func _center_strip(control: Control, height: float) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_HCENTER_WIDE)
	control.offset_top = -height * 0.5
	control.offset_bottom = height * 0.5

func _hit_button() -> Button:
	var hit := Button.new()
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	return hit

func _art(file: String) -> TextureRect:
	var rect := TextureRect.new()
	var paths := {
		"energy_icon.png": "icons/energy.png", "coin_icon.png": "icons/coin.png",
		"gem_icon.png": "icons/gem.png", "add.png": "buttons/add.png",
		"track.png": "bars/bar_track.png", "frame.png": "frames/hud_frame.png",
		"level.png": "hud/level.png", "xp_fill.png": "bars/fill_xp.png",
		"energy_fill.png": "bars/fill_energy.png",
	}
	rect.texture = load(ART_DIR + str(paths.get(file, file)))
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

func _label(font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", UiTheme.TEXT)
	label.add_theme_color_override("font_outline_color", Color("080e20"))
	label.add_theme_constant_override("outline_size", 3)
	var bold := FontVariation.new()
	bold.base_font = ThemeDB.fallback_font
	bold.variation_embolden = 1.0
	label.add_theme_font_override("font", bold)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _compact_number(value: int) -> String:
	for unit in [[1_000_000_000, "B"], [1_000_000, "M"], [1_000, "K"]]:
		if value >= unit[0]:
			var scaled := float(value) / float(unit[0])
			return ("%d%s" % [int(scaled), unit[1]]) if scaled >= 100.0 else ("%.1f%s" % [scaled, unit[1]])
	return str(value)
