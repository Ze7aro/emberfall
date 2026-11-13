extends Control
## Vista de una etapa sin marco: un trozo de suelo del capítulo que se funde
## con el fondo, sus decorados alrededor y el jefe que espera al final,
## asomando detrás como una sombra. El héroe lo coloca MapSelection encima.

const FLOORS := {
	1: "res://assets/mundo/suelos/cap1_criptas.png",
	2: "res://assets/mundo/suelos/cap2_cavernas.png",
	3: "res://assets/mundo/suelos/cap3_forja.png",
}
const DECOR_DIR := "res://assets/mundo/decorados/cap%d/"
const BOSSES := {
	1: "res://assets/personajes/jefes/01_coloso_runico/idle.png",
	2: "res://assets/personajes/jefes/02_guardian_hueco/idle.png",
	3: "res://assets/personajes/jefes/03_matriarca_ceniza/idle.png",
}
## Color de la luz del capítulo: resplandor del suelo y tinte del jefe.
const GLOWS := {1: Color("8a5cf0"), 2: Color("3fd6a8"), 3: Color("ff8a3c")}
## [archivo, centro x (0-1), base y (0-1), alto en px, delante del héroe]
const LAYOUT := [
	["pilar.png", 0.13, 0.70, 112.0, false],
	["lapida.png", 0.30, 0.58, 52.0, false],
	["brasero.png", 0.88, 0.72, 78.0, false],
	["cristal.png", 0.80, 0.97, 62.0, true],
	["calaveras.png", 0.17, 0.98, 40.0, true],
]
const FLOOR_SHADER := "shader_type canvas_item;
void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float fade = 1.0 - smoothstep(0.55, 1.0, length(p));
	COLOR = texture(TEXTURE, UV * vec2(1.0, 0.5) + vec2(0.0, 0.25));
	COLOR.a *= fade;
}"

var _chapter := 0
var _back: Control
var _front: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

## Capa para lo que va delante del héroe (MapSelection la pone encima de él).
func front_layer() -> Control:
	if _front == null:
		_front = _layer()
	return _front

func set_chapter(chapter: int) -> void:
	chapter = clampi(chapter, 1, 3)
	if chapter == _chapter:
		return
	_chapter = chapter
	if _back == null:
		_back = _layer()
		add_child(_back)
	for layer in [_back, front_layer()]:
		for child in layer.get_children():
			child.queue_free()
	var glow_color: Color = GLOWS[chapter]

	# Jefe: grande, oscuro y teñido con la luz del capítulo.
	var boss := _picture(BOSSES[chapter], 0.5, 0.58, 200.0)
	boss.modulate = Color(0.46, 0.42, 0.6, 0.92).lerp(Color(glow_color, 0.92), 0.2)
	_back.add_child(boss)

	var floor_rect := TextureRect.new()
	floor_rect.texture = load(FLOORS[chapter])
	floor_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	floor_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	floor_rect.stretch_mode = TextureRect.STRETCH_SCALE
	floor_rect.anchor_left = -0.04; floor_rect.anchor_right = 1.04
	floor_rect.anchor_top = 0.42; floor_rect.anchor_bottom = 1.06
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = FLOOR_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	floor_rect.material = material
	_back.add_child(floor_rect)

	var glow := TextureRect.new()
	glow.texture = _glow_texture()
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.anchor_left = 0.12; glow.anchor_right = 0.88
	glow.anchor_top = 0.5; glow.anchor_bottom = 1.0
	glow.modulate = Color(glow_color, 0.32)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back.add_child(glow)

	for entry in LAYOUT:
		var path := _decor_path(chapter, str(entry[0]))
		if path == "":
			continue
		var picture := _picture(path, float(entry[1]), float(entry[2]), float(entry[3]))
		(_front if bool(entry[4]) else _back).add_child(picture)

func _layer() -> Control:
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return layer

## Los nombres cambian un poco entre capítulos ("roca_1", "circulo_runico_2").
func _decor_path(chapter: int, file: String) -> String:
	var folder := DECOR_DIR % chapter
	if ResourceLoader.exists(folder + file):
		return folder + file
	var numbered := folder + file.get_basename() + "_1.png"
	return numbered if ResourceLoader.exists(numbered) else ""

## Imagen de `height` px de alto, centrada en x y apoyada en y (fracciones).
func _picture(path: String, center_x: float, base_y: float, height: float) -> TextureRect:
	var texture := load(path) as Texture2D
	var rect := TextureRect.new()
	rect.texture = texture
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var width := height * float(texture.get_width()) / float(maxi(texture.get_height(), 1))
	rect.anchor_left = center_x; rect.anchor_right = center_x
	rect.anchor_top = base_y; rect.anchor_bottom = base_y
	rect.offset_left = -width / 2.0; rect.offset_right = width / 2.0
	rect.offset_top = -height; rect.offset_bottom = 0.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

static var _glow: GradientTexture2D

static func _glow_texture() -> GradientTexture2D:
	if _glow != null:
		return _glow
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	_glow = GradientTexture2D.new()
	_glow.gradient = gradient
	_glow.fill = GradientTexture2D.FILL_RADIAL
	_glow.fill_from = Vector2(0.5, 0.5)
	_glow.fill_to = Vector2(1.0, 0.5)
	_glow.width = 128
	_glow.height = 64
	return _glow
