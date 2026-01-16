extends Control
class_name HUD

@onready var bottom_panel: PanelContainer = $BottomPanel
@onready var turn_decision: HFlowContainer = $BottomPanel/VBoxContainer/TurnDecision
@onready var description: Label = $BottomPanel/VBoxContainer/Label
@onready var queue_marker: Marker2D = $QueueMarker

@onready var ui_feedback: AudioStreamPlayer = $UIFeedback

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
            if button.is_hovered() or button.has_focus():
                button.grab_focus()
                if button.is_in_group(MOVE_BUTTON_GROUP):
                    var move_id = button.get_meta(MOVE_ID_META)
                    on_move_hovered.emit(move_id)
                    var move = instance_from_id(move_id) as Move
                    description.text = move.description

                if button.is_in_group(TARGET_BUTTON_GROUP):
                    var target_id = button.get_meta(TARGET_ID_META, -1)
                    if target_id != -1:
                        on_target_hovered.emit(target_id)

func set_description_text(value: String):
    description.text = value

func hide_moves():
    bottom_panel.visible = false

func show_moves(truck: Truck):
    for node in turn_decision.get_children():
        node.queue_free.call_deferred()

    bottom_panel.visible = true
    var is_first_button = true
    for move in truck.moves:
        var button = Button.new()
        button.text = move.title
        if truck.heat_level >= truck.max_heat_level and move.heat_cost > 0:
            button.disabled = true
        button.set_meta(MOVE_ID_META, move.get_instance_id())
        button.add_to_group(MOVE_BUTTON_GROUP)
        
        button.pressed.connect(Callable(on_move_selected.emit).bind(move))
        button.pressed.connect(play_ui_feedback)
        button.focus_entered.connect(play_ui_feedback)
        turn_decision.add_child.call_deferred(button)
        if is_first_button:
            button.grab_focus.call_deferred()
            is_first_button = false


func show_targets(move: Move, targets: Array[Fighter]):
    for node in turn_decision.get_children():
        node.queue_free.call_deferred()

    bottom_panel.visible = true

    var cancel_button = Button.new()
    cancel_button.text = "Cancel"
    cancel_button.add_to_group(TARGET_BUTTON_GROUP)
    cancel_button.pressed.connect(on_move_cancelled.emit)
    turn_decision.add_child.call_deferred(cancel_button)
    cancel_button.grab_focus.call_deferred()
    cancel_button.focus_entered.connect(play_ui_feedback)
    cancel_button.pressed.connect(play_ui_feedback)

    for target in targets:
        var button = Button.new()
        button.text = target.title
        button.add_to_group(TARGET_BUTTON_GROUP)
        var single_target: Array[Fighter] = [target]
        button.set_meta(TARGET_ID_META, target.get_instance_id())
        button.pressed.connect(Callable(on_target_selected.emit).bind(move, single_target))
        button.pressed.connect(play_ui_feedback)
        button.focus_entered.connect(play_ui_feedback)
        turn_decision.add_child.call_deferred(button)


func update_turn_display(queue: Array[GameManager.FighterQueue], current: GameManager.FighterQueue = null):
    print(len(queue))
    if current:
        print(current.fighter.title, " :: ", current.move_index)
    for node in queue_marker.get_children():
        node.queue_free()

    var counter = 0
    var max_display = 6
    var is_before_current = true
    for item in queue:
        var is_current_fighter = false
        if current:
            is_current_fighter = item.fighter.get_instance_id() == current.fighter.get_instance_id() and item.move_index == current.move_index
            if is_current_fighter:
                is_before_current = false
            elif is_before_current:
                continue
        var turn = TurnDisplayItem.new()
        turn.texture = (item.fighter.get_node("TextureContainer/Sprite2D") as Sprite2D).texture
        turn.fighter_id = item.fighter.get_instance_id()
        turn.move_index = item.move_index
        if not is_current_fighter:
            turn.self_modulate = "#808080a8"

        turn.position = Vector2(counter * 40, 0)
        turn.transition_speed = (len(queue) - counter) * 15
        if item.fighter is Truck:
            turn.scale = Vector2(.5, .5)
            # turn.target_scale_x = .5
            # turn.transition_speed /= 2
        # var label = Label.new()
        # label.modulate = Color.WHITE
        # label.text = str(item.move_index)
        # turn.add_child(label)
        # if is_current_fighter:
        queue_marker.add_child(turn)
        # else:
        # turn_display.add_child(turn)
        counter += 1
        if counter > max_display:
            break

func play_ui_feedback():
    ui_feedback.pitch_scale = randf_range(0.8, 1.2)
    ui_feedback.play()
