extends Control
class_name RunResultScreen

## End-of-run summary: time, kills, level, rewards, a damage ranking per
## ability and the next unlock goal. Reads GameState.last_run_summary (filled
## by game_world.end_run) and GameState.last_run_rewards (finish_run).

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

signal retry_pressed
signal home_pressed

const GOLD := Color("ffd166")
const RANKING_ROWS := 6
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
		margin.add_theme_constant_override("margin_" + side, 14)
	card.add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	margin.add_child(outer)

	var title := _label("VICTORIA" if victory else "CAÍSTE", 34, accent)
	outer.add_child(title)
	var stage_name := str(GameState.last_stage_context.get("name", ""))
	var subtitle := stage_name if stage_name != "" else ("Un paso más en tu leyenda." if victory else "Aún quedan batallas por librar.")
	outer.add_child(_label(subtitle, 13, UiTheme.PURPLE))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)

	var summary: Dictionary = GameState.last_run_summary
	var rewards: Dictionary = GameState.last_run_rewards
	body.add_child(_stats_grid(summary))
	body.add_child(_rewards_box(summary, rewards))
	var unlocked: Array = summary.get("unlocked", [])
	if not unlocked.is_empty():
		var names := PackedStringArray()
		for id in unlocked:
			names.append(AbilityCatalog.display_name(str(id)))
		body.add_child(_label("¡Nueva habilidad: %s!" % ", ".join(names), 15, GOLD))
	body.add_child(_ranking(summary))
	var goal := GameState.next_unlock_goal()
	if not goal.is_empty():
		body.add_child(_goal_box(goal))

	outer.add_child(_buttons())

func _label(text: String, font_size: int, color: Color, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _section(text: String) -> Label:
	return _label(text, 14, UiTheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT)

func _stats_grid(summary: Dictionary) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	var seconds := int(summary.get("time", 0))
	var cells := [
		["TIEMPO", "%d:%02d" % [seconds / 60, seconds % 60]],
		["BAJAS", str(int(summary.get("kills", 0)))],
		["NIVEL", str(int(summary.get("level", 1)))],
		["COFRES", str(int(summary.get("chests", 0)))],
	]
	for cell in cells:
		var box := PanelContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_stylebox_override("panel", UiTheme.slot(false, 8))
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 0)
		column.add_child(_label(str(cell[0]), 11, UiTheme.TEXT_MUTED))
		column.add_child(_label(str(cell[1]), 22, UiTheme.TEXT))
		box.add_child(column)
		grid.add_child(box)
	return grid

func _rewards_box(summary: Dictionary, rewards: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.add_child(_section("RECOMPENSAS"))
	var lines := PackedStringArray()
	lines.append("+%d oro recogido" % int(summary.get("gold_collected", 0)))
	if int(rewards.get("gold", 0)) > 0:
		lines.append("+%d oro de recompensa" % int(rewards.get("gold", 0)))
	if int(rewards.get("gems", 0)) > 0:
		lines.append("+%d gemas" % int(rewards.get("gems", 0)))
	lines.append("+%d de experiencia" % int(rewards.get("xp", 0)))
	box.add_child(_label("  ·  ".join(lines), 14, GOLD))
	if bool(rewards.get("first_clear", false)):
		box.add_child(_label("¡Primera vez! Bonus incluido.", 12, UiTheme.ACCENT))
	return box

func _ranking(summary: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_child(_section("DAÑO POR HABILIDAD"))
	var damage: Dictionary = summary.get("damage", {})
	var evolved: Array = summary.get("evolved", [])
	var ids: Array = damage.keys()
	ids.sort_custom(func(a, b): return int(damage[a]) > int(damage[b]))
	if ids.is_empty():
		box.add_child(_label("Sin daño registrado.", 13, UiTheme.TEXT_MUTED))
		return box
	var top := maxi(1, int(damage[ids[0]]))
	var total := 0
	for id in ids:
		total += int(damage[id])
	for i in mini(RANKING_ROWS, ids.size()):
		var id := str(ids[i])
		box.add_child(_ranking_row(id, int(damage[id]), top, total, evolved.has(id)))
	return box

func _ranking_row(id: String, amount: int, top: int, total: int, is_evolved: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var extra: Dictionary = EXTRA_SOURCES.get(id, {})
	var color: Color = extra.get("color", AbilityCatalog.color(id))
	var icon_id := str(extra.get("icon_from", id)) if not extra.is_empty() else id
	var icon_tex: Texture2D = AbilityCatalog.icon(icon_id, is_evolved) if icon_id != "" else null
	var icon_holder := Control.new()
	icon_holder.custom_minimum_size = Vector2(28, 28)
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_holder.add_child(icon)
	else:
		var dot := ColorRect.new()
		dot.color = color
		dot.position = Vector2(8, 8)
		dot.size = Vector2(12, 12)
		icon_holder.add_child(dot)
	row.add_child(icon_holder)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 2)
	var name_text := str(extra.get("name", "")) if not extra.is_empty() else AbilityCatalog.display_name(id, is_evolved)
	var top_line := HBoxContainer.new()
	var name_label := _label(name_text, 12, UiTheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.clip_text = true
	top_line.add_child(name_label)
	var percent := int(round(100.0 * amount / maxf(1.0, float(total))))
	top_line.add_child(_label("%s  (%d%%)" % [_compact(amount), percent], 12, UiTheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_RIGHT))
	column.add_child(top_line)
	column.add_child(_bar(float(amount) / float(top), color))
	row.add_child(column)
	return row

func _bar(ratio: float, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 8)
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.step = 0.0
	bar.value = clampf(ratio, 0.0, 1.0)
	bar.add_theme_stylebox_override("background", UiTheme.bar(UiTheme.BG_SLOT))
	bar.add_theme_stylebox_override("fill", UiTheme.bar(color))
	return bar

func _compact(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (value / 1000000.0)
	if value >= 10000:
		return "%.1fk" % (value / 1000.0)
	return str(value)

func _goal_box(goal: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.add_child(_section("PRÓXIMO OBJETIVO"))
	var ability_name := AbilityCatalog.display_name(str(goal["id"]))
	box.add_child(_label("%s → desbloquea %s" % [str(goal["text"]), ability_name], 13, UiTheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT))
	var current := int(goal["current"])
	var target := int(goal["target"])
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	var bar := _bar(float(current) / maxf(1.0, float(target)), UiTheme.ACCENT)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(bar)
	line.add_child(_label("%d / %d" % [mini(current, target), target], 12, UiTheme.TEXT_MUTED))
	box.add_child(line)
	return box

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
	_retry.icon = load("res://assets/ui/pixel_simple_v1/icons/refresh.png") as Texture2D
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
