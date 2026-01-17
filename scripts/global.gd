extends Node

var operator_name_options = [
    "Muhammad", "Olivia", "Aarav", "Yichén", "Mateo",
    "Amara", "Noah", "Sofia", "Zahra", "Liam",
    "Saanvi", "Santiago", "Fatima", "Hiroshi", "Isabella",
    "Chen", "Lucas", "Aaliyah", "Xavier", "Mei",
    "Omar", "Kiara", "Koa", "Elena", "Arjun"
]

var money: float = 2500

# Max 15 each
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
# Kaiju
var kaijus_defeated: int
# Scrapyard
var trucks_lost: int
# It's very hot in here
var total_heat: float
# Ka-Ching!
var total_money: float
# Big Spender
var total_spent: float
# Anti environmentalist
var trees_fallen: int
# Damage dealt
var damage_dealt: float
# Damage received
var damage_received: float

var bgm: AudioStreamPlayer

signal money_updated()

var GAME_SCENE = "res://scenes/game.tscn"
var MENU_SCENE = "res://scenes/menu.tscn"

var achievement_notification_scene = preload("res://scenes/achievement_notification.tscn")

class Achievement:
    var title: String
    var description: String

var achievement_queue: Array[Achievement] = []
var achievements: Array[Achievement] = []
const ACHIEVEMENT_INTERVAL = 3.5
var achievement_interval = 0
signal on_new_achievement()

func _ready() -> void:
    if len(operators) == 0:
        recruit_operator()
        # recruit_operator()
        # recruit_operator()
    bgm = AudioStreamPlayer.new()
    bgm.stream = preload("res://assets/bgm/chill-drum-loop.mp3")
    bgm.volume_db = -15
    add_child(bgm)
    bgm.play()

func _process(delta: float) -> void:
    if len(achievement_queue) > 0:
        achievement_interval -= delta
        if achievement_interval <= 0:
            var item = achievement_queue.pop_back()
            add_achievement(item)
            achievement_interval = ACHIEVEMENT_INTERVAL
    elif achievement_interval > 0:
        achievement_interval -= delta

func earn_money(amount: float):
    money += amount
    total_money += amount
    money_updated.emit()

    if total_money > 50:
        queue_achievement("Earner I", "Earn 50 dollars")
    if total_money > 250:
        queue_achievement("Earner II", "Earn 250 dollars")
    if total_money > 500:
        queue_achievement("Earner III", "Earn 500 dollars")
    if total_money > 1000:
        queue_achievement("Earner IV", "Earn 1000 dollars")

func spend_money(amount: float):
    money -= amount
    total_spent += amount
    money_updated.emit()

    if total_spent > 50:
        queue_achievement("Spender I", "Spend 50 dollars")
    if total_spent > 250:
        queue_achievement("Spender II", "Spend 250 dollars")
    if total_spent > 500:
        queue_achievement("Spender III", "Spend 500 dollars")
    if total_spent > 1000:
        queue_achievement("Spender IV", "Spend 1000 dollars")

func increment_enemies_defeated():
    enemies_defeated += 1
    # Increase difficulty
    var stat = stat_keys.pick_random()
    var increases = [.5, .75, 1, 1.25]
    # Decrease max increase stat as enemies appear
    for i in range(len(operators)):
        increases.pop_back()

    # Cap enemy stat to double of player's
    enemy_stat_modifier[stat] += increases.pick_random()
    if enemy_stat_modifier[stat] > 30:
        enemy_stat_modifier[stat] = 30
        
    if enemies_defeated == 1:
        queue_achievement("My first kill", "Defeat 1 monster")
    if enemies_defeated == 5:
        queue_achievement("It gets harder from here", "Defeat 5 monsters")
    if enemies_defeated == 25:
        queue_achievement("Professional exterminator", "Defeat 25 monsters")
    if enemies_defeated == 100:
        queue_achievement("Bane of monsters", "Defeat 100 monsters")

