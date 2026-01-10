extends Control
class_name HUD

@onready var turn_decision: HBoxContainer = $BottomPanel/TurnDecision

signal temp_next()

func _on_cooldown_button_pressed() -> void:
    temp_next.emit()
