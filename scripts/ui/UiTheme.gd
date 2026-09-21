extends RefCounted
## Shared look for Emberfall's chrome (Top HUD, Navigation Footer, modals):
## dark violet panels, sharp pixel-style corners, turquoise glow for magic and
## highlighted actions. Only styles live here; no screen logic.

const BG_DEEP := Color("0d0917")
const BG_PANEL := Color("140e22")
const BG_SLOT := Color("1e1530")
const BG_SLOT_ACTIVE := Color("2a1c40")
const BORDER := Color("4e3a68")
const BORDER_SOFT := Color("5b4771")
const ACCENT := Color("20e6bd")
const ACCENT_DIM := Color("13a98b")
const PURPLE := Color("c86bff")
const TEXT := Color("f1e8ff")
const TEXT_MUTED := Color("9b8eaa")
const DANGER := Color("e65a5a")

const CORNER := 4

static func panel(border: Color = BORDER, radius: int = CORNER, border_width: int = 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BG_PANEL
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 6
	return style

static func slot(active: bool = false, padding: int = 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BG_SLOT_ACTIVE if active else BG_SLOT
	style.border_color = ACCENT if active else BORDER_SOFT
	style.set_border_width_all(3)
	style.set_corner_radius_all(CORNER)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding - 1
	style.content_margin_bottom = padding - 1
	if active:
		style.shadow_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.35)
		style.shadow_size = 6
	return style

## Bar background/fill. Fill keeps a 2px corner so it reads as chunky pixels.
static func bar(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	return style

## Primary call-to-action (turquoise) with per-state variants.
static func apply_primary(button: Button) -> void:
	button.add_theme_stylebox_override("normal", button_primary())
	button.add_theme_stylebox_override("hover", button_pressed())
	button.add_theme_stylebox_override("pressed", button_pressed())
	button.add_theme_color_override("font_color", ACCENT)

static func button_normal() -> StyleBoxFlat:
	return slot(false, 10)

static func button_primary() -> StyleBoxFlat:
	var style := slot(true, 10)
	style.bg_color = Color("0f3a3a")
	return style

static func button_pressed() -> StyleBoxFlat:
	var style := slot(true, 10)
	style.bg_color = Color("14504b")
	return style

## Theme applied only to the nodes that opt in (HUD, footer, modals) so the
## screens that haven't been restyled yet don't change under the player.
static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.set_stylebox("normal", "Button", button_normal())
	theme.set_stylebox("hover", "Button", slot(true, 10))
	theme.set_stylebox("pressed", "Button", button_pressed())
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_stylebox("disabled", "Button", slot(false, 10))
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", ACCENT)
	theme.set_color("font_pressed_color", "Button", ACCENT)
	theme.set_color("font_disabled_color", "Button", Color("6a5f7a"))
	theme.set_font_size("font_size", "Button", 16)
	theme.set_stylebox("panel", "PanelContainer", panel())
	theme.set_stylebox("background", "ProgressBar", bar(Color("100b18")))
	theme.set_stylebox("fill", "ProgressBar", bar(ACCENT))
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "CheckButton", TEXT)
	theme.set_color("font_hover_color", "CheckButton", ACCENT)
	theme.set_font_size("font_size", "CheckButton", 16)
	theme.set_stylebox("tab_selected", "TabContainer", slot(true, 8))
	theme.set_stylebox("tab_unselected", "TabContainer", slot(false, 8))
	theme.set_stylebox("tab_hovered", "TabContainer", slot(true, 8))
	theme.set_stylebox("tab_focus", "TabContainer", StyleBoxEmpty.new())
	theme.set_stylebox("panel", "TabContainer", StyleBoxEmpty.new())
	theme.set_color("font_selected_color", "TabContainer", ACCENT)
	theme.set_color("font_unselected_color", "TabContainer", TEXT_MUTED)
	theme.set_color("font_hovered_color", "TabContainer", ACCENT)
	return theme
