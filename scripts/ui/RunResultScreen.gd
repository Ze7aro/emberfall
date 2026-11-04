extends Control
class_name RunResultScreen

## End-of-run summary, kept short: time/kills/level, one rewards line, the
## top 3 damage sources and the next unlock goal. Reads
## GameState.last_run_summary (game_world.end_run) and
## GameState.last_run_rewards (finish_run).

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

signal retry_pressed
signal home_pressed

const GOLD := Color("ffd166")
const RANKING_ROWS := 3
const FOOTER_CLEARANCE := 122.0
## Damage sources that aren't abilities in AbilityCatalog.
const EXTRA_SOURCES := {
	"basic": {"name": "ATAQUE BÁSICO", "color": Color("ecedf4"), "icon_from": ""},
	"burn": {"name": "QUEMADURAS", "color": Color("ff9f4a"), "icon_from": "fire"},
	"poison": {"name": "VENENO", "color": Color("7ddc4a"), "icon_from": "poison_bomb"},
	"bomb": {"name": "BOMBA", "color": Color("d96168"), "icon_from": ""},
}

var victory := false
var _retry: Button

func setup(is_victory: bool) -> void:
	victory = is_victory

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.make_theme()
	var bg := ColorRect.new()
	bg.color = UiTheme.BG_DEEP
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var art := UiTheme.background("bg_victoria.png" if victory else "bg_derrota.png", 0.6)
	if art != null:
		add_child(art)
	var accent: Color = UiTheme.ACCENT if victory else UiTheme.DANGER
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Between the top HUD and the navigation footer (both stay visible here).
	card.offset_left = 14; card.offset_right = -14
	card.offset_top = UiTheme.CONTENT_TOP; card.offset_bottom = -FOOTER_CLEARANCE
	card.add_theme_stylebox_override("panel", UiTheme.kit("panel_modal", UiTheme.panel(accent, UiTheme.CORNER, 4)))
	card.self_modulate = Color.WHITE if victory else Color(1.0, 0.8, 0.8)
	add_child(card)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var summary: Dictionary = GameState.last_run_summary
	var rewards: Dictionary = GameState.last_run_rewards
	box.add_child(_label("VICTORIA" if victory else "CAÍSTE", 34, accent))
	var stage_name := str(GameState.last_stage_context.get("name", ""))
	if stage_name != "":
		box.add_child(_label(stage_name, 13, UiTheme.PURPLE))
	box.add_child(_stats_row(summary))
	box.add_child(_label(_rewards_text(summary, rewards), 14, GOLD))
	var loot: Array = (summary.get("loot", []) as Array) + (rewards.get("items", []) as Array)
	if not loot.is_empty():
		box.add_child(_loot_row(loot))
	var unlocked: Array = summary.get("unlocked", [])
	if not unlocked.is_empty():
		var names := PackedStringArray()
		for id in unlocked:
			names.append(AbilityCatalog.display_name(str(id)))
		var unlock_label := _label("¡Desbloqueaste: %s!" % ", ".join(names), 14, UiTheme.ACCENT)
		unlock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(unlock_label)
	box.add_child(_ranking(summary))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	var goal := GameState.next_unlock_goal()
	if not goal.is_empty():
		var goal_label := _label("Próximo: %s (%d/%d)" % [str(goal["text"]), mini(int(goal["current"]), int(goal["target"])), int(goal["target"])], 12, UiTheme.TEXT_MUTED)
		goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(goal_label)
	box.add_child(_buttons())

