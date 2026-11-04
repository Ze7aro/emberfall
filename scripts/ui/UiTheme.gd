extends RefCounted
## Shared mobile-first visual language.  The game used to mix several ornate
## asset kits; this is deliberately quieter so that enemies, rewards and the
## next action are what the player reads first.

const BG_DEEP := Color("101321")
const BG_PANEL := Color("141827")
const BG_SLOT := Color("1b1e31")
const BG_SLOT_ACTIVE := Color("25243a")
const BORDER := Color("55446e")
const BORDER_SOFT := Color("514364")
const ACCENT := Color("42d8e8")
const ACCENT_DIM := Color("248d9a")
const PURPLE := Color("c747e0")
const TEXT := Color("ecedf4")
const TEXT_MUTED := Color("aaa3b8")
const DANGER := Color("d96168")
const GOLD := Color("f4c96a")
const EMBER := Color("ff9a4a")
## Light label on the dark turquoise primary art (dark text was unreadable).
const PRIMARY_TEXT := Color("e9fdff")

const TITLE_FONT := "res://assets/ui/fuentes/titulo.tres"
const BOLD_FONT := "res://assets/ui/fuentes/texto_bold.tres"

const CORNER := 12

## Slim top HUD height and the y where screen content may start under it.
const HUD_HEIGHT := 100.0
const CONTENT_TOP := 120.0

static var _fonts := {}

static func _font(path: String) -> Font:
	if not _fonts.has(path):
		_fonts[path] = load(path) as Font
	return _fonts[path]

## Engraved display face for screen and section titles.
static func title_font() -> Font:
	return _font(TITLE_FONT)

static func bold_font() -> Font:
	return _font(BOLD_FONT)

## Applies the display face plus a dark outline so titles sit on any backdrop.
static func style_title(label: Label, size: int, color: Color = TEXT) -> void:
	label.add_theme_font_override("font", title_font())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("07060d"))
	label.add_theme_constant_override("outline_size", 6)

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

## --- Graphic kit -----------------------------------------------------------
## Optional nine-slice textures for the shared theme. Each entry maps an id to
## [file under KIT_DIR, margin_left, margin_top, margin_right, margin_bottom]
## (margins in texture pixels). While a file is missing (or not imported) the
## flat style is used instead, so nothing changes until the art is dropped in.
## Full list, sizes and target screens: docs/RECURSOS_UI_PENDIENTES.md
const KIT_DIR := "res://assets/ui/"
## Optional 6th element `true`: the frame's interior is transparent, so it is
## composited over a solid dark fill (built at runtime, no extra file).
const KIT := {
	"panel_default": ["frames/panel.png", 10, 10, 10, 10],
	"panel_main": ["frames/panel.png", 10, 10, 10, 10],
	"panel_modal": ["frames/panel.png", 10, 10, 10, 10],
	"panel_card": ["frames/panel.png", 10, 10, 10, 10],
	"slot_normal": ["frames/slot.png", 6, 6, 6, 6],
	"slot_active": ["frames/selection.png", 6, 6, 6, 6],
	"slot_locked": ["frames/slot.png", 6, 6, 6, 6],
	"button_normal": ["buttons/button_secondary.png", 8, 8, 8, 8],
	"button_hover": ["buttons/button_secondary.png", 8, 8, 8, 8],
	"button_pressed": ["buttons/button_secondary.png", 8, 8, 8, 8],
	"button_disabled": ["buttons/button_secondary.png", 8, 8, 8, 8],
	"button_primary": ["buttons/button_primary.png", 8, 8, 8, 8],
	"button_primary_hover": ["buttons/button_primary.png", 8, 8, 8, 8],
	"button_primary_pressed": ["buttons/button_primary.png", 8, 8, 8, 8],
	"bar_bg": ["bars/bar_track.png", 4, 4, 4, 4],
	"bar_fill": ["bars/fill_energy.png", 2, 2, 2, 2],
	"rarity_common": ["frames/slot.png", 6, 6, 6, 6],
	"rarity_rare": ["frames/slot.png", 6, 6, 6, 6],
	"rarity_epic": ["frames/slot.png", 6, 6, 6, 6],
	"rarity_legendary": ["frames/slot.png", 6, 6, 6, 6],
	"hero_card": ["frames/panel.png", 10, 10, 10, 10],
	"hero_card_focus": ["frames/selection.png", 6, 6, 6, 6],
	"slot_wide": ["frames/slot.png", 6, 6, 6, 6],
	"slot_wide_active": ["frames/selection.png", 6, 6, 6, 6],
}

