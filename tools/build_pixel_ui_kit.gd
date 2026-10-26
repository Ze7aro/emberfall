extends SceneTree
## Package pixel UI artwork on a small, consistent logical grid.
## Generation sources live in source/; prior review versions are archived separately.

const ROOT := "res://assets/ui/pixel_simple_v1/"
var _images: Dictionary = {}
var _entries: Array = []

func _initialize() -> void:
	var source_manifest = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "prompts.json"))
	if not source_manifest is Dictionary:
		push_error("Missing pixel UI generation manifest")
		quit(1)
		return
	_entries = source_manifest.assets
	if source_manifest.get("status", "") == "incomplete_usage_limit":
		_fail("Kit incomplete: see assets/ui/pixel_simple_v1/STATUS.md before exporting.")
		return
	for entry: Dictionary in _entries:
		var name: String = entry.name
		var source := Image.load_from_file(ROOT + "source/" + name + ".png")
		if source == null:
			_fail("Missing source: " + name)
			return
		if entry.folder != "backgrounds" and not source.detect_alpha():
			_fail("Transparent alpha missing: " + name)
			return
		var target := Vector2i(int(entry.size[0]), int(entry.size[1]))
		source.convert(Image.FORMAT_RGBA8)
		var sprite := source
		# Preserve native logical grids and transparent safety margins exactly.
		# Legacy generated sheets may still need their requested crop/scale.
		if source.get_size() != target:
			var bounds := _visible_bounds(source)
			if bounds.size.x == 0 or bounds.size.y == 0:
				_fail("Empty asset: " + name)
				return
			sprite = source.get_region(bounds)
			var is_icon: bool = entry.folder in ["icons", "equipment", "shop", "navigation"] or name in ["level", "add"]
			if is_icon:
				var inner := target - Vector2i(4, 4)
				var factor := minf(float(inner.x) / sprite.get_width(), float(inner.y) / sprite.get_height())
				sprite.resize(maxi(1, roundi(sprite.get_width() * factor)), maxi(1, roundi(sprite.get_height() * factor)), Image.INTERPOLATE_NEAREST)
				var padded := Image.create(target.x, target.y, false, Image.FORMAT_RGBA8)
				padded.fill(Color.TRANSPARENT)
				padded.blend_rect(sprite, Rect2i(Vector2i.ZERO, sprite.get_size()), (target - sprite.get_size()) / 2)
				sprite = padded
			else:
				sprite.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
		# Final exports use a binary alpha edge on the native pixel grid.
		# Low-alpha edge haze must not become blurry UI outlines when scaled.
		for y in sprite.get_height():
			for x in sprite.get_width():
				var pixel := sprite.get_pixel(x, y)
				pixel.a = 1.0 if pixel.a >= 0.5 else 0.0
				sprite.set_pixel(x, y, pixel)
		var path: String = ROOT + entry.folder + "/" + name + ".png"
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		if sprite.save_png(path) != OK:
			_fail("Cannot save: " + path)
			return
		_images[name] = sprite
		entry["file"] = path.trim_prefix(ROOT)
		entry["width"] = sprite.get_width()
		entry["height"] = sprite.get_height()
	_build_states()
	_build_previews()
	var manifest := FileAccess.open(ROOT + "manifest.json", FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"assets": _entries, "filter": "nearest", "scale": "integer multiples preferred", "bar_states": [0, 25, 50, 75, 100]}, "\t"))
	print("Pixel UI: %d base assets exported; 15 bar states and category previews generated." % _entries.size())
	quit()

func _visible_bounds(source: Image) -> Rect2i:
	var left := source.get_width()
	var top := source.get_height()
	var right := -1
	var bottom := -1
	for y in source.get_height():
		for x in source.get_width():
			if source.get_pixel(x, y).a >= 0.5:
				left = mini(left, x)
				top = mini(top, y)
				right = maxi(right, x)
				bottom = maxi(bottom, y)
	if right < left:
		return Rect2i()
	return Rect2i(left, top, right - left + 1, bottom - top + 1)

func _build_states() -> void:
	DirAccess.make_dir_recursive_absolute(ROOT + "states")
	for kind in ["xp", "energy", "health"]:
		for step in range(5):
			var track: Image = _images["bar_track"].duplicate()
			var fill: Image = _images["fill_" + kind].duplicate()
			fill.resize(88, 10, Image.INTERPOLATE_NEAREST)
			var width := roundi(88.0 * step / 4.0)
			if width > 0:
				track.blend_rect(fill, Rect2i(0, 0, width, 10), Vector2i(4, 3))
			track.save_png(ROOT + "states/%s_%03d.png" % [kind, step * 25])

func _build_previews() -> void:
	DirAccess.make_dir_recursive_absolute(ROOT + "previews")
	for group in ["frames", "hud", "buttons", "bars", "icons", "shop", "equipment", "navigation", "backgrounds"]:
		var items: Array = _entries.filter(func(e: Dictionary): return e.folder == group)
		var columns := 3
		var rows := ceili(float(items.size()) / columns)
		var sheet := Image.create(960, maxi(rows, 1) * 240, false, Image.FORMAT_RGBA8)
		sheet.fill(Color("101321"))
		for i in items.size():
			var sprite: Image = _images[items[i].name].duplicate()
			var factor := maxi(1, mini(4, mini(288 / sprite.get_width(), 208 / sprite.get_height())))
			sprite.resize(sprite.get_width() * factor, sprite.get_height() * factor, Image.INTERPOLATE_NEAREST)
			var cell := Vector2i((i % columns) * 320, (i / columns) * 240)
			var pos := cell + (Vector2i(320, 240) - sprite.get_size()) / 2
			sheet.blend_rect(sprite, Rect2i(Vector2i.ZERO, sprite.get_size()), pos)
		if not items.is_empty():
			sheet.save_png(ROOT + "previews/" + group + ".png")
	var bars := Image.create(960, 440, false, Image.FORMAT_RGBA8)
	bars.fill(Color("101321"))
	for column in range(3):
		var kind: String = ["xp", "energy", "health"][column]
		for step in range(5):
			var state := Image.load_from_file(ROOT + "states/%s_%03d.png" % [kind, step * 25])
			state.resize(288, 48, Image.INTERPOLATE_NEAREST)
			bars.blend_rect(state, Rect2i(Vector2i.ZERO, state.get_size()), Vector2i(16 + column * 320, 20 + step * 84))
	bars.save_png(ROOT + "previews/fill_states.png")

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
