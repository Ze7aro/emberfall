extends Node
## Autoload "Localization": idioma del juego.
##
## El juego está escrito en español: los textos del código son la fuente.
## Para inglés se registra una traducción dinámica (DynamicTranslation) que
## Godot consulta sola cada vez que un Label/Button muestra un texto, así que
## las pantallas no necesitan llamar a tr().
##
##   Localization.set_language("auto" | "es" | "en")
##   Localization.language            -> la preferencia guardada
##   Localization.t("texto")          -> traducción manual (texto dibujado a mano)
##
## Solo el texto dibujado con draw_string() tiene que pasar por t().

signal language_changed

const DynamicTranslation := preload("res://scripts/systems/dynamic_translation.gd")
const LANGUAGES := ["auto", "es", "en"]

var language := "auto"
var _english: Translation

func _ready() -> void:
	_english = DynamicTranslation.new()
	_english.locale = "en"
	TranslationServer.add_translation(_english)
	language = GameState.language if LANGUAGES.has(GameState.language) else "auto"
	_apply()

## La traducción es un objeto de GDScript: se quita antes de que el motor
## descargue los scripts al cerrar.
func _exit_tree() -> void:
	TranslationServer.remove_translation(_english)

## Locale en uso: "es" o "en".
func locale() -> String:
	return "es" if TranslationServer.get_locale().begins_with("es") else "en"

func set_language(value: String) -> void:
	if not LANGUAGES.has(value) or value == language:
		return
	language = value
	GameState.set_language(value)
	_apply()
	language_changed.emit()

## Traducción explícita, para texto que no pasa por un Control.
func t(text: String) -> String:
	return str(TranslationServer.translate(text))

func _apply() -> void:
	var target := language
	if target == "auto":
		# Dispositivos en español ven el original; el resto, inglés.
		target = "es" if OS.get_locale_language() == "es" else "en"
	TranslationServer.set_locale(target)
