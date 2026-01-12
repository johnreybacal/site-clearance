extends Node2D
class_name FighterData

@onready var hp: TextureProgressBar = $HP
@onready var heat: TextureProgressBar = $Heat

var is_truck: bool

func _ready() -> void:
    if not is_truck:
        heat.visible = false

func update_hp(amount: float, max_amount: float):
    hp.value = (amount / max_amount) * 100

func update_heat(amount: float, max_amount: float):
    heat.value = (amount / max_amount) * 100
