extends Fighter
class_name Truck

@onready var sprite_2d: Sprite2D = $TextureContainer/Sprite2D

@export var max_heat_level = 10
var heat_level = 0

func _init() -> void:
    fighter_sfx_stream = preload("res://assets/sfx/truck.mp3")

func _ready():
    super._ready()
    var move_cd = preload("res://resources/moves/trucks/cool_down.tres")
    var move_ro = preload("res://resources/moves/trucks/run_over.tres")
    moves.push_front(move_ro)
    moves.push_front(move_cd)
    fighter_data.update_heat(heat_level, max_heat_level)

func cool_down(amount: float):
    heat_level -= amount
    if heat_level < 0:
       heat_level = 0
    fighter_data.update_heat(heat_level, max_heat_level)
    fighter_data.queue_text("-" + str(amount), Color.SKY_BLUE)
