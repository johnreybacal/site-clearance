extends Node2D

var tick = 0
var is_ticking = false
const TICK_INTERVAL = 0.25
var tick_interval = TICK_INTERVAL

@export var trucks: Array[PackedScene]

func _ready() -> void:
    for truck in trucks:
        var new_truck = truck.instantiate()
        new_truck.position = Vector2(-300, 0)
        add_child.call_deferred(new_truck)

func _process(delta: float) -> void:
    if is_ticking:
        tick_interval -= delta
        if tick_interval <= 0:
            tick_interval = TICK_INTERVAL
            tick += 1
            print(tick)
