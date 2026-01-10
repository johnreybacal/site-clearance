extends Node2D


@export var hud: HUD

var tick = 0
var is_ticking = true
const TICK_INTERVAL = 1
var tick_interval = TICK_INTERVAL

var move_index: int = 0
const MAX_SPEED = 100

@export var truck_scenes: Array[PackedScene]
@export var enemy_scene: PackedScene

var fighters: Array[Fighter] = []
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

    for fighter in fighters:
        set_next_move_index(fighter)

    hud.temp_next.connect(on_next)

func on_next():
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
        current_fighter = turn_fighters[current_fighter_index]
        if current_fighter_index < len(turn_fighters):
            current_fighter_index += 1
        is_next_turn = false
        on_fighter_turn()

func on_tick():
    var indices = fighters.map(func(f: Fighter): return f.move_index)
    move_index = indices.min()

    turn_fighters = fighters.filter(func(f: Fighter): return f.move_index == move_index)

    for fighter in turn_fighters:
        hud.add_to_turn_display(fighter)
        set_next_move_index(fighter)

    current_fighter_index = 0
    is_next_turn = true
    is_ticking = false

func on_fighter_turn():
    print()
    print(move_index, " >> ", current_fighter.name)
    if current_fighter is Truck:
        hud.show_moves(current_fighter.moves)
    else:
        on_next.call_deferred()


func set_next_move_index(fighter: Fighter):
    fighter.move_index += MAX_SPEED - fighter.speed
