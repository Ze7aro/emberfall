extends Control

const STAGE_NAMES := [
	"CRIPTAS DEL VACÍO", "RUINAS VERDANTES", "FORJA DE EMBER", "BOSQUE CENIZO",
	"CAVERNAS ROTAS", "TORRE OLVIDADA", "PANTANO NEGRO", "CUMBRE HELADA",
	"FOSA DE MAGMA", "TRONO DE EMBERFALL",
]
const STAGE_PREVIEWS := ["res://assets/environment/game_bg.png", "res://assets/environment/world_map.png"]

func _ready() -> void:
	var map_selection := $MapSelection
	map_selection.unlock_check = func(data: Dictionary) -> bool:
		return GameState.is_stage_unlocked(int(data.get("index", 1)))
	map_selection.set_maps(_build_stages())
	map_selection.previous_map_requested.connect(map_selection.show_previous_map)
	map_selection.next_map_requested.connect(map_selection.show_next_map)
	map_selection.start_map_requested.connect(_on_start_map_requested)

func _build_stages() -> Array[Dictionary]:
	var stages: Array[Dictionary] = []
	for i in GameState.STAGE_COUNT:
		var index := i + 1
		stages.append({
			"id": StringName("stage_%02d" % index),
			"type": "stage",
			"index": index,
			"name": STAGE_NAMES[i],
			"chapter": 1 + (i / 4),
			"level": index,
			"preview": STAGE_PREVIEWS[i % STAGE_PREVIEWS.size()],
			"gold_reward": 40 + index * 20,
			"gems_reward": 1 + index / 2,
		})
	return stages

func _on_start_map_requested(data: Dictionary) -> void:
	var main_layout := _find_main_layout()
	if main_layout:
		main_layout.start_run(data)

func _find_main_layout() -> Node:
	var node := get_parent()
	while node:
		if node.has_method("start_run"):
			return node
		node = node.get_parent()
	return null