static var _texture_cache := {}

static func kit_available(id: String) -> bool:
	return KIT.has(id) and ResourceLoader.exists(KIT_DIR + str(KIT[id][0]))

static func _kit_texture(id: String) -> Texture2D:
	if _texture_cache.has(id):
		return _texture_cache[id]
	var entry: Array = KIT[id]
	var texture := load(KIT_DIR + str(entry[0])) as Texture2D
	if texture != null and entry.size() > 5 and entry[5]:
		var src := texture.get_image()
		src.convert(Image.FORMAT_RGBA8)
		var out := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
		var inset := 6
		out.fill_rect(Rect2i(inset, inset, src.get_width() - inset * 2, src.get_height() - inset * 2), BG_PANEL)
		out.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i.ZERO)
		texture = ImageTexture.create_from_image(out)
	_texture_cache[id] = texture
	return texture

## The kit's nine-slice style for `id`, or `fallback` when that art isn't
## available. Content margins are at least the fallback's, and never so small
## that children touch the ornamented border.
static func kit(id: String, fallback: StyleBox, content: float = -1.0) -> StyleBox:
	if not kit_available(id):
		return fallback
	var texture := _kit_texture(id)
	if texture == null:
		return fallback
	var entry: Array = KIT[id]
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = float(entry[1])
	style.texture_margin_top = float(entry[2])
	style.texture_margin_right = float(entry[3])
	style.texture_margin_bottom = float(entry[4])
	if id == "rarity_rare":
		style.modulate_color = Color(0.8, 1.0, 1.12)
	elif id == "rarity_epic":
		style.modulate_color = Color(1.12, 0.84, 1.12)
	elif id == "rarity_legendary":
		style.modulate_color = Color(1.2, 0.95, 0.6)
	if entry.size() > 6:
		style.region_rect = entry[6]
	var sides := [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]
	for i in 4:
		if content >= 0.0:
			style.set_content_margin(sides[i], content)
		else:
			style.set_content_margin(sides[i], maxf(maxf(fallback.get_content_margin(sides[i]), 0.0), float(entry[i + 1]) * 1.0))
	return style

## Some delivered art has a file-name caption drawn under the artwork. This
## returns the texture with `crop` applied (when non-empty) and the `clear`
## rectangles made transparent, without touching the file on disk.
static func clean_texture(path: String, crop: Rect2i = Rect2i(), clear: Array = []) -> Texture2D:
	var key := "clean:" + path
	if _texture_cache.has(key):
		return _texture_cache[key]
	var source := load(path) as Texture2D
	if source == null:
		return null
	var image := source.get_image()
	image.convert(Image.FORMAT_RGBA8)
	for rect in clear:
		var r: Rect2i = rect
		image.fill_rect(r, Color(0, 0, 0, 0))
	if crop.size != Vector2i.ZERO:
		image = image.get_region(crop)
	var texture := ImageTexture.create_from_image(image)
	_texture_cache[key] = texture
	return texture

## Crops `crop` out of a kit texture and resizes it (nearest) to `target`.
## Returns null when the art is missing. Used for the switch and arrow icons.
static func scaled_texture(path: String, crop: Rect2i, target: Vector2i, flip_h: bool = false) -> Texture2D:
	var key := "scaled:%s:%s:%s:%s" % [path, crop, target, flip_h]
	if _texture_cache.has(key):
		return _texture_cache[key]
	if not ResourceLoader.exists(path):
		return null
	var image := (load(path) as Texture2D).get_image()
	image.convert(Image.FORMAT_RGBA8)
	image = image.get_region(crop)
	image.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
	if flip_h:
		image.flip_x()
	var texture := ImageTexture.create_from_image(image)
	_texture_cache[key] = texture
	return texture

