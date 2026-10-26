extends Control

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

const MAX_UPGRADE_LEVEL := 10

## Each branch grows straight down from its own root: same stat the old
## flat buttons controlled, just presented as a tree of purchase steps.
const BRANCHES := [
	{"key": "health", "name": "VITALIDAD", "shape": UpgradeNode.Shape.CIRCLE, "color": Color("e65a7a")},
	{"key": "damage", "name": "PODER", "shape": UpgradeNode.Shape.DIAMOND, "color": Color("ff9f4a")},
	{"key": "speed", "name": "MOVILIDAD", "shape": UpgradeNode.Shape.HEX, "color": UiTheme.ACCENT},
]

const BRANCH_ICONS := {
	"health": "res://assets/ui/pixel_simple_v1/icons/heart.png",
	"damage": "res://assets/ui/pixel_simple_v1/equipment/weapon.png",
	"speed": "res://assets/ui/pixel_simple_v1/icons/speed.png",
}

var _gold_label: Label
var _tree_row: HBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.make_theme()
	var bg := ColorRect.new(); bg.color = UiTheme.BG_DEEP; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var art := UiTheme.background("bg_mejoras.png", 0.6)
	if art != null:
		add_child(art)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 15; root.offset_right = -15; root.offset_top = UiTheme.CONTENT_TOP; root.offset_bottom = -124
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	root.add_child(UiTheme.header("PROGRESO", "CRECE. EVOLUCIONA. SOBREVIVE.", 30, "mejoras_header.png"))

	var upgrades := _build_permanent_tab()
	upgrades.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(upgrades)

	GameState.gold_changed.connect(func(_v): _refresh_permanent())
	_refresh_permanent()

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
	title.text = "%s\nNV. %d/%d" % [str(branch.get("name", "")), GameState.get_upgrade_level(str(branch.get("key", ""))), MAX_UPGRADE_LEVEL]
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
		var icon_path: String = BRANCH_ICONS.get(kind, "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			node.icon_texture = load(icon_path) as Texture2D
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
		label.add_theme_color_override("font_color", UiTheme.ACCENT)
	elif index == current_level:
		label.text = str(40 + current_level * 35)
		label.add_theme_color_override("font_color", UiTheme.TEXT)
	else:
		label.text = ""
	return label
