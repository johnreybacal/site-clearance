extends Control
class_name Menu


@export var bg_tile_map: TileMapLayer
@export var bg_tile_set: TileSet

const BG_X_INITIAL = -13
var bg_x = BG_X_INITIAL
const BG_Y_INITIAL = -7
var bg_y = BG_Y_INITIAL

@onready var sunlight_foreground: Sprite2D = $SunlightForeground

func _ready() -> void:
    draw_bg()

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