## Kit icon (54×57 art) by file name, or null if missing.
static func icon(file_name: String) -> Texture2D:
	var path := KIT_DIR + "icons/" + file_name
	var flip_h := false
	if file_name.ends_with(".png"):
		var stem := file_name.trim_suffix(".png")
		var mapped := {
			"notificacion": "icons/mail.png", "settings": "icons/settings.png", "ajustes": "icons/settings.png", "refresh": "icons/refresh.png", "recargar": "icons/refresh.png", "espada": "equipment/weapon.png", "icono_ataque": "equipment/weapon.png",
			"corazon": "icons/heart.png", "energia": "icons/energy.png",
			"flecha": "icons/arrow.png", "arrow": "icons/arrow.png", "arrow_left": "icons/arrow.png", "candado": "icons/lock.png",
			"objetivo": "icons/target.png", "mazmorras": "icons/target.png",
			"cofre": "shop/chest_epic.png", "check": "icons/check.png", "confirmar": "icons/confirm.png", "cancelar": "icons/cancel.png", "autoplay": "icons/autoplay.png",
		}
		if mapped.has(stem):
			path = KIT_DIR + mapped[stem]
		flip_h = stem == "arrow_left"
	if not ResourceLoader.exists(path):
		return null
	var texture := load(path) as Texture2D
	if flip_h and texture != null:
		var image := texture.get_image()
		image.flip_x()
		return ImageTexture.create_from_image(image)
	return texture

static func icon_rect(file_name: String, size: float = 24.0) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = icon(file_name)
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(size, size)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

## Ornate kit bar for tall bars only (the art is 51 px high: below ~28 px the
## end ornaments get squashed). Falls back to the flat bar when art is missing.
static func style_bar(progress: ProgressBar, height: float = 30.0, fill_file: String = "fill_energy.png") -> void:
	if not kit_available("bar_bg"):
		return
	progress.custom_minimum_size.y = maxf(progress.custom_minimum_size.y, height)
	# ProgressBar draws the fill inside the background's content margins, so
	# those margins are the channel between the frame's end ornaments.
	var background := kit("bar_bg", bar(Color("100b18")), 0.0)
	background.content_margin_left = 22.0
	background.content_margin_right = 22.0
	background.content_margin_top = 12.0
	background.content_margin_bottom = 12.0
	progress.add_theme_stylebox_override("background", background)
	var fill := StyleBoxTexture.new()
	fill.texture = load(KIT_DIR + "bars/" + fill_file) as Texture2D
	if fill.texture == null:
		return
	fill.texture_margin_left = 1.0
	fill.texture_margin_right = 1.0
	fill.texture_margin_top = 1.0
	fill.texture_margin_bottom = 1.0
	fill.content_margin_left = 0.0
	fill.content_margin_right = 0.0
	fill.content_margin_top = 0.0
	fill.content_margin_bottom = 0.0
	# The fill is drawn from the bar's own edge: pull it into the channel.
	fill.expand_margin_left = -22.0
	fill.expand_margin_top = -12.0
	fill.expand_margin_bottom = -12.0
	progress.add_theme_stylebox_override("fill", fill)

## Wider side padding for narrow buttons whose text would touch the ornaments.
static func _with_h(style: StyleBox, h_margin: float) -> StyleBox:
	if style is StyleBoxTexture:
		style.content_margin_left = h_margin
		style.content_margin_right = h_margin
	return style

## Shared secondary (kit) button look with custom side padding.
static func apply_secondary(button: Button, h_margin: float = 12.0) -> void:
	button.add_theme_stylebox_override("normal", _with_h(button_normal(), h_margin))
	button.add_theme_stylebox_override("hover", _with_h(button_hover(), h_margin))
	button.add_theme_stylebox_override("pressed", _with_h(button_pressed(), h_margin))
	button.add_theme_stylebox_override("disabled", _with_h(button_disabled(), h_margin))
	button.add_theme_color_override("font_color", TEXT)
	install_press_feedback(button)

## Flat turquoise CTA for small buttons (< ~44 px tall), where the ornate kit
## art would be squashed.
static func apply_primary_flat(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _primary_flat())
	button.add_theme_stylebox_override("hover", button_pressed())
	button.add_theme_stylebox_override("pressed", button_pressed())
	button.add_theme_color_override("font_color", Color("102013"))
	install_press_feedback(button)