func increment_kaiju_defeated():
    kaijus_defeated += 1
    # Increase difficulty
    var stat = stat_keys.pick_random()
    var increases = [.5, .75, 1, 1.25]
    # Decrease max increase stat as enemies appear
    for i in range(len(operators)):
        increases.pop_back()

    # Cap enemy stat to double of player's
    enemy_stat_modifier[stat] += increases.pick_random()
    if enemy_stat_modifier[stat] > 30:
        enemy_stat_modifier[stat] = 30
        
    if kaijus_defeated == 1:
        queue_achievement("Kaiju killer", "Defeat 1 kaiju level monster")
    if kaijus_defeated == 5:
        queue_achievement("Kaiju slayer", "Defeat 5 kaiju level monsters")
    if kaijus_defeated == 10:
        queue_achievement("Kaiju exterminator", "Defeat 10 kaiju level monsters")
    if kaijus_defeated == 25:
        queue_achievement("Kaiju kaiju", "Defeat 25 kaiju level monsters")

func increment_trucks_lost():
    trucks_lost += 1

    if trucks_lost == 1:
        queue_achievement("Don't worry, we'll fix it", "Lose 1 truck")
    if trucks_lost == 10:
        queue_achievement("We got more", "Lose 10 trucks")
    if trucks_lost == 25:
        queue_achievement("Is this obsolete?", "Lose 25 trucks")

func increment_trees_fallen():
    trees_fallen += 1

    if trees_fallen > 250:
        queue_achievement("Not cool •ˋ◠ˊ•", "Cause 250 trees to fall")
    if trees_fallen > 750:
        queue_achievement("So not cool •ˋ◠ˊ•", "Cause 750 trees to fall")
    if trees_fallen > 1500:
        queue_achievement("•ˋ◠ˊ•", "Cause 1500 trees to fall")

func add_total_heat(amount: float):
    total_heat += amount

    if total_heat > 100:
        queue_achievement("It's very hot in here", "Accumulate a total of 100 heat level")
    if total_heat > 250:
        queue_achievement("Sure is nice outside", "Accumulate a total of 250 heat level")
    if total_heat > 500:
        queue_achievement("Doesn't this thing have AC?", "Accumulate a total of 500 heat level")

func add_damage_received(amount: float):
    damage_received += amount

    if damage_received > 100:
        queue_achievement("A little dent", "Take a total of 100 damage")
    if damage_received > 250:
        queue_achievement("It still works", "Take a total of 250 damage")
    if damage_received > 500:
        queue_achievement("Unbreakable", "Take a total of 500 damage")

func add_damage_dealt(amount: float):
    damage_dealt += amount

    if damage_dealt > 100:
        queue_achievement("Road Rage", "Deal a total of 100 damage")
    if damage_dealt > 250:
        queue_achievement("Mad Max", "Deal a total of 250 damage")
    if damage_dealt > 500:
        queue_achievement("Keep distance from machine", "Deal a total of 500 damage")

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

    if len(operators) == 2:
        queue_achievement("Prepare for trouble", "Hire a second operator")
    if len(operators) == 3:
        queue_achievement("The three musketeers", "Hire a third operator")

    max_enemies = len(operators) + 1

func get_operator_cost():
    return 100 * len(operators)

func upgrade_operator(op: Operator, stat: String):
    var cost = get_upgrade_cost(op, stat)
    spend_money(cost)
    if op.stats[stat] < 15:
        op.stats[stat] += 1
    
    if op.stats[stat] == 15:
        queue_achievement(stat.to_upper() + " Specialist", "Max out " + stat.to_upper())
    if op.stats.hp + op.stats.speed + op.stats.damage == 45:
        queue_achievement("Smooth operator", "Max out all stats")


func get_upgrade_cost(op: Operator, stat: String):
    var accumulated_stats = op.stats.hp + op.stats.damage + op.stats.speed
    return 10 + (op.stats[stat] * 2.5) + (accumulated_stats * .25)


func queue_achievement(title: String, description: String):
    var is_already_achieved = achievements.any(func(a: Achievement): return a.title == title) or achievement_queue.any(func(a: Achievement): return a.title == title)
    if is_already_achieved:
        return
    var achievement = Achievement.new()
    achievement.title = title
    achievement.description = description
    achievement_queue.push_front(achievement)

func add_achievement(achievement: Achievement):
    var achievement_notif: AchievementNotification = achievement_notification_scene.instantiate()
    achievement_notif.title_text = achievement.title
    achievement_notif.description_text = achievement.description
    add_child(achievement_notif)
    achievements.append(achievement)
    on_new_achievement.emit()
