extends Node

var money: float

# Max 25 each
# Each upgrade increases cost
# 10 + (upgrade * 5) + (accumulated upgrades * 1.5)
class StatModifier:
    var hp: float
    var speed: float
    var damage: float

# cost: 100
var num_operators: int = 1
# Max: 3
var operators: Array[StatModifier]

# Keep track of last used trucks for uniqueness
var last_used: Array[String]

# Increase with each proceeds
var enemy_difficulty: StatModifier


# Achievements
# Exterminator
var enemies_defeated: int
# Scrapyard
var trucks_lost: int
# Ouch
var total_damage: float
# It's very hot in here
var total_heat: float
# Ka-Ching!
var total_money: float
# Big Spender
var total_spent: float

var bgm: AudioStreamPlayer

func _ready() -> void:
    bgm = AudioStreamPlayer.new()
    bgm.stream = preload("res://assets/bgm/chill-drum-loop.mp3")
    bgm.volume_db = -10
    add_child(bgm)
    bgm.play()