## Primary call-to-action (turquoise) with per-state variants.
static func apply_primary(button: Button, h_margin: float = 12.0) -> void:
	button.add_theme_stylebox_override("normal", _with_h(button_primary(), h_margin))
	button.add_theme_stylebox_override("hover", _with_h(button_primary_hover(), h_margin))
	button.add_theme_stylebox_override("pressed", _with_h(button_primary_pressed(), h_margin))
	button.add_theme_stylebox_override("disabled", _with_h(button_primary_disabled(), h_margin))
	_primary_text(button)
	install_press_feedback(button)

## A small scale response makes touch targets feel physical without adding
## particles or new art. The guard matters because some controls are restyled.
static func _primary_text(button: Button) -> void:
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, PRIMARY_TEXT)
	button.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	button.add_theme_color_override("font_outline_color", Color("06232a"))
	button.add_theme_constant_override("outline_size", 4)
	button.add_theme_font_override("font", bold_font())

static func install_press_feedback(button: Button) -> void:
	if button.has_meta("press_feedback"):
		return
	button.set_meta("press_feedback", true)
	button.button_down.connect(func():
		button.pivot_offset = button.size * 0.5
		var tween := button.create_tween()
		tween.tween_property(button, "scale", Vector2(0.96, 0.96), 0.06)
	)
	button.button_up.connect(func():
		var tween := button.create_tween()
		tween.tween_property(button, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)

static func button_normal() -> StyleBox:
	return kit("button_normal", slot(false, 10), 10.0)

static func button_hover() -> StyleBox:
	return _tinted_kit("button_hover", slot(true, 10), Color(1.12, 1.12, 1.12))

static func button_primary() -> StyleBox:
	return kit("button_primary", _primary_flat(), 10.0)

static func button_primary_hover() -> StyleBox:
	return _tinted_kit("button_primary_hover", _primary_flat(), Color(1.12, 1.12, 1.12))

static func button_primary_pressed() -> StyleBox:
	return _tinted_kit("button_primary_pressed", _primary_flat(), Color(0.72, 0.84, 0.9))

static func button_disabled() -> StyleBox:
	return _tinted_kit("button_disabled", slot(false, 10), Color(0.42, 0.42, 0.5))

static func button_primary_disabled() -> StyleBox:
	return _tinted_kit("button_primary", _primary_flat(), Color(0.42, 0.48, 0.5))

static func _tinted_kit(id: String, fallback: StyleBox, tint: Color) -> StyleBox:
	var style := kit(id, fallback, 10.0)
	if style is StyleBoxTexture:
		style.modulate_color = tint
	return style

static func _primary_flat() -> StyleBoxFlat:
	var style := slot(true, 10)
	style.bg_color = ACCENT
	style.border_color = Color("87f4ec")
	return style

static func button_pressed() -> StyleBox:
	var textured: StyleBox = kit("button_pressed", slot(true, 10), 10.0)
	if textured is StyleBoxTexture:
		textured.modulate_color = Color(0.75, 0.82, 0.9)
		return textured
	var style := slot(true, 10)
	style.bg_color = ACCENT_DIM
	style.border_color = ACCENT
	return style

## A text-only heading keeps every screen recognisable without competing with
## its playable content. `banner` remains in the signature for compatibility.
static func header(title: String, subtitle: String = "", size: int = 30, banner: String = "") -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	style_title(title_label, size)
	box.add_child(title_label)
	box.add_child(ornament())
	if subtitle != "":
		var sub := Label.new()
		# All-caps taglines read as shouting in the body face: sentence case.
		sub.text = subtitle.substr(0, 1) + subtitle.substr(1).to_lower() if subtitle == subtitle.to_upper() else subtitle
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub.add_theme_font_size_override("font_size", 14)
		sub.add_theme_color_override("font_color", TEXT_MUTED)
		box.add_child(sub)
	return box

## Modal title bar: engraved title centred, a round close button on the
## right and the gold ornament underneath.
static func modal_header(title: String, on_close: Callable, size: int = 22) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 44)
	box.add_child(bar)
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 44.0
	label.offset_right = -44.0
	label.clip_text = true
	# Long words in the engraved face don't fit beside the close button.
	style_title(label, size if title.length() <= 9 else size - 4)
	bar.add_child(label)
	var close := close_button(on_close)
	close.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	close.offset_left = -40.0
	close.offset_right = 0.0
	close.offset_top = -20.0
	close.offset_bottom = 20.0
	bar.add_child(close)
	box.add_child(ornament(220.0))
	return box

