extends Node

var operator_name_options = [
    "Muhammad", "Olivia", "Aarav", "Yichén", "Mateo",
    "Amara", "Noah", "Sofia", "Zahra", "Liam",
    "Saanvi", "Santiago", "Fatima", "Hiroshi", "Isabella",
    "Chen", "Lucas", "Aaliyah", "Xavier", "Mei",
    "Omar", "Kiara", "Koa", "Elena", "Arjun"
]

var money: float = 25

# Max 25 each
# Each upgrade increases cost
# 10 + (upgrade * 5) + (accumulated upgrades * 1.5)
# speed is multiplied by 3 for significant increase
var stat_keys = ["hp", "damage", "speed"]
class StatModifier:
    var hp: float = 0
    var damage: float = 0
    var speed: float = 0
class Operator:
    var name: String
    var stats: StatModifier

# cost: 100
var num_operators: int = 1
# Max: 3
var operators: Array[Operator]

var last_trucks_used: Array[String]

# Keep track of last used trucks for uniqueness
var last_used: Array[String]

# Increase with each proceeds
var enemy_stat_modifier = StatModifier.new()
var max_enemies = 4


# Achievements
# Exterminator
var enemies_defeated: int
# Scrapyard
var trucks_lost: int
# It's very hot in here
var total_heat: float
# Ka-Ching!
var total_money: float
# Big Spender
var total_spent: float

var bgm: AudioStreamPlayer

signal money_updated()

var GAME_SCENE = "res://scenes/game.tscn"
var MENU_SCENE = "res://scenes/menu.tscn"

func _ready() -> void:
    if len(operators) == 0:
        recruit_operator()
        recruit_operator()
        recruit_operator()
    bgm = AudioStreamPlayer.new()
    bgm.stream = preload("res://assets/bgm/chill-drum-loop.mp3")
    bgm.volume_db = -10
    add_child(bgm)
    bgm.play()

func earn_money(amount: float):
    money += amount
    total_money += amount
    money_updated.emit()

func spend_money(amount: float):
    money -= amount
    total_spent += amount
    money_updated.emit()

func increment_enemies_defeated():
    enemies_defeated += 1
    # Increase difficulty
    var stat = stat_keys.pick_random()
    var increases = [.5, .75, 1]
    enemy_stat_modifier[stat] += increases.pick_random()

func increment_trucks_lost():
    trucks_lost += 1

func add_total_heat(amount: float):
    total_heat += amount

func recruit_operator():
    var cost = get_operator_cost()
    spend_money(cost)
    if len(operators) < 3:
        var name_index = randi_range(0, len(operator_name_options) - 1)
        var op = Operator.new()
        op.stats = StatModifier.new()
        op.name = operator_name_options[name_index]
        operator_name_options.remove_at(name_index)
        operators.append(op)

    max_enemies = len(operators) + 1

func get_operator_cost():
    return 150 * len(operators)

func upgrade_operator(op: Operator, stat: String):
    var cost = get_upgrade_cost(op, stat)
    spend_money(cost)
    if op.stats[stat] < 10:
        op.stats[stat] += 1

func get_upgrade_cost(op: Operator, stat: String):
    var accumulated_stats = op.stats.hp + op.stats.damage + op.stats.speed
    return 10 + (op.stats[stat] * 2.5) + (accumulated_stats * .25)
