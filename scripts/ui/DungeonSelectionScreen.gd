extends Control

const DUNGEONS: Array[Dictionary] = [
	{"id": &"crimson_catacombs", "name": "CATACUMBAS CARMESÍ", "chapter": 1, "level": 1, "rewards": "Oro · Gema", "preview": "res://assets/environment/game_bg.png", "required": 0},
	{"id": &"obsidian_depths", "name": "PROFUNDIDADES DE OBSIDIANA", "chapter": 2, "level": 1, "rewards": "Oro · Reliquia · Cofre", "preview": "res://assets/environment/world_map.png", "required": 5},
	{"id": &"withered_sanctum", "name": "SANTUARIO MARCHITO", "chapter": 3, "level": 1, "rewards": "Oro · Núcleo · Gema", "preview": "res://assets/environment/game_bg.png", "required": 12},
]

func _ready() -> void:
	var map_selection := $MapSelection
	map_selection.set_maps(DUNGEONS)
	map_selection.previous_map_requested.connect(map_selection.show_previous_map)
	map_selection.next_map_requested.connect(map_selection.show_next_map)
	map_selection.start_map_requested.connect(_on_start_map_requested)

func _on_start_map_requested(map_id: StringName) -> void:
	var main_layout := _find_main_layout()
	if main_layout:
		main_layout.start_run(map_id)

func _find_main_layout() -> Node:
	var node := get_parent()
	while node:
		if node.has_method("start_run"):
			return node
		node = node.get_parent()
	return null
