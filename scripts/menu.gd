extends Control
class_name Menu


@export var bg_tile_map: TileMapLayer
@export var bg_tile_set: TileSet
@export var operator_tab: PackedScene
const BG_X_INITIAL = -13
var bg_x = BG_X_INITIAL
const BG_Y_INITIAL = -7
var bg_y = BG_Y_INITIAL

@onready var tab_container: TabContainer = $UpgradePanel/TabContainer
@onready var money_label: Label = $UpgradePanel/MoneyLabel
@onready var recruit_button: Button = $UpgradePanel/RecruitButton

@onready var sunlight_foreground: Sprite2D = $SunlightForeground

func _ready() -> void:
    draw_bg()
    print("op", Global.operators)
    for op in Global.operators:
        draw_operator_tab(op)

    redraw_recruit_operator()
    redraw_money()
    Global.money_updated.connect(redraw_money)

    recruit_button.text = "RECRUIT OPERATOR [$" + str(Global.get_operator_cost()) + "]"

func _process(delta: float) -> void:
    var sun_position = clampf(800 / get_local_mouse_position().x, 0, 1)
    if sunlight_foreground.texture.fill_to.x != sun_position:
        sunlight_foreground.texture.fill_to.x = move_toward(sunlight_foreground.texture.fill_to.x, sun_position, delta / 3)

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
    print(Global.money)
    money_label.text = "$" + str(Global.money)

func redraw_recruit_operator():
    if len(Global.operators) < 3:
        var cost = Global.get_operator_cost()
        recruit_button.text = "RECRUIT OPERATOR [$" + str(cost) + "]"
        if cost > Global.money:
            recruit_button.disabled = true
    else:
        recruit_button.visible = false

func draw_operator_tab(op: Global.Operator):
    var tab: OperatorTab = operator_tab.instantiate()
    tab.name = op.name
    tab.operator = op
    tab_container.add_child(tab)


func _on_recruit_button_pressed() -> void:
    Global.recruit_operator()
    draw_operator_tab(Global.operators.back())
    redraw_recruit_operator()


func _on_start_button_pressed() -> void:
    get_tree().change_scene_to_file(Global.GAME_SCENE)