## Labels never wrap unless the caller asks: inside rows without a fixed
## width, wrapping squeezes them to one character per line.
func _label(text: String, font_size: int, color: Color, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _stats_row(summary: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var seconds := int(summary.get("time", 0))
	var cells := [
		["TIEMPO", "%d:%02d" % [seconds / 60, seconds % 60]],
		["BAJAS", str(int(summary.get("kills", 0)))],
		["NIVEL", str(int(summary.get("level", 1)))],
	]
	for cell in cells:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", UiTheme.slot(false, 8))
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 0)
		column.add_child(_label(str(cell[0]), 11, UiTheme.TEXT_MUTED))
		column.add_child(_label(str(cell[1]), 22, UiTheme.TEXT))
		panel.add_child(column)
		row.add_child(panel)
	return row

func _rewards_text(summary: Dictionary, rewards: Dictionary) -> String:
	var gold := int(summary.get("gold_collected", 0)) + int(rewards.get("gold", 0))
	var parts := PackedStringArray(["+%d ORO" % gold])
	if int(rewards.get("gems", 0)) > 0:
		parts.append("+%d GEMAS" % int(rewards.get("gems", 0)))
	if int(rewards.get("essence", 0)) > 0:
		parts.append("+%d ESENCIA" % int(rewards.get("essence", 0)))
	parts.append("+%d EXP" % int(rewards.get("xp", 0)))
	return "  ·  ".join(parts)

## Equipment found this run (kept even after a defeat), best first.
func _loot_row(loot: Array) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_child(_label("BOTÍN", 13, UiTheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	var items := loot.duplicate()
	items.sort_custom(func(a, b): return EquipmentCatalog.rarity_index(str(a.get("rarity", ""))) > EquipmentCatalog.rarity_index(str(b.get("rarity", ""))))
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 6)
	box.add_child(row)
	for item in items:
		var slot := EquipmentSlot.new()
		slot.custom_minimum_size = Vector2(52, 52)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.set_item(EquipmentCatalog.icon(item), str(item.get("rarity", "common")), "", false, false, 0)
		row.add_child(slot)
	return box

func _ranking(summary: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(_label("MÁS DAÑO", 13, UiTheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	var damage: Dictionary = summary.get("damage", {})
	var evolved: Array = summary.get("evolved", [])
	var ids: Array = damage.keys()
	ids.sort_custom(func(a, b): return int(damage[a]) > int(damage[b]))
	var total := 0
	for id in ids:
		total += int(damage[id])
	for i in mini(RANKING_ROWS, ids.size()):
		var id := str(ids[i])
		box.add_child(_ranking_row(id, float(damage[id]) / maxf(1.0, float(total)), evolved.has(id)))
	return box

func _ranking_row(id: String, share: float, is_evolved: bool) -> Control:
	var extra: Dictionary = EXTRA_SOURCES.get(id, {})
	var color: Color = extra.get("color", AbilityCatalog.color(id))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_icon(id, extra, color, is_evolved))
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 3)
	var line := HBoxContainer.new()
	var name_text := str(extra.get("name", "")) if not extra.is_empty() else AbilityCatalog.display_name(id, is_evolved)
	var name_label := _label(name_text, 12, UiTheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	line.add_child(name_label)
	line.add_child(_label("%d%%" % int(round(share * 100.0)), 12, color, HORIZONTAL_ALIGNMENT_RIGHT))
	column.add_child(line)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 6)
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.step = 0.0
	bar.value = clampf(share, 0.0, 1.0)
	bar.add_theme_stylebox_override("background", UiTheme.bar(UiTheme.BG_SLOT))
	bar.add_theme_stylebox_override("fill", UiTheme.bar(color))
	column.add_child(bar)
	row.add_child(column)
	return row

func _icon(id: String, extra: Dictionary, color: Color, is_evolved: bool) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(26, 26)
	var icon_id := str(extra.get("icon_from", id)) if not extra.is_empty() else id
	var texture: Texture2D = AbilityCatalog.icon(icon_id, is_evolved) if icon_id != "" else null
	if texture != null:
		var icon := TextureRect.new()
		icon.texture = texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.add_child(icon)
	else:
		var dot := ColorRect.new()
		dot.color = color
		dot.position = Vector2(7, 7)
		dot.size = Vector2(12, 12)
		holder.add_child(dot)
	return holder

func _buttons() -> HBoxContainer:
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	var home := Button.new()
	home.text = "VOLVER\nA INICIO"
	home.custom_minimum_size = Vector2(0, 52)
	home.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home.pressed.connect(func(): home_pressed.emit())
	buttons.add_child(home)
	_retry = Button.new()
	_retry.text = "REINTENTAR\n%d ENERGÍA" % GameState.ENERGY_COST
	_retry.icon = load("res://assets/ui/icons/refresh.png") as Texture2D
	_retry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTheme.apply_primary(_retry)
	_retry.custom_minimum_size = Vector2(0, 52)
	_retry.disabled = not GameState.can_start()
	_retry.pressed.connect(func(): retry_pressed.emit())
	buttons.add_child(_retry)
	# Energy can regenerate while this screen is open.
	GameState.energy_changed.connect(_on_energy_changed)
	return buttons

func _on_energy_changed(_energy: int) -> void:
	if is_instance_valid(_retry):
		_retry.disabled = not GameState.can_start()

func _exit_tree() -> void:
	if GameState.energy_changed.is_connected(_on_energy_changed):
		GameState.energy_changed.disconnect(_on_energy_changed)
