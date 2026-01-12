extends Control
class_name HUD

@onready var bottom_panel: PanelContainer = $BottomPanel
@onready var turn_decision: HFlowContainer = $BottomPanel/TurnDecision

@onready var turn_display: HBoxContainer = $TopPanel/TurnDisplay

signal on_move_selected(move: Move)
signal on_move_cancelled()
signal on_move_hovered(move_id: int)
signal on_target_hovered(target_id: int)
signal on_target_selected(move: Move, targets: Array[Fighter])

const MOVE_BUTTON_GROUP = "move_button"
const TARGET_BUTTON_GROUP = "target_button"
const MOVE_ID_META = "move_id"
const TARGET_ID_META = "target_id"
var fighters: Array[Fighter] = []

func _ready():
    bottom_panel.visible = false

func _process(_delta: float):
    for node in turn_decision.get_children():
        if node is Button:
            var button = node
            if button.is_hovered():
                if button.is_in_group(MOVE_BUTTON_GROUP):
                    var move_id = button.get_meta(MOVE_ID_META)
                    on_move_hovered.emit(move_id)
                if button.is_in_group(TARGET_BUTTON_GROUP):
                    var target_id = button.get_meta(TARGET_ID_META)
                    on_target_hovered.emit(target_id)


func hide_moves():
    bottom_panel.visible = false

func show_moves(truck: Truck):
    for node in turn_decision.get_children():
        node.queue_free.call_deferred()

    bottom_panel.visible = true

    for move in truck.moves:
        var move_button = Button.new()
        move_button.text = move.title + "[" + str(move.heat_cost) + "]"
        if truck.heat_level > truck.max_heat_level and move.heat_cost > 0:
            move_button.disabled = true
        move_button.tooltip_text = move.description
        move_button.set_meta(MOVE_ID_META, move.get_instance_id())
        move_button.add_to_group(MOVE_BUTTON_GROUP)
        move_button.pressed.connect(Callable(on_move_selected.emit).bind(move))
        turn_decision.add_child.call_deferred(move_button)

func show_targets(move: Move, targets: Array[Fighter]):
    for node in turn_decision.get_children():
        node.queue_free.call_deferred()

    bottom_panel.visible = true

    var cancel_button = Button.new()
    cancel_button.text = "Cancel"
    cancel_button.add_to_group(MOVE_BUTTON_GROUP)
    cancel_button.pressed.connect(on_move_cancelled.emit)
    turn_decision.add_child.call_deferred(cancel_button)

    for target in targets:
        var target_button = Button.new()
        target_button.text = target.title
        target_button.add_to_group(TARGET_BUTTON_GROUP)
        var single_target: Array[Fighter] = [target]
        target_button.set_meta(TARGET_ID_META, target.get_instance_id())
        target_button.pressed.connect(Callable(on_target_selected.emit).bind(move, single_target))
        turn_decision.add_child.call_deferred(target_button)


func update_turn_display(queue: Array[GameManager.FighterQueue], current: GameManager.FighterQueue = null):
    for node in turn_display.get_children():
        node.queue_free()

    for item in queue:
        var turn = TurnDisplayItem.new()
        turn.texture = (item.fighter.get_node("Sprite2D") as Sprite2D).texture
        turn.fighter_id = item.fighter.get_instance_id()
        turn.move_index = item.move_index
        turn.modulate.a = 0.5
        if current:
            var is_current_fighter = turn.fighter_id == current.fighter.get_instance_id() and turn.move_index == current.move_index
            if is_current_fighter:
                turn.modulate.a = 1
        turn_display.add_child(turn)
