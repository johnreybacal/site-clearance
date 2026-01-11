extends Node2D
class_name GameManager


@export var hud: HUD

var tick = 0
var is_ticking = true
const TICK_INTERVAL = 1
var tick_interval = TICK_INTERVAL

var prev_move_index: int = -1
var move_index: int = 0
const MAX_SPEED = 100

@export var truck_scenes: Array[PackedScene]
@export var enemy_scene: PackedScene

class FighterQueue:
    var fighter: Fighter
    var move_index: int

var fighters: Array[Fighter] = []
var turn_queue: Array[FighterQueue] = []
var turn_fighters: Array[Fighter] = []
var current_fighter_index: int
var current_fighter: Fighter
var is_next_turn: bool = false

var is_player_turn: bool = false


func _ready() -> void:
    for truck_scene in truck_scenes:
        var truck: Truck = truck_scene.instantiate()
        truck.position = Vector2(-300, 0)
        add_child.call_deferred(truck)
        fighters.append(truck)

    var enemy: Enemy = enemy_scene.instantiate()
    enemy.position = Vector2(300, 0)
    enemy.title = "Ankylosaur"
    add_child.call_deferred(enemy)
    fighters.append(enemy)

    update_queue()

    hud.on_move_selected.connect(on_move_selected)
    hud.on_move_cancelled.connect(on_fighter_turn)
    hud.on_target_selected.connect(on_move_confirmed)

func on_move_selected(move: Move):
    if move.target_type == Move.TargetType.Enemy:
        var enemies = fighters.filter(func(f: Fighter): return f is Enemy)
        if move.is_area_target:
            on_move_confirmed(move, enemies)
        else:
            hud.show_targets(move, enemies)
    elif move.target_type == Move.TargetType.Ally:
        var allies = fighters.filter(func(f: Fighter): return f is Truck and f != current_fighter)
        if move.is_area_target:
            on_move_confirmed(move, allies)
        else:
            hud.show_targets(move, allies)
    else:
        on_move_confirmed(move, [])

func on_move_confirmed(move: Move, targets: Array[Fighter]):
    current_fighter.perform_move(move, targets)
    if current_fighter_index < len(turn_fighters):
        is_next_turn = true
    else:
        is_ticking = true
    hud.hide_moves()

    
func _process(delta: float) -> void:
    if is_ticking:
        tick_interval -= delta
        if tick_interval <= 0:
            tick_interval = TICK_INTERVAL
            tick += 1
            on_tick()
    if is_next_turn:
        if len(turn_fighters) == 0:
            return
        current_fighter = turn_fighters[current_fighter_index]
        current_fighter_index += 1
        
        hud.update_turn_display(turn_queue, new_queue_item(current_fighter, move_index))
        is_next_turn = false
        on_fighter_turn()

func new_queue_item(f: Fighter, i: int):
    var queue_item = FighterQueue.new()
    queue_item.fighter = f
    queue_item.move_index = i
    return queue_item

func update_queue():
    for fighter in fighters:
        if fighter.move_index == move_index:
            fighter.update_move_index()
            turn_queue.append(new_queue_item(fighter, fighter.move_index))
            turn_queue.append_array(fighter.upcoming_move_indices.map(func(i: int): return new_queue_item(fighter, i)))

    var unique_queue: Array[FighterQueue] = []
    for item in turn_queue:
        var any = unique_queue.any(func(i: FighterQueue): return i.fighter.get_instance_id() == item.fighter.get_instance_id() and i.move_index == item.move_index)
        if not any:
            unique_queue.append(item)
    
    turn_queue = unique_queue.filter(func(i: FighterQueue): return i.move_index >= prev_move_index)
    turn_queue.sort_custom(func(a: FighterQueue, b: FighterQueue): return a.move_index < b.move_index)


func on_tick():
    var indices = fighters.map(func(f: Fighter): return f.move_index)
    prev_move_index = move_index
    move_index = indices.min()

    turn_fighters.assign(turn_queue.filter(
        func(f: FighterQueue): return f.move_index == move_index
        ).map(func(f: FighterQueue): return f.fighter))
    update_queue()

    current_fighter_index = 0
    is_next_turn = true
    is_ticking = false

func on_fighter_turn():
    if current_fighter is Truck:
        hud.fighters = fighters
        hud.show_moves(current_fighter)
    else:
        await get_tree().create_timer(1.0).timeout
        enemy_decide()
        

func enemy_decide():
    var move = current_fighter.moves.pick_random()
    var targets: Array[Fighter] = []
    if move.move_type == Move.MoveType.Attack:
        var trucks = fighters.filter(func(f: Fighter): return f is Truck)
        if move.is_area_target:
            targets = trucks
        else:
            targets = [trucks.pick_random()]
    on_move_confirmed.call_deferred(move, targets)
