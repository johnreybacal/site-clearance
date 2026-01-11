extends Node2D
class_name Fighter


const MAX_SPEED = 100

@export var max_hp: int = 10
@export var speed: int = 75
var hp: int

var move_index: int = 0
var upcoming_move_indices: Array[int]

signal died()

func _ready():
    hp = max_hp

func take_damage(damage: int):
    hp -= damage
    if hp <= 0:
        died.emit()

func update_move_index():
    move_index += MAX_SPEED - speed
    var move_index_projection = move_index
    upcoming_move_indices.clear()
    for i in range(1):
        move_index_projection += MAX_SPEED - speed
        upcoming_move_indices.append(move_index_projection)