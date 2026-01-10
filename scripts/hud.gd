extends Control

@onready var turn_decision: HBoxContainer = $BottomPanel/TurnDecision
@onready var fight_decision: HBoxContainer = $BottomPanel/FightDecision

func _ready() -> void:
    show_turn_decision(true)
    show_fight_decision(false)

func show_turn_decision(v: bool):
    turn_decision.visible = v

func show_fight_decision(v: bool):
    fight_decision.visible = v

func _on_skip_button_pressed() -> void:
    show_turn_decision(false)

func _on_fight_button_pressed() -> void:
    show_turn_decision(false)
    show_fight_decision(true)

func _on_back_button_pressed() -> void:
    show_turn_decision(true)
    show_fight_decision(false)
