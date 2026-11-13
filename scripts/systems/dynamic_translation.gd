extends Translation
## Traducción español -> inglés resuelta en el momento.
##
## Godot llama a _get_message() con el texto que un Control está por mostrar.
## Además de la búsqueda exacta, resuelve los textos armados en el código:
##   - mayúsculas / título distintos de la clave ("Misiones" con clave "MISIONES")
##   - plantillas con formato ("NIVEL %d" cubre "NIVEL 7")
##   - varias líneas, y partes separadas por " · "
## Lo que no reconoce se devuelve vacío y Godot muestra el original.

const Table := preload("res://scripts/data/translations_en.gd")

const CACHE_LIMIT := 6000
const MINOR_WORDS := ["a", "an", "the", "of", "and", "or", "to", "in", "on", "for", "with", "at", "by", "from", "per"]

var _exact: Dictionary = {}
var _upper: Dictionary = {}
## [{regex: RegEx, target: String, kinds: Array[String]}], literal más largo primero.
var _patterns: Array = []
var _cache: Dictionary = {}
var _placeholder := RegEx.create_from_string("%(%|[-+0]*\\d*(?:\\.\\d+)?[sdf])")
var _separator := RegEx.create_from_string("\\s+·\\s+")
var _letters := RegEx.create_from_string("[A-Za-zÁÉÍÓÚÑáéíóúñ]{2}")
var _number_prefix := RegEx.create_from_string("^([-+]?[\\d.,½]+\\s*%?(?:/min)?\\s+)(\\S[\\s\\S]*)$")

func _init() -> void:
	var with_length: Array = []
	var entries: Array = []
	for source in Table.TABLE:
		var target := str(Table.TABLE[source])
		entries.append([str(source), target])
		# Un texto de varias líneas también se registra línea por línea,
		# porque los textos armados se traducen de a una línea.
		var source_lines := str(source).split("\n")
		var target_lines := target.split("\n")
		if source_lines.size() > 1 and source_lines.size() == target_lines.size():
			for i in source_lines.size():
				if not Table.TABLE.has(source_lines[i]):
					entries.append([source_lines[i], target_lines[i]])
	for entry in entries:
		var source: String = entry[0]
		var target: String = entry[1]
		_exact[source] = target
		_upper[source.to_upper()] = target
		if not source.contains("\n") and _placeholder.search(source) != null:
			var compiled := _compile(source, target)
			if not compiled.is_empty():
				with_length.append(compiled)
	with_length.sort_custom(func(a, b): return int(a.weight) > int(b.weight))
	_patterns = with_length

func _get_message(src_message: StringName, _context: StringName) -> StringName:
	var source := str(src_message)
	if source.is_empty():
		return &""
	if _cache.has(source):
		return _cache[source]
	var result := _translate(source, 0)
	if _cache.size() > CACHE_LIMIT:
		_cache.clear()
	var value := StringName(result) if result != source else &""
	_cache[source] = value
	return value

func _get_plural_message(src_message: StringName, _src_plural: StringName, _n: int, context: StringName) -> StringName:
	return _get_message(src_message, context)

