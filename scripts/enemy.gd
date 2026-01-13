extends Fighter
class_name Enemy

const REST_INDEX = 0

signal on_move_selected(move: Move)
signal on_move_confirmed(move: Move, targets: Array[Fighter])

func _init() -> void:
    fighter_sfx_stream = preload("res://assets/sfx/enemy.mp3")

func _ready():
    super._ready()
    var move_at = preload("res://resources/moves/enemies/attack.tres")
    var move_re = preload("res://resources/moves/enemies/rest.tres")
    moves.push_front(move_at) # 1
    moves.push_front(move_re) # 0

func decide():
    var choice = randi_range(1 if hp >= max_hp - 3 else 0, len(moves) - 1)
    on_move_selected.emit(moves[choice])

func select_target(move: Move, targets: Array[Fighter]):
    var selected_targets: Array[Fighter] = []
    if move.target_type == Move.TargetType.Self:
        selected_targets.append(self)
    elif move.is_area_target:
        selected_targets = targets
    else:
        selected_targets.append(targets.pick_random())
    on_move_confirmed.emit(move, selected_targets)
