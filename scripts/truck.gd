extends Fighter
class_name Truck

@onready var sprite_2d: Sprite2D = $Sprite2D

@export var max_heat_level = 10
var heat_level = 0


func _ready():
    super._ready()
    on_heat_updated()
    var move_cd = preload("res://resources/moves/trucks/cool_down.tres")
    var move_ro = preload("res://resources/moves/trucks/run_over.tres")
    moves.push_front(move_ro)
    moves.push_front(move_cd)

func on_heat_updated():
    update_effect_label()
    var color: float = 1 - (heat_level as float / 25)
    sprite_2d.modulate.b = color
    sprite_2d.modulate.g = color

func cool_down(amount: int):
    heat_level -= amount
    if heat_level < 0:
       heat_level = 0

    on_heat_updated()

func update_effect_label():
    super.update_effect_label()
    effect_label.text = "HEAT: " + str(heat_level) + " / " + str(max_heat_level) + "\n" + effect_label.text
