extends Fighter
class_name Truck

@onready var sprite_2d: Sprite2D = $Sprite2D
@export var moves: Array[Move]

@export var max_heat_level = 10
var heat_level = 0

func perform_move(index: int):
    var move = moves[index]
    heat_level += move.heat_cost
