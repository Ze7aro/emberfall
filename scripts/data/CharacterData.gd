class_name CharacterData
extends Resource

@export var id: StringName
@export var display_name := ""
@export var faction: StringName = &"humans"
@export var role := ""
@export var rarity: StringName = &"common"
@export var level := 1
@export var energy_cost := 3
@export var spawn_count := 1
@export var target_type: StringName = &"ground"
@export var damage_type: StringName = &"physical"
@export var portrait: Texture2D
@export var health := 100.0
@export var damage := 10.0
@export var attack_speed := 1.0
@export var movement_speed := 100.0
@export var attack_range := 100.0
@export var unlocked := true
