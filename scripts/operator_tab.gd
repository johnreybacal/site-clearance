extends MarginContainer
class_name OperatorTab

var operator: Global.Operator

@onready var hp_label: Label = $GridContainer/HpLabel
@onready var hp_button: Button = $GridContainer/HpButton
@onready var damage_label: Label = $GridContainer/DamageLabel
@onready var damage_button: Button = $GridContainer/DamageButton
@onready var speed_label: Label = $GridContainer/SpeedLabel
@onready var speed_button: Button = $GridContainer/SpeedButton

func _ready() -> void:
    redraw()
    Global.money_updated.connect(redraw)

func redraw():
    for stat in Global.stat_keys:
        var cost = Global.get_upgrade_cost(operator, stat)

        if stat == "hp":
            redraw_stat(hp_label, hp_button, stat, cost)
        elif stat == "damage":
            redraw_stat(damage_label, damage_button, stat, cost)
        elif stat == "speed":
            redraw_stat(speed_label, speed_button, stat, cost)

func redraw_stat(label: Label, button: Button, stat: String, cost: float):
    label.text = stat.to_upper() + ": " + str(int(operator.stats[stat])) + " / 15"
    if operator.stats[stat] < 15:
        button.text = "UPGRADE [$" + str(cost) + "]"
        if cost > Global.money:
            button.disabled = true
    else:
        button.disabled = true
        button.text = "MAX"

func _on_hp_button_pressed() -> void:
    Global.upgrade_operator(operator, "hp")
    redraw()

func _on_damage_button_pressed() -> void:
    Global.upgrade_operator(operator, "damage")
    redraw()

func _on_speed_button_pressed() -> void:
    Global.upgrade_operator(operator, "speed")
    redraw()
