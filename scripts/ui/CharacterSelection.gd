extends MarginContainer
signal character_preview_changed(character_id: StringName, index: int)
signal character_selected(character_id: StringName)
signal back_requested
var characters: Array = []
var index := 0
var selected_id: StringName = &""
var title_label: Label
var info_label: Label
var preview: TextureRect
var position_label: Label
var select_button: Button

func _ready() -> void:
	var files := ["baculo","baculo","baculo","baculo","arco","baculo","hacha_dos_manos","espadon_dos_manos","dos_hachas","escudo_y_espada","dos_pistolas","baculo","puños","dos_espadas"]
	for i in range(14):
		var unlock := _unlock_rule_for(i + 1)
		characters.append({
			"id": StringName("variante_%02d" % (i + 1)),
			"name": "PERSONAJE %02d" % (i + 1),
			"weapon": files[i],
			"texture": "res://assets/variantes_con_armas/variante_%02d_%s.png" % [i + 1, files[i]],
			"cost": unlock.cost, "currency": unlock.currency, "requirement": unlock.requirement,
		})
	_build(); show_character_at(0)
	GameState.gold_changed.connect(func(_v): refresh_character_details())
	GameState.gems_changed.connect(func(_v): refresh_character_details())
	GameState.progress_changed.connect(refresh_character_details)

## First character is free; the rest cost gold, gems, or require clearing
## specific stages/dungeons first (then a gold price on top).
func _unlock_rule_for(slot: int) -> Dictionary:
	if slot == 1:
		return {"cost": 0, "currency": "gold", "requirement": ""}
	if slot <= 5:
		return {"cost": 50 + (slot - 2) * 150, "currency": "gold", "requirement": ""}
	if slot <= 9:
		return {"cost": 8 + (slot - 6) * 4, "currency": "gems", "requirement": ""}
	if slot <= 13:
		var stage_index := 6 + (slot - 9)
		return {"cost": 900 + (slot - 10) * 100, "currency": "gold", "requirement": "stage_%02d" % stage_index}
	return {"cost": 30, "currency": "gems", "requirement": "dungeon_01"}

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_theme_constant_override("margin_left", 18); add_theme_constant_override("margin_right", 18); add_theme_constant_override("margin_top", 160); add_theme_constant_override("margin_bottom", 140)
	var col := VBoxContainer.new(); col.alignment = BoxContainer.ALIGNMENT_CENTER; col.add_theme_constant_override("separation", 8); add_child(col)
	title_label = Label.new(); title_label.text = "SELECCIÓN DE PERSONAJE"; title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title_label.add_theme_font_size_override("font_size", 22); col.add_child(title_label)
	var row := HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.custom_minimum_size.y = 300; col.add_child(row)
	var prev := Button.new(); prev.text = "‹"; prev.custom_minimum_size = Vector2(52, 100); prev.add_theme_font_size_override("font_size", 44); prev.pressed.connect(show_previous_character); row.add_child(prev)
	var panel := PanelContainer.new(); panel.custom_minimum_size = Vector2(250, 290); panel.add_theme_stylebox_override("panel", _style()); row.add_child(panel)
	preview = TextureRect.new(); preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; preview.custom_minimum_size = Vector2(0, 250); panel.add_child(preview)
	var next := Button.new(); next.text = "›"; next.custom_minimum_size = Vector2(52, 100); next.add_theme_font_size_override("font_size", 44); next.pressed.connect(show_next_character); row.add_child(next)
	position_label = Label.new(); position_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; col.add_child(position_label)
	info_label = Label.new(); info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; col.add_child(info_label)
	select_button = Button.new(); select_button.text = "SELECCIONAR"; select_button.custom_minimum_size = Vector2(0, 58); select_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; select_button.add_theme_font_size_override("font_size", 21); select_button.pressed.connect(_on_select_pressed); col.add_child(select_button)
func set_characters(value: Array) -> void: characters = value; show_character_at(index)
func show_character_at(value: int) -> void:
	if characters.is_empty(): return
	index = posmod(value, characters.size()); refresh_character_details(); character_preview_changed.emit(StringName(characters[index].get("id", "")), index)
func show_previous_character() -> void: show_character_at(index - 1)
func show_next_character() -> void: show_character_at(index + 1)

func _on_select_pressed() -> void:
	var c: Dictionary = characters[index]
	var id := StringName(c.get("id", ""))
	if GameState.owns_character(id):
		selected_id = id
		refresh_character_details()
		character_selected.emit(selected_id)
		return
	if not _is_requirement_met(c):
		return
	if GameState.buy_character(id, int(c.get("cost", 0)), str(c.get("currency", "gold"))):
		refresh_character_details()

func _is_requirement_met(c: Dictionary) -> bool:
	var requirement := str(c.get("requirement", ""))
	if requirement == "":
		return true
	if requirement.begins_with("stage_"):
		return GameState.highest_stage_cleared >= int(requirement.trim_prefix("stage_"))
	if requirement.begins_with("dungeon_"):
		return GameState.dungeons_cleared >= int(requirement.trim_prefix("dungeon_"))
	return true

func set_selected_character(value: StringName) -> void: selected_id = value; refresh_character_details()
func focus_character(id: StringName) -> void:
	for i in characters.size():
		if StringName(characters[i].get("id", "")) == id:
			selected_id = id
			show_character_at(i)
			return
func refresh_character_details() -> void:
	if characters.is_empty() or not is_instance_valid(info_label): return
	var c: Dictionary = characters[index]; var tex = load(str(c.get("texture", ""))); if tex is Texture2D: preview.texture = tex
	position_label.text = "%d / %d" % [index + 1, characters.size()]
	var id := StringName(c.get("id", ""))
	var owned := GameState.owns_character(id)
	var requirement := str(c.get("requirement", ""))
	var requirement_met := _is_requirement_met(c)
	var cost := int(c.get("cost", 0))
	var currency := str(c.get("currency", "gold"))
	var currency_label := "ORO" if currency == "gold" else "ESMERALDAS"
	if owned:
		info_label.text = "%s\nArma: %s\nPersonaje disponible" % [c.get("name", "PERSONAJE"), c.get("weapon", "")]
		select_button.text = "SELECCIONADO" if selected_id == id else "SELECCIONAR"
		select_button.disabled = false
	elif not requirement_met:
		info_label.text = "%s\nArma: %s\nRequiere superar: %s" % [c.get("name", "PERSONAJE"), c.get("weapon", ""), requirement]
		select_button.text = "BLOQUEADO"
		select_button.disabled = true
	else:
		var have := GameState.gold if currency == "gold" else GameState.gems
		info_label.text = "%s\nArma: %s\nCoste: %d %s" % [c.get("name", "PERSONAJE"), c.get("weapon", ""), cost, currency_label]
		select_button.text = "COMPRAR · %d %s" % [cost, currency_label]
		select_button.disabled = have < cost
func _style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = Color("171027"); s.border_color = Color("20e6bd"); s.set_border_width_all(3); s.set_corner_radius_all(10); return s
