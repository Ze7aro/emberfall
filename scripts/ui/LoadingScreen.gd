extends Control

## Real-progress loading screen: requests a list of resources through
## ResourceLoader.load_threaded_request and shows the average of what the
## loader itself reports. It stays hidden if everything is already cached
## (nothing to wait for), so it never flashes on screen for nothing.

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

signal finished

var _paths: Array[String] = []
var _progress := {}
var _bar: ProgressBar
var _percent: Label
var _done := false

func setup(paths: Array[String]) -> void:
	_paths = paths

func _ready() -> void:
	theme = UiTheme.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()
	for path in _paths:
		ResourceLoader.load_threaded_request(path, "", true)
	# First poll happens in _process, so a caller can connect to `finished`
	# (or await it) right after add_child even when everything is cached.

func _process(_delta: float) -> void:
	if not _done:
		_poll()

func _poll() -> void:
	var total := 0.0
	var all_loaded := true
	for path in _paths:
		var progress: Array = []
		var status := ResourceLoader.load_threaded_get_status(path, progress)
		match status:
			ResourceLoader.THREAD_LOAD_LOADED, ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				total += 1.0
			_:
				all_loaded = false
				total += float(progress[0]) if not progress.is_empty() else 0.0
	var value := total / float(maxi(_paths.size(), 1))
	_bar.value = value * 100.0
	_percent.text = "%d%%" % int(round(value * 100.0))
	if all_loaded:
		_done = true
		finished.emit()
	else:
		visible = true

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = UiTheme.BG_DEEP
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var art := UiTheme.background("bg_carga.png", 0.35)
	if art != null:
		add_child(art)

	var box := VBoxContainer.new()
	box.anchor_left = 0.5; box.anchor_right = 0.5; box.anchor_top = 0.5; box.anchor_bottom = 0.5
	box.offset_left = -150; box.offset_right = 150; box.offset_top = -120; box.offset_bottom = 120
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	add_child(box)

	var logo_path := "res://assets/ui/logo/logo_emberfall.png"
	if ResourceLoader.exists(logo_path):
		var logo := TextureRect.new()
		logo.texture = load(logo_path) as Texture2D
		logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.custom_minimum_size = Vector2(0, 130)
		box.add_child(logo)
	else:
		var title := Label.new()
		title.text = "EMBERFALL"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 40)
		title.add_theme_color_override("font_color", UiTheme.PURPLE)
		box.add_child(title)

	var tagline := Label.new()
	tagline.text = "SOMBRAS HOY. LEYENDAS MAÑANA."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 12)
	tagline.add_theme_color_override("font_color", UiTheme.TEXT)
	tagline.add_theme_color_override("font_outline_color", Color("0a0612"))
	tagline.add_theme_constant_override("outline_size", 6)
	box.add_child(tagline)

	var loading := Label.new()
	loading.text = "CARGANDO..."
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading.add_theme_font_size_override("font_size", 16)
	box.add_child(loading)

	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.max_value = 100.0
	_bar.custom_minimum_size = Vector2(0, 18)
	UiTheme.style_bar(_bar, 34.0)
	box.add_child(_bar)

	_percent = Label.new()
	_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_percent)
