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
    add_child.call_deferred(enemy)
    fighters.append(enemy)

    update_queue()

    hud.temp_next.connect(on_next)

func on_next():
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
        hud.show_moves(current_fighter.moves)
    else:
        await get_tree().create_timer(1.0).timeout
        on_next.call_deferred()
