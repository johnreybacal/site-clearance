extends Control
class_name Menu


@export var bg_tile_map: TileMapLayer
@export var bg_tile_set: TileSet
@export var operator_tab: PackedScene
const BG_X_INITIAL = -13
var bg_x = BG_X_INITIAL
const BG_Y_INITIAL = -7
var bg_y = BG_Y_INITIAL

@onready var foldable_container: FoldableContainer = $MarginContainer/HBoxContainer/FoldableContainer
@onready var monsters_defeated_value: Label = $MarginContainer/HBoxContainer/FoldableContainer/TabContainer/Statistics/GridContainer/MonstersDefeatedValue
@onready var kaiju_defeated_value: Label = $MarginContainer/HBoxContainer/FoldableContainer/TabContainer/Statistics/GridContainer/KaijuDefeatedValue
@onready var trucks_lost_value: Label = $MarginContainer/HBoxContainer/FoldableContainer/TabContainer/Statistics/GridContainer/TrucksLostValue
@onready var money_earned_value: Label = $MarginContainer/HBoxContainer/FoldableContainer/TabContainer/Statistics/GridContainer/MoneyEarnedValue
@onready var money_spent_value: Label = $MarginContainer/HBoxContainer/FoldableContainer/TabContainer/Statistics/GridContainer/MoneySpentValue
@onready var heat_value: Label = $MarginContainer/HBoxContainer/FoldableContainer/TabContainer/Statistics/GridContainer/HeatValue
@onready var damage_dealt_value: Label = $MarginContainer/HBoxContainer/FoldableContainer/TabContainer/Statistics/GridContainer/DamageDealtValue
@onready var damage_received_value: Label = $MarginContainer/HBoxContainer/FoldableContainer/TabContainer/Statistics/GridContainer/DamageReceivedValue
@onready var trees_value: Label = $MarginContainer/HBoxContainer/FoldableContainer/TabContainer/Statistics/GridContainer/TreesValue

@onready var achievements_container: GridContainer = $MarginContainer/HBoxContainer/FoldableContainer/TabContainer/Achievements/ScrollContainer/GridContainer

@onready var operators_tab_container: TabContainer = $MarginContainer/HBoxContainer/VBoxContainer/UpgradePanel/TabContainer
@onready var money_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/UpgradePanel/MoneyLabel
@onready var recruit_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/UpgradePanel/RecruitButton

@onready var start_transition_foreground: Sprite2D = $StartTransitionForeground
@onready var sunlight_foreground: Sprite2D = $SunlightForeground

func _ready() -> void:
    draw_bg()
    for op in Global.operators:
        draw_operator_tab(op)

    redraw_recruit_operator()
    redraw_money()
    Global.money_updated.connect(redraw_money)
    Global.money_updated.connect(redraw_money_spent)

    recruit_button.text = "RECRUIT OPERATOR [$" + str(Global.get_operator_cost()) + "]"
    monsters_defeated_value.text = str(Global.enemies_defeated)
    kaiju_defeated_value.text = str(Global.kaijus_defeated)
    trucks_lost_value.text = str(Global.trucks_lost)
    heat_value.text = str(round(Global.total_heat))
    money_earned_value.text = "$" + str(round(Global.total_money))
    damage_dealt_value.text = str(round(Global.damage_dealt))
    damage_received_value.text = str(round(Global.damage_received))
    trees_value.text = str(Global.trees_fallen)
    redraw_money_spent()
    for achievement in Global.achievements:
        var label = Label.new()
        label.text = achievement.title + " - " + achievement.description
    redraw_achievements()
    Global.on_new_achievement.connect(redraw_achievements)
    foldable_container.folded = true

func _process(delta: float) -> void:
    var sun_position = clampf(800 / get_local_mouse_position().x, 0, 1)
    if sunlight_foreground.texture.fill_to.x != sun_position:
        sunlight_foreground.texture.fill_to.x = move_toward(sunlight_foreground.texture.fill_to.x, sun_position, delta / 3)

    if start_transition_foreground.modulate.a != 0:
        start_transition_foreground.modulate.a = move_toward(start_transition_foreground.modulate.a, 0, delta * 2)

func draw_bg():
    var source_id = bg_tile_set.get_source_id(0)
    var atlas_coords = [Vector2i(8, 2), Vector2i(0, 0), Vector2i(2, 2), Vector2i(2, 6), Vector2i(6, 2)]

    var max_bg_x = abs(BG_X_INITIAL)

    bg_tile_map.local_to_map(Vector2.ZERO)
        
    for x in range(bg_x, max_bg_x):
        for y in range(bg_y, bg_y + abs(BG_Y_INITIAL) * 2):
            var coords = Vector2i(x, y)
            bg_tile_map.set_cell(coords, source_id, atlas_coords.pick_random())
        bg_x = x
    bg_y = BG_Y_INITIAL

func redraw_money():
    money_label.text = "$" + str(round(Global.money))

func redraw_recruit_operator():
    if len(Global.operators) < 3:
        var cost = Global.get_operator_cost()
        recruit_button.text = "RECRUIT OPERATOR [$" + str(round(cost)) + "]"
        if cost > Global.money:
            recruit_button.disabled = true
    else:
        recruit_button.visible = false

func draw_operator_tab(op: Global.Operator):
    var tab: OperatorTab = operator_tab.instantiate()
    tab.name = op.name
    tab.operator = op
    operators_tab_container.add_child(tab)

func redraw_achievements():
    for node in achievements_container.get_children():
        node.queue_free()
    for achievement in Global.achievements:
        var label = Label.new()
        label.text = achievement.title
        achievements_container.add_child(label)
        label = Label.new()
        label.text = achievement.description
        label.size_flags_horizontal = Control.SIZE_EXPAND
        achievements_container.add_child(label)

func redraw_money_spent():
    money_spent_value.text = "$" + str(round(Global.total_spent))

func _on_recruit_button_pressed() -> void:
    Global.recruit_operator()
    draw_operator_tab(Global.operators.back())
    redraw_recruit_operator()


func _on_start_button_pressed() -> void:
    Global.save_data()
    get_tree().change_scene_to_file(Global.GAME_SCENE)
