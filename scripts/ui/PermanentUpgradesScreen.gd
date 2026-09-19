extends Control

const MAX_UPGRADE_LEVEL := 10

## Each branch grows straight down from its own root: same stat the old
## flat buttons controlled, just presented as a tree of purchase steps.
const BRANCHES := [
	{"key": "health", "name": "VITALIDAD", "shape": UpgradeNode.Shape.CIRCLE, "color": Color("e65a7a")},
	{"key": "damage", "name": "PODER", "shape": UpgradeNode.Shape.DIAMOND, "color": Color("ff9f4a")},
	{"key": "speed", "name": "MOVILIDAD", "shape": UpgradeNode.Shape.HEX, "color": Color("20e6bd")},
]

var _gold_label: Label
var _tree_row: HBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new(); bg.color = Color("101a2b"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)

	var root := VBoxContainer.new()
	root.anchor_left = 0.5; root.anchor_right = 0.5; root.anchor_top = 0.5; root.anchor_bottom = 0.5
	root.offset_left = -180; root.offset_right = 180; root.offset_top = -240; root.offset_bottom = 240
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var title := Label.new()
	title.text = "HÉROE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("20e6bd"))
	root.add_child(title)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)

	tabs.add_child(_build_characters_tab())
	tabs.add_child(_build_permanent_tab())

	GameState.gold_changed.connect(func(_v): _refresh_permanent())
	_refresh_permanent()

func _build_characters_tab() -> Control:
	var tab := VBoxContainer.new()
	tab.name = "PERSONAJES"
	var screen := preload("res://scenes/ui/CharacterEquipmentScreen.tscn").instantiate()
	screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab.add_child(screen)
	return tab

func _build_permanent_tab() -> Control:
	var tab := VBoxContainer.new()
	tab.name = "ÁRBOL DE MEJORAS"
	tab.add_theme_constant_override("separation", 8)

	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tab.add_child(_gold_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab.add_child(scroll)

	_tree_row = HBoxContainer.new()
	_tree_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_tree_row.add_theme_constant_override("separation", 20)
	_tree_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_tree_row)
	return tab

func _buy_upgrade(kind: String) -> void:
	GameState.buy_upgrade(kind)
	_refresh_permanent()

func _refresh_permanent() -> void:
	_gold_label.text = "ORO DISPONIBLE: %d" % GameState.gold
	for child in _tree_row.get_children():
		child.queue_free()
	for branch in BRANCHES:
		_tree_row.add_child(_build_branch_lane(branch))

## Builds one branch as a straight vertical chain: purchased nodes below the
## root, one clickable "available" node at the frontier, then locked nodes
## dimmed out below it. The last node in the branch is the milestone.
func _build_branch_lane(branch: Dictionary) -> Control:
	var lane := VBoxContainer.new()
	lane.add_theme_constant_override("separation", 0)
	lane.custom_minimum_size.x = 92

	var title := Label.new()
	title.text = str(branch.get("name", ""))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", branch.get("color", Color.WHITE))
	lane.add_child(title)

	var kind: String = branch.get("key", "")
	var level := GameState.get_upgrade_level(kind)
	var color: Color = branch.get("color", Color.WHITE)

	for i in MAX_UPGRADE_LEVEL:
		if i > 0:
			lane.add_child(_build_connector(i <= level, color))

		var node := UpgradeNode.new()
		node.shape = branch.get("shape", UpgradeNode.Shape.CIRCLE)
		node.accent_color = color
		node.is_milestone = i == MAX_UPGRADE_LEVEL - 1
		if i < level:
			node.set_state(UpgradeNode.STATE_PURCHASED)
		elif i == level:
			node.set_state(UpgradeNode.STATE_AVAILABLE)
			node.modulate.a = 1.0 if GameState.gold >= 40 + level * 35 else 0.5
			node.pressed.connect(_buy_upgrade.bind(kind))
		else:
			node.set_state(UpgradeNode.STATE_LOCKED)
		var node_center := CenterContainer.new()
		node_center.add_child(node)
		lane.add_child(node_center)

		lane.add_child(_build_step_label(i, level, kind))
	return lane

func _build_connector(filled: bool, color: Color) -> Control:
	var wrap := CenterContainer.new()
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(4, 18)
	line.color = color if filled else Color("332a40")
	wrap.add_child(line)
	return wrap

func _build_step_label(index: int, current_level: int, kind: String) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	if index < current_level:
		label.text = "✓"
		label.add_theme_color_override("font_color", Color("20e6bd"))
	elif index == current_level:
		label.text = str(40 + current_level * 35)
		label.add_theme_color_override("font_color", Color("d8c9ed"))
	else:
		label.text = ""
	return label

