extends SceneTree
## Deterministic packaging only: preserve generated alpha, trim margins,
## resize individual exports, and compose explicit fill-state previews.

const ROOT := "res://assets/ui/TopHUD/modular_v3_simple/"
const SIZES := {
	"frame": Vector2i(1800, 300),
	"level": Vector2i(256, 256),
	"track": Vector2i(512, 104),
	"xp_fill": Vector2i(512, 104),
	"energy_fill": Vector2i(512, 104),
	"energy_icon": Vector2i(128, 128),
	"coin_icon": Vector2i(128, 128),
	"gem_icon": Vector2i(128, 128),
	"add": Vector2i(128, 128),
}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ROOT + "states")
	var images: Dictionary = {}
	for asset: String in SIZES:
		var source := Image.load_from_file(ROOT + "source/" + asset + ".png")
		if source == null or not source.detect_alpha():
			push_error("Missing image or transparent alpha: " + asset)
			quit(1)
			return
		var trimmed := source.get_region(_visible_bounds(source))
		var target: Vector2i = SIZES[asset]
		if asset in ["level", "energy_icon", "coin_icon", "gem_icon", "add"]:
			var factor := minf(float(target.x) / trimmed.get_width(), float(target.y) / trimmed.get_height())
			trimmed.resize(roundi(trimmed.get_width() * factor), roundi(trimmed.get_height() * factor), Image.INTERPOLATE_LANCZOS)
			var square := Image.create(target.x, target.y, false, Image.FORMAT_RGBA8)
			square.fill(Color.TRANSPARENT)
			var position := Vector2i((target - trimmed.get_size()) / 2)
			square.blend_rect(trimmed, Rect2i(Vector2i.ZERO, trimmed.get_size()), position)
			trimmed = square
		else:
			trimmed.resize(target.x, target.y, Image.INTERPOLATE_LANCZOS)
		trimmed.save_png(ROOT + asset + ".png")
		images[asset] = trimmed
	var sheet := Image.create(1200, 820, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("101624"))
	var frame: Image = images["frame"].duplicate()
	frame.resize(1160, 194, Image.INTERPOLATE_LANCZOS)
	sheet.blend_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(20, 55))
	var x := 70
	for asset in ["level", "energy_icon", "coin_icon", "gem_icon", "add"]:
		var icon: Image = images[asset].duplicate()
		icon.resize(96, 96, Image.INTERPOLATE_LANCZOS)
		sheet.blend_rect(icon, Rect2i(Vector2i.ZERO, icon.get_size()), Vector2i(x, 320))
		x += 235
	for kind in ["xp", "energy"]:
		for step in range(5):
			var bar: Image = images["track"].duplicate()
			var fill: Image = images[kind + "_fill"].duplicate()
			fill.resize(466, 62, Image.INTERPOLATE_LANCZOS)
			var width := roundi(466.0 * step / 4.0)
			if width > 0:
				bar.blend_rect(fill, Rect2i(0, 0, width, 62), Vector2i(23, 21))
			bar.save_png(ROOT + "states/%s_%03d.png" % [kind, step * 25])
			bar.resize(512, 64, Image.INTERPOLATE_LANCZOS)
			var column := 42 if kind == "xp" else 646
			sheet.blend_rect(bar, Rect2i(Vector2i.ZERO, bar.get_size()), Vector2i(column, 440 + step * 72))
	sheet.save_png(ROOT + "preview.png")
	print("TopHUD pack: 9 assets, 10 fill states, transparent alpha checked.")
	quit()

func _visible_bounds(source: Image) -> Rect2i:
	# Ignore near-invisible generator pixels when determining the export bounds.
	# Keep original alpha inside the crop, including antialiased edges.
	var left := source.get_width()
	var top := source.get_height()
	var right := 0
	var bottom := 0
	for y in range(0, source.get_height(), 2):
		for x in range(0, source.get_width(), 2):
			if source.get_pixel(x, y).a > 0.15:
				left = mini(left, x)
				top = mini(top, y)
				right = maxi(right, x)
				bottom = maxi(bottom, y)
	return Rect2i(left - 2, top - 2, right - left + 5, bottom - top + 5).intersection(Rect2i(Vector2i.ZERO, source.get_size()))