## Round dark button with the kit's close icon.
static func close_button(on_close: Callable) -> Button:
	var button := Button.new()
	button.icon = load(KIT_DIR + "icons/close.png") as Texture2D
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", 18)
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(40, 40)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.1, 0.9)
	style.border_color = Color(GOLD, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(20)
	style.set_content_margin_all(9)
	for state in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(on_close)
	install_press_feedback(button)
	return button

## Thin divider that fades out at both ends with a small diamond in the
## middle; sits under titles.
static func ornament(width: float = 180.0, color: Color = GOLD) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 12)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.draw.connect(func():
		var mid := Vector2(holder.size.x / 2.0, 6.0)
		var half := minf(width / 2.0, holder.size.x / 2.0 - 4.0)
		var steps := 12
		for i in steps:
			var t0 := float(i) / steps
			var t1 := float(i + 1) / steps
			var a := color.a * (1.0 - t0) * 0.85
			holder.draw_line(mid + Vector2(10 + (half - 10) * t0, 0), mid + Vector2(10 + (half - 10) * t1, 0), Color(color, a), 1.5)
			holder.draw_line(mid - Vector2(10 + (half - 10) * t0, 0), mid - Vector2(10 + (half - 10) * t1, 0), Color(color, a), 1.5)
		var d := PackedVector2Array([mid + Vector2(0, -5), mid + Vector2(5, 0), mid + Vector2(0, 5), mid + Vector2(-5, 0)])
		holder.draw_colored_polygon(d, color)
		holder.draw_circle(mid, 1.6, Color("1a1028"))
	)
	return holder

## Illustrated full-screen backdrop with a dark veil so content stays legible.
## Returns null when the art is missing (callers keep their flat background).
## The arguments are kept for compatibility; every screen now shares the
## code-drawn EmberBackdrop (gradient, glow, drifting embers).
static func background(_file_name: String = "", _veil: float = 0.55, _cover_top_only: bool = false) -> Control:
	return EmberBackdrop.new()

## "TITLE ———— note" row used to open a section.
static func section_title(text: String, note: String = "", color: Color = TEXT) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = text
	style_title(label, 16, color)
	label.add_theme_constant_override("outline_size", 4)
	row.add_child(label)
	var line := ColorRect.new()
	line.color = Color(color, 0.35)
	line.custom_minimum_size = Vector2(0, 2)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(line)
	if note != "":
		var note_label := Label.new()
		note_label.text = note
		note_label.add_theme_font_size_override("font_size", 13)
		note_label.add_theme_color_override("font_color", TEXT_MUTED)
		row.add_child(note_label)
	return row

## Theme applied only to the nodes that opt in (HUD, footer, modals) so the
## screens that haven't been restyled yet don't change under the player.
static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.set_stylebox("normal", "Button", button_normal())
	theme.set_stylebox("hover", "Button", button_hover())
	theme.set_stylebox("pressed", "Button", button_pressed())
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_stylebox("disabled", "Button", button_disabled())
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", TEXT)
	theme.set_color("font_pressed_color", "Button", TEXT)
	theme.set_color("font_disabled_color", "Button", TEXT_MUTED)
	theme.set_font_size("font_size", "Button", 16)
	theme.set_stylebox("panel", "PanelContainer", kit("panel_default", panel()))
	theme.set_stylebox("background", "ProgressBar", bar(Color("100b18")))
	theme.set_stylebox("fill", "ProgressBar", bar(ACCENT))
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_outline_color", "Label", Color("080b16"))
	theme.set_constant("outline_size", "Label", 2)
	theme.set_stylebox("normal", "CheckButton", slot(false, 10))
	theme.set_stylebox("hover", "CheckButton", slot(true, 10))
	theme.set_stylebox("pressed", "CheckButton", button_pressed())
	theme.set_stylebox("hover_pressed", "CheckButton", button_pressed())
	theme.set_stylebox("focus", "CheckButton", StyleBoxEmpty.new())
	var switch_off: Texture2D = _switch_texture(false)
	var switch_on: Texture2D = _switch_texture(true)
	if switch_off != null and switch_on != null:
		for state in ["unchecked", "unchecked_disabled", "unchecked_mirrored", "unchecked_disabled_mirrored"]:
			theme.set_icon(state, "CheckButton", switch_off)
		for state in ["checked", "checked_disabled", "checked_mirrored", "checked_disabled_mirrored"]:
			theme.set_icon(state, "CheckButton", switch_on)
	theme.set_color("font_color", "CheckButton", TEXT)
	theme.set_color("font_hover_color", "CheckButton", ACCENT)
	theme.set_font_size("font_size", "CheckButton", 16)
	theme.set_font("font", "Button", bold_font())
	theme.set_font("font", "CheckButton", bold_font())
	theme.set_stylebox("tab_selected", "TabContainer", slot(true, 8))
	theme.set_stylebox("tab_unselected", "TabContainer", slot(false, 8))
	theme.set_stylebox("tab_hovered", "TabContainer", slot(true, 8))
	theme.set_stylebox("tab_focus", "TabContainer", StyleBoxEmpty.new())
	theme.set_stylebox("panel", "TabContainer", StyleBoxEmpty.new())
	theme.set_color("font_selected_color", "TabContainer", ACCENT)
	theme.set_color("font_unselected_color", "TabContainer", TEXT_MUTED)
	theme.set_color("font_hovered_color", "TabContainer", ACCENT)
	return theme

