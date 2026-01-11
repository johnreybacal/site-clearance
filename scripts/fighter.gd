extends Node2D
class_name Fighter


const MAX_SPEED = 100

@export var title: String
@export var max_hp: int = 10
@export var speed: int = 75
var hp: int

@export var moves: Array[Move]

var move_index: int = 0
var upcoming_move_indices: Array[int]

@onready var hp_label: Label = $HpLabel

signal died()

func _ready():
    hp = max_hp
    update_hp_label()

    var sprite = get_node("Sprite2D") as Sprite2D
    var shadow = sprite.duplicate()
    shadow.flip_v = true
    shadow.modulate = "#00000044"
    shadow.position = Vector2(5, shadow.texture.get_height() * .66)
    shadow.scale = Vector2(sprite.scale.x, sprite.scale.y / 2)
    shadow.skew = deg_to_rad(-15)
    add_child(shadow)

func take_damage(damage: int):
    hp -= damage
    update_hp_label()
    if hp <= 0:
        died.emit()

func update_hp_label():
    hp_label.text = "HP: " + str(hp) + " / " + str(max_hp)

func update_move_index():
    move_index += MAX_SPEED - speed
    var move_index_projection = move_index
    upcoming_move_indices.clear()
    for i in range(1):
        move_index_projection += MAX_SPEED - speed
        upcoming_move_indices.append(move_index_projection)


func perform_move(move: Move, targets: Array[Fighter]):
    print(title + " used " + move.title)
    if len(targets) > 0:
        print("  on ", ", ".join(targets.map(func(t: Fighter): return t.title)))
    if self is Truck:
        var truck = self
        truck.heat_level += move.heat_cost
        truck.heat_level -= move.heat_reduction
        if truck.heat_level < 0:
            truck.heat_level = 0
        truck.update_heat_label()

    if move.target_type == Move.TargetType.Self:
        pass
    elif move.move_type == Move.MoveType.Attack:
        for target in targets:
            target.take_damage(move.damage)
