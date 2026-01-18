extends Fighter
class_name Truck

@onready var sprite_2d: Sprite2D = $TextureContainer/Sprite2D

@export var max_heat_level = 10
var heat_level = 0

var operator: Global.Operator

func _init() -> void:
    fighter_sfx_stream = preload("res://assets/sfx/truck.mp3")

func init_stats():
    var move_cd = preload("res://resources/moves/trucks/cool_down.tres").duplicate()
    var move_ro = preload("res://resources/moves/trucks/run_over.tres").duplicate()
    moves.push_front(move_ro)
    moves.push_front(move_cd)

    max_hp += operator.stats.hp * 1.5
    heal_bonus = operator.stats.hp * .25
    speed += (operator.stats.speed * 2)
    for move in moves:
        if move.damage > 0:
            move.damage += operator.stats.damage * .25 if move.is_area_target else operator.stats.damage
        if move.self_damage > 0:
            move.self_damage += (operator.stats.damage * .25)

func cool_down(amount: float):
    if heat_level > 0:
        fighter_data.queue_text("-" + str(snapped(amount, 0.01)) + " HEAT", Color.SKY_BLUE)
    heat_level -= amount
    if heat_level < 0:
       heat_level = 0
    fighter_data.update_heat(heat_level, max_heat_level)
