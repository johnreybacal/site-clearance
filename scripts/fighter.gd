extends Node2D
class_name Fighter

@export var max_hp: float = 10
@export var speed: int = 75
var hp: float

var move_index: int = 0

signal died()

func _ready():
    hp = max_hp

func take_damage(damage: float):
    hp -= damage
    if hp <= 0:
        died.emit()
