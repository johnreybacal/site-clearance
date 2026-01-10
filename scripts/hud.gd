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

func add_to_turn_display(fighter: Fighter):
    # for node in turn_display.get_children():
    #     var turn = node as TurnDisplayItem
    #     if turn.move_index < fighter.move_index:
    #         turn.queue_free()
    var turn = TurnDisplayItem.new()
    turn.texture = (fighter.get_node("Sprite2D") as Sprite2D).texture
    turn.move_index = fighter.move_index
    turn_display.add_child(turn)
    # turn_display.add_child(label)

    var sorted_nodes := turn_display.get_children()

    sorted_nodes.sort_custom(
        func(a: TurnDisplayItem, b: TurnDisplayItem): return a.move_index < b.move_index
    )

    for node in turn_display.get_children():
        turn_display.remove_child(node)

    for node in sorted_nodes:
        turn_display.add_child(node)
