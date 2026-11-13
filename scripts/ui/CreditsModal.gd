extends PanelContainer

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

signal closed

## Nombre que se muestra en la pantalla de créditos. Cambiar antes de publicar.
const DEVELOPER_NAME := "Z-rho[Dev]"

const WIDTH := 340.0
const OFL_ALEGREYA := "res://assets/ui/fuentes/OFL_alegreyasans.txt"
const OFL_CINZEL := "res://assets/ui/fuentes/OFL_cinzeldecorative.txt"

const THIRD_PARTY_LINES := [
	"Godot Engine — licencia MIT",
	"Alegreya Sans (The Alegreya Sans Project Authors) — SIL Open Font License 1.1",
	"Cinzel Decorative (Natanael Gama) — SIL Open Font License 1.1",
	"Godot Google Play Billing — licencia MIT",
	"Godot AdMob Plugin (Poing Studios) — licencia MIT",
	"Google Mobile Ads SDK y Google Play Billing Library — © Google",
]

var _body: VBoxContainer
var _reveal_button: Button
var _licenses_box: VBoxContainer

func _ready() -> void:
	theme = UiTheme.make_theme()
	anchor_left = 0.5; anchor_right = 0.5; anchor_top = 0.5; anchor_bottom = 0.5
	offset_left = -WIDTH / 2.0; offset_right = WIDTH / 2.0; offset_top = -370; offset_bottom = 370
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(WIDTH, 0)
	add_theme_stylebox_override("panel", UiTheme.kit("panel_modal", UiTheme.panel(UiTheme.BORDER, 6, 4)))
	_build()

func _build() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	box.add_child(UiTheme.modal_header("CRÉDITOS", func(): closed.emit()))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 8)
	scroll.add_child(_body)

	_body.add_child(UiTheme.section_title("EMBERFALL", "", UiTheme.GOLD))
	var version := str(ProjectSettings.get_setting("application/config/version", "")).strip_edges()
	if version != "":
		_body.add_child(_label("Versión %s" % version, 14, UiTheme.TEXT))
	_body.add_child(_label("Desarrollado por %s" % DEVELOPER_NAME, 14, UiTheme.TEXT))

	_body.add_child(UiTheme.section_title("HECHO CON", "", UiTheme.GOLD))
	for line in THIRD_PARTY_LINES:
		_body.add_child(_label(line, 13, UiTheme.TEXT))

	_reveal_button = Button.new()
	_reveal_button.text = "VER LICENCIAS COMPLETAS"
	_reveal_button.custom_minimum_size = Vector2(0, 44)
	UiTheme.apply_secondary(_reveal_button)
	_reveal_button.pressed.connect(_reveal_licenses)
	_body.add_child(_reveal_button)

## The full license texts are long, so they are only built on the first press.
func _reveal_licenses() -> void:
	if _licenses_box != null:
		return
	_reveal_button.visible = false

	_licenses_box = VBoxContainer.new()
	_licenses_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_licenses_box.add_theme_constant_override("separation", 6)
	_body.add_child(_licenses_box)

	_licenses_box.add_child(UiTheme.section_title("LICENCIAS", "", UiTheme.GOLD))
	_licenses_box.add_child(_label("Licencia de Godot Engine", 12, UiTheme.TEXT_MUTED))
	_licenses_box.add_child(_label(Engine.get_license_text(), 11, UiTheme.TEXT_MUTED))

	_licenses_box.add_child(_label("Componentes de terceros", 12, UiTheme.TEXT_MUTED))
	for component in Engine.get_copyright_info():
		var entry: Dictionary = component
		var licenses := PackedStringArray()
		for part in entry.get("parts", []):
			var lic := str(part.get("license", ""))
			if lic != "" and not licenses.has(lic):
				licenses.append(lic)
		_licenses_box.add_child(_label("%s — %s" % [str(entry.get("name", "")), ", ".join(licenses)], 11, UiTheme.TEXT_MUTED))

	_licenses_box.add_child(_label("Licencia SIL Open Font License de Alegreya Sans", 12, UiTheme.TEXT_MUTED))
	_licenses_box.add_child(_label(FileAccess.get_file_as_string(OFL_ALEGREYA), 11, UiTheme.TEXT_MUTED))
	_licenses_box.add_child(_label("Licencia SIL Open Font License de Cinzel Decorative", 12, UiTheme.TEXT_MUTED))
	_licenses_box.add_child(_label(FileAccess.get_file_as_string(OFL_CINZEL), 11, UiTheme.TEXT_MUTED))

## Wrapping label that fills the row width.
func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
