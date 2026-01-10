extends Node2D


@export var hud: HUD

var tick = 0
var is_ticking = true
const TICK_INTERVAL = 1
var tick_interval = TICK_INTERVAL

var move_index: int = 0
const MAX_SPEED = 100

@export var trucks: Array[PackedScene]
var fighters: Array[Fighter] = []
var turn_fighters: Array[Fighter] = []
var is_player_turn: bool = false

func _ready() -> void:
    for truck in trucks:
        var new_truck: Truck = truck.instantiate()
        new_truck.position = Vector2(-300, 0)
        add_child.call_deferred(new_truck)
        fighters.append(new_truck)
        new_truck = truck.instantiate()
        new_truck.position = Vector2(-350, 100)
        new_truck.speed = 66
        add_child.call_deferred(new_truck)
        fighters.append(new_truck)

    for fighter in fighters:
        set_next_move_index(fighter)

    hud.temp_next.connect(on_next)

func on_next():
    is_ticking = true
    

func _process(delta: float) -> void:
    if is_ticking:
        tick_interval -= delta
        if tick_interval <= 0:
            tick_interval = TICK_INTERVAL
            tick += 1
            on_tick()
            
            
func on_tick():
    print("tick: ", tick)
            
    var indices = fighters.map(func(f: Fighter): return f.move_index)
    move_index = indices.min()
    print("move_index: ", move_index)

    turn_fighters = fighters.filter(func(f: Fighter): return f.move_index == move_index)

    for fighter in turn_fighters:
        set_next_move_index(fighter)

    is_ticking = false


func set_next_move_index(fighter: Fighter):
    fighter.move_index += MAX_SPEED - fighter.speed
