extends Node2D
class_name FloatingText

var color: Color = Color.WHITE
var font_size: int
var text: String

@onready var label: Label = $LabelContainer/Label

func _ready():
    label.modulate = color
    label.text = text
    if font_size:
        label.add_theme_font_size_override("font_size", font_size)

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
    queue_free()
