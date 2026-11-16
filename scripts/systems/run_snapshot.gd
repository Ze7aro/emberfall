class_name RunSnapshot
extends RefCounted

## RUN-RESUME: safe readers for the run snapshot stored in the save file.
## The snapshot round-trips through JSON (ints come back as floats, vectors
## are stored as [x, y]) and may be hand-edited or damaged, so every value is
## read through one of these instead of a bare int()/float(), which would
## abort the restore on a wrong type (see GameState._safe_int).

static func f(value: Variant, default: float) -> float:
	if value is int or value is float:
		var number := float(value)
		if not is_nan(number) and not is_inf(number):
			return number
	return default

static func i(value: Variant, default: int) -> int:
	if value is int:
		return value
	if value is float and not is_nan(value) and not is_inf(value):
		return int(value)
	return default

static func b(value: Variant, default: bool) -> bool:
	return value if value is bool else default

static func s(value: Variant, default: String) -> String:
	return str(value) if value is String or value is StringName else default

static func v2(value: Variant, default: Vector2 = Vector2.ZERO) -> Vector2:
	if value is Array and (value as Array).size() >= 2:
		return Vector2(f(value[0], default.x), f(value[1], default.y))
	return default

static func dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}

static func list(value: Variant) -> Array:
	return value if value is Array else []

## An array of exactly `size` entries (missing ones are null), so callers can
## index it without bounds checks.
static func arr(value: Variant, size: int) -> Array:
	var result: Array = list(value).slice(0, size)
	result.resize(size)
	return result

## {String: int} with non-negative values (skills, passives, kill tallies).
static func int_map(value: Variant) -> Dictionary:
	var result := {}
	for key in dict(value):
		var amount := i(value[key], -1)
		if amount >= 0:
			result[str(key)] = amount
	return result

## {String: float} (skill timers, equipment totals).
static func float_map(value: Variant) -> Dictionary:
	var result := {}
	for key in dict(value):
		result[str(key)] = f(value[key], 0.0)
	return result

## Strings only, without duplicates.
static func strings(value: Variant) -> Array[String]:
	var result: Array[String] = []
	for entry in list(value):
		if (entry is String or entry is StringName) and str(entry) not in result:
			result.append(str(entry))
	return result
