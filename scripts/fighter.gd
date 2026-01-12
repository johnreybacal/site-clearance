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

signal on_ready()
signal on_died(fighter: Fighter)

var current_shake: float = 0
@export var shake_amount := 5.0
@export var shake_duration := 1

var texture_container: Node2D
var sprite: Sprite2D
var shadow: Sprite2D
var shadow_position: Vector2
var fighter_data: FighterData

var initial_position: Vector2
var is_going_to_center: bool = false
var is_ready: bool = false

var is_attacked = false
const ATTACKED_INTEVAL = 1
var attacked_interval = ATTACKED_INTEVAL

var is_dying = false

var highlight_duration = 0

# Debuff
var slowed: int
var stunned: int
var weakened: int
# Buff
var strengthened: int
var toughened: int


var FighterDataScene = preload("res://scenes/fighter_data.tscn")

func _ready():
    hp = max_hp

    texture_container = get_node("TextureContainer")
    sprite = get_node("TextureContainer/Sprite2D") as Sprite2D
    shadow = sprite.duplicate()
    shadow.name = "ShadowSprite"
    shadow.flip_v = true
    shadow.modulate = "#00000044"
    shadow_position = Vector2(5, shadow.texture.get_height() * .66)
    shadow.position = shadow_position
    shadow.scale = Vector2(sprite.scale.x, sprite.scale.y / 2)
    shadow.skew = deg_to_rad(-15)
    texture_container.add_child(shadow)

    fighter_data = FighterDataScene.instantiate()
    fighter_data.is_truck = self is Truck
    fighter_data.position = Vector2(-60 if self is Truck else 50, 0)
    
    fighter_data.skew = deg_to_rad(-25 if self is Truck else 25)
    # fighter_data.rotation = deg_to_rad(-5 if self is Truck else 5)
    add_child(fighter_data)
    fighter_data.update_hp(hp, max_hp)

    initial_position = position

func _process(delta: float) -> void:
    if highlight_duration > 0:
        highlight_duration -= delta
        current_shake = .5
        texture_container.scale = texture_container.scale.move_toward(Vector2(1.25, 1.25), delta * 5)
    else:
        texture_container.scale = texture_container.scale.move_toward(Vector2.ONE, delta * 2.5)

    if is_dying:
        position += Vector2.DOWN
        modulate.a = move_toward(modulate.a, 0, delta)
        if modulate.a == 0:
            queue_free()
        return

    if current_shake > 0:
        current_shake -= shake_amount * delta / shake_duration
        if current_shake < 0:
            current_shake = 0
        var shake_position = Vector2(randf_range(-current_shake, current_shake), randf_range(-current_shake, current_shake))
        sprite.position = shake_position
        shadow.position = shadow_position + shake_position

    if is_attacked:
        attacked_interval -= delta
        if attacked_interval < 0:
            attacked_interval = ATTACKED_INTEVAL
            is_attacked = false
    elif is_going_to_center:
        position = position.move_toward(Vector2.ZERO, delta * 750)
        if position == Vector2.ZERO:
            if not is_ready:
                on_ready.emit()
                is_ready = true
        else:
            current_shake = 1
    else:
        position = position.move_toward(initial_position, delta * 750)
        if position != initial_position:
            current_shake = 1


func take_damage(damage: int, self_inflicted: bool = false):
    if toughened > 0:
        damage *= .75
    hp -= damage
    fighter_data.update_hp(hp, max_hp)
    if not self_inflicted:
        is_attacked = true
    if hp <= 0:
        on_died.emit(self)
        is_dying = true

func heal(amount: int):
    hp += amount
    if hp > max_hp:
        hp = max_hp
    fighter_data.update_hp(hp, max_hp)


func update_move_index():
    var s = speed
    if slowed > 0:
        s *= .75
    move_index += MAX_SPEED - s

func project_upcoming_move_index():
    var s = speed
    if slowed > 0:
        s *= .75
    var move_index_projection = move_index
    upcoming_move_indices.clear()
    for i in range(1):
        move_index_projection += MAX_SPEED - s
        upcoming_move_indices.append(move_index_projection)

func move_to_center():
    is_ready = false
    if not is_going_to_center:
        initial_position = position
    is_going_to_center = true

func return_to_initial_position():
    reduce_effect()
    is_going_to_center = false


func perform_move(move: Move, targets: Array[Fighter]):
    current_shake = 5
    if stunned > 0:
        print(title + " is stunned, turn missed")
        return_to_initial_position()
        return
    print(title + " used " + move.title)
    if len(targets) > 0:
        print("  on ", ", ".join(targets.map(func(t: Fighter): return t.title)))
    if self is Truck:
        var truck = self
        truck.heat_level += move.heat_cost
        if move.heat_reduction:
            truck.cool_down(move.heat_reduction)
        fighter_data.update_heat(truck.heat_level, truck.max_heat_level)

    if move.self_damage > 0:
        take_damage(move.self_damage, true)

    # if move.target_type == Move.TargetType.Self:
    #     pass
    if move.move_type == Move.MoveType.Attack:
        for target in targets:
            var damage = move.damage
            if weakened > 0:
                damage *= .25
            if strengthened > 0:
                damage *= 1.25
            target.take_damage(damage)
            target.current_shake = 10
            target.highlight_duration = 0
    else: # Effect
        for target in targets:
            # Debuff
            target.slowed += move.slow_turn
            target.stunned += move.stun_turn
            target.weakened += move.weaken_turn

            # Buff
            target.strengthened += move.strengten_turn
            target.toughened += move.toughen_turn

            if move.heal_amount > 0:
                target.heal(move.heal_amount)
            if move.cool_down_amount > 0 and target is Truck:
                (target as Truck).cool_down(move.cool_down_amount)

            target.current_shake = 5


    return_to_initial_position()

func reduce_effect():
    if slowed > 0:
        slowed -= 1
    if stunned > 0:
        stunned -= 1
    if weakened > 0:
        weakened -= 1
    if strengthened > 0:
        strengthened -= 1
    if toughened > 0:
        toughened -= 1
