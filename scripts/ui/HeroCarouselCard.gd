extends Control
class_name HeroCarouselCard

## One card in the hero-selection carousel. Reused across positions (the
## carousel repositions/rescales existing cards rather than recreating them).

signal pressed

const CARD_SIZE := Vector2(120, 168)

var frame_panel: PanelContainer
var sprite: TextureRect
var rune: RuneBackdrop
var name_label: Label
var condition_label: Label
var lock_icon: TextureRect
var focus_badge: Label
var _unlocked := true

func _ready() -> void:
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	pivot_offset = CARD_SIZE / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	_build()

func _build() -> void:
	frame_panel = PanelContainer.new()
	frame_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame_panel)

	rune = RuneBackdrop.new()
	rune.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rune.visible = false
	frame_panel.add_child(rune)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)

	sprite = TextureRect.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.custom_minimum_size = Vector2(0, 96)
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(sprite)

	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)

	condition_label = Label.new()
	condition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	condition_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	condition_label.add_theme_font_size_override("font_size", 9)
	condition_label.add_theme_color_override("font_color", Color("9b8eaa"))
	condition_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(condition_label)

	lock_icon = TextureRect.new()
	lock_icon.texture = load("res://assets/iconos main/06_candado.png")
	lock_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock_icon.size = Vector2(34, 34)
	lock_icon.set_anchors_preset(Control.PRESET_CENTER)
	lock_icon.position = Vector2(-17, -25)
	lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_icon.visible = false
	frame_panel.add_child(lock_icon)

	# Marker independent of color/border so focus doesn't rely on color alone.
	focus_badge = Label.new()
	focus_badge.text = "★"
	focus_badge.set_anchors_preset(Control.PRESET_TOP_LEFT)
	focus_badge.offset_left = 6; focus_badge.offset_top = 4
	focus_badge.add_theme_color_override("font_color", Color("20e6bd"))
	focus_badge.add_theme_font_size_override("font_size", 14)
	focus_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_badge.visible = false
	frame_panel.add_child(focus_badge)

func setup(hero: Dictionary, unlocked: bool, requirement_text: String) -> void:
	_unlocked = unlocked
	var tex = load(str(hero.get("texture", "")))
	sprite.texture = tex if tex is Texture2D else null
	sprite.modulate = Color.WHITE if unlocked else Color(0.10, 0.06, 0.14)
	name_label.text = str(hero.get("name", ""))
	name_label.visible = unlocked
	condition_label.text = requirement_text
	condition_label.visible = not unlocked and requirement_text != ""
	lock_icon.visible = not unlocked

func set_focus_state(is_center: bool) -> void:
	rune.visible = is_center
	focus_badge.visible = is_center
	frame_panel.add_theme_stylebox_override("panel", _style(is_center))

func _style(is_center: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("21182d")
	style.border_color = Color("20e6bd") if is_center else Color("5b4771")
	style.set_border_width_all(4 if is_center else 2)
	style.set_corner_radius_all(10)
	if is_center:
		style.shadow_color = Color("20e6bd", 0.35)
		style.shadow_size = 6
	return style

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
