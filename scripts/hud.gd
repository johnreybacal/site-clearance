extends Control
class_name HUD

@onready var bottom_panel: PanelContainer = $BottomPanel
@onready var turn_decision: HBoxContainer = $BottomPanel/TurnDecision

@onready var turn_display: HBoxContainer = $TopPanel/TurnDisplay

signal temp_next()

const MOVE_BUTTON_GROUP = "custom_move_button"

func _ready():
    bottom_panel.visible = false

func _on_cooldown_button_pressed() -> void:
    temp_next.emit()

func hide_moves():
    bottom_panel.visible = false

func show_moves(moves: Array[Move]):
    var move_buttons = get_tree().get_nodes_in_group(MOVE_BUTTON_GROUP)
    for move_button in move_buttons:
        move_button.queue_free.call_deferred()

    bottom_panel.visible = true

    for move in moves:
        var move_button = Button.new()
        move_button.text = move.title + "[" + str(move.heat_cost) + "]"
        move_button.tooltip_text = move.description
        move_button.add_to_group(MOVE_BUTTON_GROUP)
        move_button.pressed.connect(_on_cooldown_button_pressed)
        turn_decision.add_child.call_deferred(move_button)

func update_turn_display(queue: Array[GameManager.FighterQueue], current: GameManager.FighterQueue):
    for node in turn_display.get_children():
        node.queue_free()

    for item in queue:
        var turn = TurnDisplayItem.new()
        turn.texture = (item.fighter.get_node("Sprite2D") as Sprite2D).texture
        turn.fighter_id = item.fighter.get_instance_id()
        turn.move_index = item.move_index
        var is_current_fighter = turn.fighter_id == current.fighter.get_instance_id() and turn.move_index == current.move_index
        if not is_current_fighter:
            turn.modulate.a = 0.5
        turn_display.add_child(turn)
