extends Control
@export var screen_title := "EMBERFALL"
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new(); bg.color = Color("101a2b"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var label := Label.new(); label.text = screen_title; label.set_anchors_and_offsets_preset(Control.PRESET_CENTER); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size", 26); label.add_theme_color_override("font_color", Color("20e6bd")); add_child(label)
