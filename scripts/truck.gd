extends Fighter
class_name Truck

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var heal_label: Label = $HeatLabel

@export var max_heat_level = 10
var heat_level = 0

func _ready():
    super._ready()
    update_heat_label()

func update_heat_label():
    heal_label.text = "HEAT: " + str(heat_level) + " / " + str(max_heat_level)