## Pill switch for CheckButtons, rasterised once (anti-aliased by coverage):
## dark track with the knob left when off, turquoise with the knob right when on.
static func _switch_texture(on: bool) -> Texture2D:
	var key := "switch:%s" % on
	if _texture_cache.has(key):
		return _texture_cache[key]
	var w := 46
	var h := 26
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var r := h / 2.0
	var track := Color("1fb5c4") if on else Color("2a2340")
	var rim := Color("8af3f7") if on else Color("5a4a78")
	var knob := Color("f4fbff") if on else Color("9d92b3")
	var knob_c := Vector2(w - r, r) if on else Vector2(r, r)
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var cx := clampf(p.x, r, w - r)
			var dist := p.distance_to(Vector2(cx, r))
			var cover := clampf(r - dist, 0.0, 1.0)
			if cover <= 0.0:
				continue
			var col := rim if dist > r - 2.0 else track
			var kd := p.distance_to(knob_c)
			var kc := clampf(r - 4.0 - kd, 0.0, 1.0)
			col = col.lerp(knob, kc)
			img.set_pixel(x, y, Color(col, cover))
	var tex := ImageTexture.create_from_image(img)
	_texture_cache[key] = tex
	return tex

## --- Crisp pixel art -------------------------------------------------------
## The small kit art (24–48 px pixel icons) looked jagged: on a phone it's
## enlarged ~2.8× with nearest filtering, so pixels came out uneven. Here it is
## enlarged in memory to ~128 px with even pixels, mipmapped, and reported at
## its original size, so a linear filter draws it clean at any scale.
const CRISP_MAX_SOURCE := 96
const CRISP_TARGET := 128

static func crisp(texture: Texture2D) -> Texture2D:
	if texture == null or texture.has_meta("crisp"):
		return texture
	var w := texture.get_width()
	var h := texture.get_height()
	if maxi(w, h) > CRISP_MAX_SOURCE:
		return texture
	var key := "crisp:%s" % (texture.resource_path if texture.resource_path != "" else str(texture.get_instance_id()))
	if _texture_cache.has(key):
		return _texture_cache[key]
	var image := texture.get_image()
	if image == null:
		return texture
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var k := ceili(float(CRISP_TARGET) / maxi(w, h))
	image.resize(w * k, h * k, Image.INTERPOLATE_NEAREST)
	image.generate_mipmaps()
	var out := ImageTexture.create_from_image(image)
	out.set_size_override(Vector2i(w, h))
	out.set_meta("crisp", true)
	_texture_cache[key] = out
	return out

## Menu art pass: crisp small icons and draw everything with smooth filtering.
static func smooth(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node is TextureRect:
		node.texture = crisp(node.texture)
		node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	elif node is Button:
		if node.icon != null:
			node.icon = crisp(node.icon)
		node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	elif node is AnimatedSprite2D or node is Sprite2D:
		node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
