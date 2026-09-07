extends Control

signal route_changed(route_id: StringName)
signal modal_opened(modal_id: StringName)
signal modal_closed(modal_id: StringName)

var current_route: StringName = &"home"
var current_screen: Node
var modal_host: Control
var content_host: Control
var active_modal: Control
var navigation_footer: Node

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_host = Control.new(); content_host.name = "ContentHost"; content_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(content_host)
	var hud := CanvasLayer.new(); hud.name = "HudLayer"; hud.layer = 10; add_child(hud)
	var top = preload("res://scenes/ui/TopHud.tscn").instantiate(); top.name = "TopHud"; top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE); top.offset_bottom = 98; hud.add_child(top)
	navigation_footer = preload("res://scenes/ui/NavigationFooter.tscn").instantiate(); navigation_footer.name = "NavigationFooter"; navigation_footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); navigation_footer.offset_top = -112
	navigation_footer.icons = [load("res://assets/iconos main/09_tienda.png"), load("res://assets/iconos main/04_pergamino.png"), load("res://assets/iconos main/05_mapa.png"), load("res://assets/iconos main/03_espada.png"), load("res://assets/iconos main/08_brujula.png")]
	hud.add_child(navigation_footer)
	navigation_footer.navigation_requested.connect(func(_index: int, route_id: StringName): navigate_to(route_id))
	var modal_layer := CanvasLayer.new(); modal_layer.name = "ModalLayer"; modal_layer.layer = 20; add_child(modal_layer)
	modal_host = Control.new(); modal_host.name = "ModalHost"; modal_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); modal_layer.add_child(modal_host)
	navigate_to(&"home")

func navigate_to(route_id: StringName) -> void:
	if route_id == current_route and is_instance_valid(current_screen): return
	close_active_modal()
	if is_instance_valid(current_screen): current_screen.queue_free()
	current_screen = _screen_for(route_id)
	if current_screen == null: return
	content_host.add_child(current_screen); current_route = route_id
	if navigation_footer.has_method("select_by_id"): navigation_footer.select_by_id(route_id)
	route_changed.emit(route_id)

func get_current_route() -> StringName: return current_route
func _screen_for(route_id: StringName) -> Node:
	match route_id:
		&"home": return preload("res://scenes/screens/HomeScreen.tscn").instantiate()
		&"characters": return preload("res://scenes/screens/CharacterSelectionScreen.tscn").instantiate()
		&"dungeons": return preload("res://scenes/screens/DungeonSelectionScreen.tscn").instantiate()
		&"upgrades": return preload("res://scenes/screens/PermanentUpgradesScreen.tscn").instantiate()
		&"shop": return preload("res://scenes/screens/ShopScreen.tscn").instantiate()
		_: return null

func _placeholder_screen(route_id: StringName) -> Control:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new(); bg.color = Color("101a2b"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); screen.add_child(bg)
	var label := Label.new(); label.text = str(route_id).to_upper(); label.set_anchors_and_offsets_preset(Control.PRESET_CENTER); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size", 28); label.add_theme_color_override("font_color", Color("20e6bd")); screen.add_child(label)
	return screen

func open_modal(modal_id: StringName, payload: Variant = null) -> void:
	if is_instance_valid(active_modal): return
	var blocker := ColorRect.new(); blocker.color = Color(0, 0, 0, 0.72); blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); blocker.mouse_filter = Control.MOUSE_FILTER_STOP; modal_host.add_child(blocker); active_modal = blocker; modal_opened.emit(modal_id)
func close_active_modal() -> void:
	if not is_instance_valid(active_modal): return
	active_modal.queue_free(); active_modal = null; modal_closed.emit(&"active")
func has_open_modal() -> bool: return is_instance_valid(active_modal)
