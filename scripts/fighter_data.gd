extends Node2D
class_name FighterData

@onready var skew_container: Node2D = $SkewContainer
@onready var hp: TextureProgressBar = $SkewContainer/HP
@onready var heat: TextureProgressBar = $SkewContainer/Heat
@onready var status: HBoxContainer = $Status
@onready var fighter_name: Label = $Name

var is_truck: bool

var target_hp: float = 100
var target_heat: float = 0

var damage_buff_texture = preload("res://assets/sprites/status/damage.png")
var defense_buff_texture = preload("res://assets/sprites/status/defense.png")
var slow_debuff_texture = preload("res://assets/sprites/status/slow.png")
var stun_debuff_texture = preload("res://assets/sprites/status/stun.png")
var overheat_texture = preload("res://assets/sprites/status/overheat.png")
var floating_text_scene = preload("res://scenes/floating_text.tscn")

var overheat_status: Node

class TextQueue:
    var text: String
    var color: Color

var text_queue: Array[TextQueue] = []
const TEXT_INTERVAL = 0.5
var text_interval = 0

func _ready() -> void:
    status.scale = Vector2(.25, .25)
    status.position.x = status.position.x * .25
    hp.value = 0
    heat.value = 100
    if not is_truck:
        heat.visible = false
        $SkewContainer/HeatBg.visible = false
    else:
        overheat_status = add_status(overheat_texture, 0)

func _process(delta: float) -> void:
    if hp.value != target_hp:
        hp.value = move_toward(hp.value, target_hp, delta * 100)
    if heat.value != target_heat:
        heat.value = move_toward(heat.value, target_heat, delta * 100)
    if len(text_queue) > 0:
        text_interval -= delta
        if text_interval <= 0:
            var item = text_queue.pop_back()
            display_text(item.text, item.color)
            text_interval = TEXT_INTERVAL if len(text_queue) > 0 else 0.0

func update_hp(amount: float, max_amount: float):
    target_hp = (amount / max_amount) * 100

func update_heat(amount: float, max_amount: float):
    target_heat = (amount / max_amount) * 100
    var previous_show_overheat = overheat_status.visible
    var show_overheat = amount >= max_amount
    overheat_status.visible = show_overheat
    if show_overheat and not previous_show_overheat:
        queue_text("Overheating", Color.RED)

func hide_data():
    skew_container.visible = false
    status.visible = false


func add_status(texture: CompressedTexture2D, _duration: int):
    var rect = TextureRect.new()
    rect.texture = texture
    rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
    rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    # var label = Label.new()
    # label.text = str(duration)
    # rect.add_child(label)
    var panel = PanelContainer.new()
    panel.add_child(rect)

    status.add_child(panel)

    return panel

func update_status(
    slow_debuff_turns: int,
    stun_debuff_turns: int,
    damage_buff_turns: int,
    defense_buff_turns: int,
):
    for node in status.get_children():
        if node != overheat_status:
            node.queue_free()

    if slow_debuff_turns > 0:
        add_status(slow_debuff_texture, slow_debuff_turns)
    if stun_debuff_turns > 0:
        add_status(stun_debuff_texture, stun_debuff_turns)
    if damage_buff_turns > 0:
        add_status(damage_buff_texture, damage_buff_turns)
    if defense_buff_turns > 0:
        add_status(defense_buff_texture, defense_buff_turns)

func queue_text(value: String, color: Color = "#FFFFFF"):
    var item = TextQueue.new()
    item.text = value
    item.color = color
    text_queue.push_front(item)

func display_text(value: String, color: Color = "#FFFFFF"):
    var floating_text: FloatingText = floating_text_scene.instantiate()
    floating_text.color = color
    floating_text.text = value
    add_child(floating_text)
