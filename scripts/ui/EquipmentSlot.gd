extends PanelContainer
class_name EquipmentSlot

## One reusable slot: used both for the six equip-type slots around the hero
## and for each cell in the backpack grid — visually identical, so this one
## component serves both per the same "icon + rarity frame + level/bonus +
## empty state" shape.

signal pressed

const RARITY_BORDERS := {"common": Color("9b8eaa"), "rare": Color("6be0ff"), "epic": Color("ffb84d")}
const EMPTY_BORDER := Color("4a3f5c")

var icon_rect: TextureRect
var bonus_label: Label
var empty_label: Label
var upgrade_marker: Label

## Built in _init (not _ready) so callers can call set_item()/set_empty()
## right after `.new()`, before this node is ever added to the tree.
func _init() -> void:
	custom_minimum_size = Vector2(60, 60)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	_build()
	set_empty()

func _build() -> void:
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stack)
	icon_rect = TextureRect.new()
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(30, 30)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(icon_rect)
	bonus_label = Label.new()
	bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_label.add_theme_font_size_override("font_size", 11)
	bonus_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(bonus_label)
	empty_label = Label.new()
	empty_label.text = "VACÍO"
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.add_theme_font_size_override("font_size", 9)
	empty_label.add_theme_color_override("font_color", Color("6a5f7a"))
	empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(empty_label)
	upgrade_marker = Label.new()
	upgrade_marker.text = "▲"
	upgrade_marker.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	upgrade_marker.offset_left = -16; upgrade_marker.offset_top = 2
	upgrade_marker.add_theme_color_override("font_color", Color("20e6bd"))
	upgrade_marker.add_theme_font_size_override("font_size", 12)
	upgrade_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upgrade_marker.visible = false
	add_child(upgrade_marker)

func set_empty() -> void:
	icon_rect.texture = null
	icon_rect.visible = false
	bonus_label.visible = false
	empty_label.visible = true
	upgrade_marker.visible = false
	add_theme_stylebox_override("panel", _style(EMPTY_BORDER, false))

## `bonus_text` and `has_upgrade` are optional — pass "" / false to omit
## indicators the real data doesn't back (no fabricated levels/upgrades).
func set_item(icon: Texture2D, rarity: String, bonus_text: String = "", equipped: bool = false, has_upgrade: bool = false) -> void:
	icon_rect.texture = icon
	icon_rect.visible = icon != null
	bonus_label.text = bonus_text
	bonus_label.visible = bonus_text != ""
	empty_label.visible = false
	upgrade_marker.visible = has_upgrade
	var border: Color = RARITY_BORDERS.get(rarity, EMPTY_BORDER)
	add_theme_stylebox_override("panel", _style(border, equipped))

func _style(border: Color, equipped: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("302040") if equipped else Color("21182d")
	style.border_color = border
	style.set_border_width_all(4 if equipped else 3)
	style.set_corner_radius_all(8)
	return style

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
