extends Control

func _ready() -> void:
	var map_selection := $MapSelection
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
