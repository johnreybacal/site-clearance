extends Node2D
class_name Fighter


const MAX_SPEED = 100

@export var title: String
@export var max_hp: float = 10
@export var speed: float = 75
var hp: float

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
var slow_debuff_turns: int
var stun_debuff_turns: int
# Buff
var damage_buff_turns: int
var defense_buff_turns: int


var FighterDataScene = preload("res://scenes/fighter_data.tscn")
var smoke_scene = preload("res://scenes/smoke.tscn")

func _ready():
    hp = max_hp
    # speed = randf_range(speed - 1, speed + 1)

    texture_container = get_node("TextureContainer")
    sprite = get_node("TextureContainer/Sprite2D") as Sprite2D
    sprite.z_index = 2
    shadow = sprite.duplicate()
    shadow.name = "ShadowSprite"
    shadow.modulate = "#00000044"
    shadow_position = Vector2(5, shadow.texture.get_height() * .66)
    shadow.position = shadow_position
    shadow.scale = Vector2(sprite.scale.x, sprite.scale.y / -1.5)
    shadow.skew = deg_to_rad(-30)
    shadow.z_index = 1
    texture_container.add_child(shadow)

    fighter_data = FighterDataScene.instantiate()
    fighter_data.is_truck = self is Truck
    add_child(fighter_data)
    fighter_data.skew_container.position = Vector2(-50 if self is Truck else 50, 0)
    fighter_data.skew_container.skew = deg_to_rad(-25 if self is Truck else 25)
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
        current_shake = 1
        position += Vector2.LEFT if self is Truck else Vector2.RIGHT
        texture_container.scale.x = move_toward(texture_container.scale.x, -1, delta * 10)
        modulate.a = move_toward(modulate.a, 0, delta)
        if modulate.a == 0:
            queue_free()

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


func take_damage(damage: float, self_inflicted: bool = false):
    if defense_buff_turns > 0:
        damage *= .5
    hp -= damage
    fighter_data.queue_text("-" + str(damage))
    fighter_data.update_hp(hp, max_hp)
    var smoke: Node2D = smoke_scene.instantiate()
    if self is Enemy:
        smoke.scale = Vector2(-1, 1)
    add_child(smoke)
    if not self_inflicted:
        is_attacked = true
    if hp <= 0:
        on_died.emit(self)
        fighter_data.hide_data()
        is_dying = true
    else:
        current_shake = 10

func heal(amount: float):
    hp += amount
    if hp > max_hp:
        hp = max_hp
    fighter_data.queue_text("+" + str(amount))
    fighter_data.update_hp(hp, max_hp)


func update_move_index():
    var s = speed * .25 if slow_debuff_turns > 0 else speed
    move_index += round(MAX_SPEED - s)
    # print(title, " speed: ", s)

func project_upcoming_move_index():
    var s = speed * .25 if slow_debuff_turns > 0 else speed
    var move_index_projection: int = move_index
    # print(title, " upcoming speed: ", s)
    upcoming_move_indices.clear()
    for i in range(1):
        move_index_projection += round(MAX_SPEED - s)
        upcoming_move_indices.append(move_index_projection)

func move_to_center():
    is_ready = false
    is_going_to_center = true

func return_to_initial_position():
    reduce_effect()
    is_going_to_center = false


func perform_move(move: Move, targets: Array[Fighter]):
    current_shake = 5
    if stun_debuff_turns > 0:
        fighter_data.queue_text("STUNNED")
        print(title + " is stunned, turn missed")
        return_to_initial_position()
        return

    var move_stats = "DMG: " + str(move.damage)
    print(title + " used " + move.title + "::" + move_stats)
    
    if len(targets) > 0:
        print("  on ", ", ".join(targets.map(func(t: Fighter): return t.title)))
    if self is Truck:
        self.heat_level += move.heat_cost
        fighter_data.update_heat(self.heat_level, self.max_heat_level)

    if move.self_damage > 0:
        take_damage(move.self_damage, true)

    if move.target_type == Move.TargetType.Self:
        targets = [self]

    for target in targets:
        target.highlight_duration = 0
        
        # Attack
        if move.damage > 0:
            var damage = move.damage
            if damage_buff_turns > 0:
                damage *= 1.5
            target.take_damage(damage)
        
        # Debuff
        if move.slow_debuff_turns > 0:
            target.fighter_data.queue_text("SLOWED")
            target.slow_debuff_turns += move.slow_debuff_turns
            
        if move.stun_debuff_turns > 0:
            target.fighter_data.queue_text("STUNNED")
            target.stun_debuff_turns += move.stun_debuff_turns

        # Buff
        if move.damage_buff_turns > 0:
            target.fighter_data.queue_text("DMG+")
            target.damage_buff_turns += move.damage_buff_turns
        if move.defense_buff_turns > 0:
            target.fighter_data.queue_text("DEF+")
            target.defense_buff_turns += move.defense_buff_turns

        if move.heal_amount > 0:
            target.heal(move.heal_amount)
        if move.cool_down_amount > 0 and target is Truck:
            (target as Truck).cool_down(move.cool_down_amount)

        target.current_shake = 5
        target.update_status()

    return_to_initial_position()

func reduce_effect():
    if slow_debuff_turns > 0:
        slow_debuff_turns -= 1
    if stun_debuff_turns > 0:
        stun_debuff_turns -= 1
    if damage_buff_turns > 0:
        damage_buff_turns -= 1
    if defense_buff_turns > 0:
        defense_buff_turns -= 1
    update_status()

func update_status():
    fighter_data.update_status(slow_debuff_turns, stun_debuff_turns, damage_buff_turns, defense_buff_turns)