## Devuelve la traducción, o el mismo texto si no hay ninguna.
func _translate(source: String, depth: int) -> String:
	if depth > 4 or _letters.search(source) == null:
		return source
	if _exact.has(source):
		return _exact[source]
	var trimmed := source.strip_edges()
	if trimmed != source and not trimmed.is_empty():
		var inner := _translate(trimmed, depth + 1)
		return source.replace(trimmed, inner) if inner != trimmed else source
	var key := source.to_upper()
	if _upper.has(key):
		return _match_case(source, _upper[key])
	if source.contains("\n"):
		var lines := source.split("\n")
		var out: PackedStringArray = []
		for line in lines:
			out.append(_translate(line, depth + 1))
		return "\n".join(out)
	for pattern in _patterns:
		var found: RegExMatch = pattern.regex.search(source)
		if found == null:
			continue
		var values: Array = []
		for i in pattern.kinds.size():
			var captured := found.get_string(i + 1)
			values.append(_translate(captured, depth + 1) if pattern.kinds[i] == "s" else captured)
		return _fill(pattern.target, values)
	if _separator.search(source) != null:
		var pieces: PackedStringArray = []
		var last := 0
		for found in _separator.search_all(source):
			pieces.append(_translate(source.substr(last, found.get_start() - last), depth + 1))
			pieces.append(found.get_string())
			last = found.get_end()
		pieces.append(_translate(source.substr(last), depth + 1))
		return "".join(pieces)
	# "+12% Crítico": un número delante de un texto conocido.
	var numbered := _number_prefix.search(source)
	if numbered != null:
		var rest := numbered.get_string(2)
		var translated := _translate(rest, depth + 1)
		if translated != rest:
			return numbered.get_string(1) + translated
	# Lista separada por comas: solo si se reconocen todas las partes.
	if source.contains(", "):
		var items: PackedStringArray = []
		for item in source.split(", "):
			var translated := _translate(item, depth + 1)
			if translated == item and _letters.search(item) != null:
				return source
			items.append(translated)
		return ", ".join(items)
	return source

## "%d oro" -> ^(\d+) oro$. Cada marcador se vuelve un grupo de captura.
func _compile(source: String, target: String) -> Dictionary:
	var expression := "^"
	var kinds: Array[String] = []
	var literal := 0
	var last := 0
	for found in _placeholder.search_all(source):
		var text := source.substr(last, found.get_start() - last)
		literal += text.length()
		expression += _escape(text)
		var spec := found.get_string()
		last = found.get_end()
		if spec == "%%":
			expression += "%"
			literal += 1
			continue
		var kind := spec.right(1)
		kinds.append(kind)
		match kind:
			"d": expression += "([-+]?\\d+)"
			"f": expression += "([-+]?\\d+(?:[.,]\\d+)?)"
			_: expression += "([\\s\\S]*?)"
	var tail := source.substr(last)
	literal += tail.length()
	expression += _escape(tail) + "$"
	if kinds.is_empty() or literal == 0:
		return {}
	var regex := RegEx.new()
	if regex.compile(expression) != OK:
		push_warning("Localization: plantilla inválida: %s" % source)
		return {}
	return {"regex": regex, "target": target, "kinds": kinds, "weight": literal}

## Rellena la plantilla inglesa: por posición, o con {0} {1} si cambia el orden.
func _fill(target: String, values: Array) -> String:
	if target.contains("{0}"):
		var ordered := target
		for i in values.size():
			ordered = ordered.replace("{%d}" % i, str(values[i]))
		return ordered.replace("%%", "%")
	var out := ""
	var last := 0
	var index := 0
	for found in _placeholder.search_all(target):
		out += target.substr(last, found.get_start() - last)
		last = found.get_end()
		if found.get_string() == "%%":
			out += "%"
		elif index < values.size():
			out += str(values[index])
			index += 1
	return out + target.substr(last)

func _match_case(source: String, target: String) -> String:
	if source == source.to_upper():
		return target.to_upper()
	if source == source.to_lower():
		return target.to_lower()
	var words := source.split(" ", false)
	var titled := words.size() > 1
	for word in words:
		if word.length() > 3 and word.substr(0, 1) != word.substr(0, 1).to_upper():
			titled = false
	if not titled:
		# Oración: primera letra en mayúscula, el resto en minúscula.
		return target.substr(0, 1).to_upper() + target.substr(1).to_lower() if target == target.to_upper() else target
	var out: PackedStringArray = []
	for word in target.to_lower().split(" ", false):
		if out.is_empty() or not MINOR_WORDS.has(word):
			word = word.substr(0, 1).to_upper() + word.substr(1)
		out.append(word)
	return " ".join(out)

func _escape(text: String) -> String:
	var out := ""
	for character in text:
		if "\\^$.|?*+()[]{}".contains(character):
			out += "\\"
		out += character
	return out
