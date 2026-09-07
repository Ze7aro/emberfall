extends Control

func _ready() -> void:
	var selection := $CharacterSelection
	if GameState.selected_character_id != &"":
		selection.focus_character(GameState.selected_character_id)
	selection.character_selected.connect(_on_character_selected)

func _on_character_selected(character_id: StringName) -> void:
	var selection := $CharacterSelection
	var texture_path := ""
	for character in selection.characters:
		if StringName(character.get("id", "")) == character_id:
			texture_path = str(character.get("texture", ""))
			break
	GameState.set_selected_character(character_id, texture_path)
