extends Node2D

const INTRO_TEXT: String = "Diesel.[PAUSE] Hydraulic.[PAUSE] Steel.[PAUSE] Iron.[PAUSE]

Long ago,[PAUSE] the heavy machines built our world.[PAUSE]
Then,[PAUSE] everything changed when the Advanced Robots arrived.[PAUSE]
They were faster,[PAUSE] making our machines obsolete.[PAUSE]

But then the monsters came.[PAUSE]
The robots were too fragile to fight back.[PAUSE]

Now,[PAUSE] we've dragged the old machines out of the scrap yards.[PAUSE]
We've repurposed them for combat.[PAUSE]
We have a lot of ground to clear.[PAUSE]

This is Site Clearance."

# 4
# 5: Blue
# 11: Red
# 15: Gray
var intro_sequence = INTRO_TEXT.split("[PAUSE]")

var current_intro_text: String

var is_typing: bool
var is_paused: bool

var type_interval = .25

const PAUSE_INTERVAL = .5
var pause_interval = PAUSE_INTERVAL

var sequence_len: int
var sequence_index = 0
var index = 0

var target_color

@onready var label: Label = $IntroLabel
@onready var continue_label: Label = $ContinueLabel
@onready var start_transition_foreground: Sprite2D = $StartTransitionForeground
@onready var type_sfx: AudioStreamPlayer = $TypeSfx

@export var bg_tile_map: TileMapLayer
@export var bg_tile_set: TileSet

var gradient: GradientTexture2D
var speed_multiplier = 1

const BG_X_INITIAL = -13
var bg_x = BG_X_INITIAL
const BG_Y_INITIAL = -7
var bg_y = BG_Y_INITIAL

func _ready() -> void:
    label.text = ""
    is_typing = true
    is_paused = false
    
    current_intro_text = ""
    sequence_len = len(intro_sequence[sequence_index])
    continue_label.visible = false

    target_color = start_transition_foreground.modulate
    Global.bgm.stop()
    draw_bg()

func _process(delta: float) -> void:
    start_transition_foreground.modulate = lerp(start_transition_foreground.modulate, target_color, (delta / 2.5) * speed_multiplier)
    if is_typing:
        type_interval -= delta * speed_multiplier
        if type_interval <= 0:
            current_intro_text += intro_sequence[sequence_index][index]
            index += 1
            type_sfx.pitch_scale = randf_range(6, 8)
            type_sfx.play()
            label.text = current_intro_text
            
            if index == sequence_len:
                is_typing = false
                is_paused = true

            type_interval = randf_range(.005, .05) / speed_multiplier

    if is_paused:
        pause_interval -= delta * speed_multiplier
        if pause_interval <= 0:
            is_paused = false
            sequence_index += 1
            index = 0

            if sequence_index == len(intro_sequence):
                continue_label.visible = true
                Global.bgm.play()
                return
            elif sequence_index == 4:
                target_color = Color.SKY_BLUE
            elif sequence_index == 8:
                target_color = Color.RED
            elif sequence_index == 16:
                target_color = Color.DARK_SLATE_GRAY

            sequence_len = len(intro_sequence[sequence_index])
            is_typing = true
            pause_interval = PAUSE_INTERVAL

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

func _input(event: InputEvent) -> void:
    speed_multiplier = 10 if event.is_pressed() else 1
    if event.is_released():
        speed_multiplier = 1
    if event.is_pressed():
        if continue_label.visible:
            get_tree().change_scene_to_file(Global.MENU_SCENE)
