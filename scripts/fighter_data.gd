extends Node2D
class_name FighterData

@onready var hp: TextureProgressBar = $HP
@onready var heat: TextureProgressBar = $Heat

var is_truck: bool

var target_hp: float = 100
var target_heat: float = 0

func _ready() -> void:
    hp.value = 0
    heat.value = 100
    if not is_truck:
        heat.visible = false

func _process(delta: float) -> void:
    if hp.value != target_hp:
        hp.value = move_toward(hp.value, target_hp, delta * 250)
    if heat.value != target_heat:
        heat.value = move_toward(heat.value, target_heat, delta * 250)

func update_hp(amount: float, max_amount: float):
    target_hp = (amount / max_amount) * 100

func update_heat(amount: float, max_amount: float):
    target_heat = (amount / max_amount) * 100
