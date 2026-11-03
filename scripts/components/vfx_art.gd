class_name EmberfallVfxArt
extends RefCounted

## Sprite art for the few effects that use it (assets/vfx): enemy death,
## status badges, the familiar and the axe. Everything else is drawn in code.
## Missing files just return empty, so callers keep their drawn fallback.

const DIR := "res://assets/habilidades/efectos/"
static var _cache := {}

## frame_00.png, frame_01.png… of one folder, in order.
static func frames(folder: String) -> Array:
	if _cache.has(folder):
		return _cache[folder]
	var found: Array = []
	var i := 0
	while ResourceLoader.exists("%s%s/frame_%02d.png" % [DIR, folder, i]):
		found.append(load("%s%s/frame_%02d.png" % [DIR, folder, i]))
		i += 1
	_cache[folder] = found
	return found

## A single named image (e.g. estados/burn.png), or null.
static func image(path: String) -> Texture2D:
	if not _cache.has(path):
		_cache[path] = load(DIR + path) if ResourceLoader.exists(DIR + path) else null
	return _cache[path]
