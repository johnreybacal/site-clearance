extends Control
class_name HUD

@onready var turn_decision: HBoxContainer = $BottomPanel/TurnDecision

signal temp_next()

const MOVE_BUTTON_GROUP = "custom_move_button"

func _ready():
    turn_decision.visible = false

func _on_cooldown_button_pressed() -> void:
    temp_next.emit()

func hide_moves():
    turn_decision.visible = false

func show_moves(moves: Array[Move]):
    var move_buttons = get_tree().get_nodes_in_group(MOVE_BUTTON_GROUP)
    for move_button in move_buttons:
        move_button.queue_free.call_deferred()

    turn_decision.visible = true

    for move in moves:
        var move_button = Button.new()
        move_button.text = move.title + "[" + str(move.heat_cost) + "]"
        move_button.tooltip_text = move.description
        move_button.add_to_group(MOVE_BUTTON_GROUP)
        move_button.pressed.connect(_on_cooldown_button_pressed)
        turn_decision.add_child.call_deferred(move_button)
