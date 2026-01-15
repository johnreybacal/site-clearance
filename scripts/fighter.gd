extends Node2D
class_name Fighter


const MAX_SPEED = 100

@export var title: String
@export var max_hp: float = 10
@export var speed: float = 75
var hp: float
var heal_bonus: float

@export var moves: Array[Move]

var move_index: int = 0
var upcoming_move_indices: Array[int]

signal on_ready(fighter: Fighter)
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

var is_entering = true
var is_leaving = false

var highlight_duration = 0

# Debuff
var slow_debuff_turns: int
var stun_debuff_turns: int

var is_recently_slowed: bool

# Buff
var damage_buff_turns: int
var defense_buff_turns: int


var FighterDataScene = preload("res://scenes/fighter_data.tscn")
var smoke_scene = preload("res://scenes/smoke.tscn")
var hit_sfx_stream = preload("res://assets/sfx/hit.mp3")
var fighter_sfx_stream: AudioStream

var hit_sfx: AudioStreamPlayer
var fighter_sfx: AudioStreamPlayer

func _ready():
    initial_position = position
    position = Vector2(initial_position.x + (-150 if self is Truck else 150), initial_position.y)
    is_entering = true

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

    hit_sfx = AudioStreamPlayer.new()
    hit_sfx.name = "HitSfx"
    hit_sfx.stream = hit_sfx_stream
    hit_sfx.volume_db = -5
    add_child(hit_sfx)

    fighter_sfx = AudioStreamPlayer.new()
    fighter_sfx.name = "FighterSfx"
    fighter_sfx.stream = fighter_sfx_stream
    fighter_sfx.volume_db = -10
    add_child(fighter_sfx)


func _process(delta: float) -> void:
    if is_entering:
        position = position.move_toward(initial_position, delta * 250)
        current_shake = 1
        if position == initial_position:
            is_entering = false
            on_entry()
    if highlight_duration > 0:
        highlight_duration -= delta
        current_shake = .5
        texture_container.scale = texture_container.scale.move_toward(Vector2(1.25, 1.25), delta * 5)
        if fighter_data:
            fighter_data.fighter_name.visible = true
    else:
        if fighter_data:
            fighter_data.fighter_name.visible = false
        texture_container.scale = texture_container.scale.move_toward(Vector2.ONE, delta * 2.5)

    if is_leaving:
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
                on_ready.emit(self)
                is_ready = true
        else:
            current_shake = 1
    elif not is_entering:
        position = position.move_toward(initial_position, delta * 1000)
        if position != initial_position:
            current_shake = 1

func on_entry():
    fighter_data = FighterDataScene.instantiate()
    fighter_data.is_truck = self is Truck
    add_child(fighter_data)
    fighter_data.fighter_name.text = title
    if self is Truck:
        var truck = self as Truck
        fighter_data.fighter_name.text += " [" + truck.operator.name + "]"
    # fighter_data.fighter_name.rotation = deg_to_rad(15 if self is Truck else -15)
    fighter_data.skew_container.position = Vector2(-50 if self is Truck else 50, 0)
    fighter_data.skew_container.skew = deg_to_rad(-25 if self is Truck else 25)

    hp = max_hp
    fighter_data.update_hp(hp, max_hp)
    
    if self is Truck:
        var truck = self as Truck
        fighter_data.update_heat(truck.heat_level, truck.max_heat_level)


func take_damage(damage: float, self_inflicted: bool = false):
    if defense_buff_turns > 0:
        damage *= .5
    hp -= damage
    fighter_data.queue_text("-" + str(round(damage)) + " HP", Color.ORANGE_RED)
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
        is_leaving = true
        play_fighter_sfx()
    else:
        current_shake = 10

    hit_sfx.pitch_scale = randf_range(0.8, 1.2)
    hit_sfx.play()

func heal(amount: float):
    amount += heal_bonus
    hp += amount
    if hp > max_hp:
        hp = max_hp
    fighter_data.queue_text("+" + str(round(amount)) + " HP", Color.GREEN)
    fighter_data.update_hp(hp, max_hp)

func get_speed_penalty():
    var s = speed * .25 if slow_debuff_turns > 0 else speed
    return speed - s

func update_move_index():
    var s = speed - get_speed_penalty()
    move_index += int(floor(MAX_SPEED - s))
    # print(title, " speed: ", s)

func project_upcoming_move_index():
    var s = speed - get_speed_penalty()
    var move_index_projection: int = move_index
    # print(title, " upcoming speed: ", s)
    upcoming_move_indices.clear()
    for i in range(2):
        move_index_projection += int(floor(MAX_SPEED - s))
        upcoming_move_indices.append(move_index_projection)

func move_to_center():
    is_ready = false
    is_going_to_center = true
    play_fighter_sfx()

func return_to_initial_position():
    reduce_effect()
    is_going_to_center = false


func perform_move(move: Move, targets: Array[Fighter]):
    current_shake = 5
    if stun_debuff_turns > 0:
        print(title + " is stunned, turn missed")
        return_to_initial_position()
        return

    var move_stats = "DMG: " + str(move.damage)
    print(title + " used " + move.title + "::" + move_stats)
    
    if len(targets) > 0:
        print("  on ", ", ".join(targets.map(func(t: Fighter): return t.title)))
    if self is Truck:
        self.heat_level += move.heat_cost
        Global.add_total_heat(move.heat_cost)
        fighter_data.update_heat(self.heat_level, self.max_heat_level)

    if move.self_damage > 0:
        take_damage(move.self_damage, true)

    if move.target_type == Move.TargetType.Self:
        targets = [self]

    if move.move_type == Move.MoveType.Effect:
        play_fighter_sfx()

    for target in targets:
        target.highlight_duration = 0
        
        # Attack
        if move.damage > 0:
            var damage = move.damage
            if damage_buff_turns > 0:
                damage *= 1.5
            target.take_damage(damage)
        
        #  + 1 if target == self else 0: to counteract reduce effect
        # Debuff
        if move.slow_debuff_turns > 0:
            target.fighter_data.queue_text("SLOWED")
            target.is_recently_slowed = target.slow_debuff_turns == 0
            target.slow_debuff_turns += move.slow_debuff_turns + (1 if target == self else 0)
            
        if move.stun_debuff_turns > 0:
            target.fighter_data.queue_text("STUNNED")
            target.stun_debuff_turns += move.stun_debuff_turns + (1 if target == self else 0)

        # Buff
        if move.damage_buff_turns > 0:
            target.fighter_data.queue_text("DMG+")
            target.damage_buff_turns += move.damage_buff_turns + (1 if target == self else 0)
        if move.defense_buff_turns > 0:
            target.fighter_data.queue_text("DEF+")
            target.defense_buff_turns += move.defense_buff_turns + (1 if target == self else 0)

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

func play_fighter_sfx():
    fighter_sfx.pitch_scale = randf_range(0.8, 1.2)
    fighter_sfx.play()
