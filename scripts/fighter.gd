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

var current_shake = 0
@export var shake_amount := 5.0
@export var shake_duration := 1

var sprite: Sprite2D
var shadow: Sprite2D
var shadow_position: Vector2

func _ready():
    hp = max_hp
    update_hp_label()

    sprite = get_node("Sprite2D") as Sprite2D
    shadow = sprite.duplicate()
    shadow.name = "ShadowSprite"
    shadow.flip_v = true
    shadow.modulate = "#00000044"
    shadow_position = Vector2(5, shadow.texture.get_height() * .66)
    shadow.position = shadow_position
    shadow.scale = Vector2(sprite.scale.x, sprite.scale.y / 2)
    shadow.skew = deg_to_rad(-15)
    add_child(shadow)

func _process(delta: float) -> void:
    current_shake -= shake_amount * delta / shake_duration
    if current_shake < 0:
        current_shake = 0
    
    var shake_position = Vector2(randf_range(-current_shake, current_shake), randf_range(-current_shake, current_shake))
    sprite.position = shake_position
    shadow.position = shadow_position + shake_position


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
    current_shake = 5
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
            target.current_shake = 10
