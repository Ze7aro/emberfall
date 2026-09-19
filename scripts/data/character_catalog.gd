class_name CharacterCatalog
extends RefCounted

## Explicit list of every playable hero resource. Both GameState and
## CharacterEquipmentScreen used to scan res://resources/characters/ at
## runtime via DirAccess — the Godot docs warn resource paths and directory
## listings can behave differently once packed into an exported PCK/APK, so
## a new hero silently missing on Android would only surface after export.
## Adding a hero now means adding its path here too (see ROADMAP_LANZAMIENTO.md AUD-02).
const RESOURCE_PATHS: Array[String] = [
	"res://resources/characters/variante_01.tres",
	"res://resources/characters/variante_02.tres",
	"res://resources/characters/variante_03.tres",
	"res://resources/characters/variante_04.tres",
	"res://resources/characters/variante_05.tres",
	"res://resources/characters/variante_06.tres",
	"res://resources/characters/variante_07.tres",
	"res://resources/characters/variante_08.tres",
	"res://resources/characters/variante_09.tres",
	"res://resources/characters/variante_10.tres",
	"res://resources/characters/variante_11.tres",
	"res://resources/characters/variante_12.tres",
	"res://resources/characters/variante_13.tres",
	"res://resources/characters/variante_14.tres",
]

static func load_all() -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	for path in RESOURCE_PATHS:
		var data := load(path) as CharacterData
		if data == null:
			push_error("Emberfall: no se pudo cargar %s (revisar CharacterCatalog.RESOURCE_PATHS)" % path)
			continue
		result.append(data)
	return result
