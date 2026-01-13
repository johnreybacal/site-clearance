extends Node2D
class_name GameManager

class FighterQueue:
    var fighter: Fighter
    var move_index: int

@export var hud: HUD
@export var truck_scenes: Array[PackedScene]
@export var enemy_scenes: Array[PackedScene]
@export var bg_tile_map: TileMapLayer
@export var bg_tile_set: TileSet

var MAX_TICK = 12
var tick = 0
var is_ticking = true
const TICK_INTERVAL = 1
var tick_interval = TICK_INTERVAL

var prev_move_index: int = 0
var move_index: int = 0

var fighters: Array[Fighter] = []
var turn_queue: Array[FighterQueue] = []
var turn_fighters: Array[Fighter] = []
var current_fighter_index: int
var current_fighter: Fighter
var is_next_turn: bool = false

var is_proceeding = false
const PROCEED_INTERVAL = 2
var proceed_interval = PROCEED_INTERVAL
var proceeds: int = 0
const BARREN_INTERVAL = .1
var barren_interval = BARREN_INTERVAL

const BG_X_INITIAL = -13
var bg_x = BG_X_INITIAL
const BG_Y_INITIAL = -7
var bg_y = BG_Y_INITIAL
@export var sunlight_foreground: Sprite2D
@export var sunlight_gradient: GradientTexture2D
var sun_position = 0

@export var floating_text_scene: PackedScene

var num_trucks = 3
var num_enemies = 4

var trucks_spawned: Array[String] = []

var trucks_position = [
    [Vector2(-300, 0)],
    [Vector2(-275, 75), Vector2(-275, -75)],
    [Vector2(-250, 100), Vector2(-300, 0), Vector2(-250, -100)]
]
var enemies_position = [
    [Vector2(300, 0)],
    [Vector2(275, 75), Vector2(275, -75)],
    [Vector2(250, 100), Vector2(300, 0), Vector2(250, -100)],
    [Vector2(225, 125), Vector2(300, 50), Vector2(300, -50), Vector2(225, -125)],
]

func _ready() -> void:
    var truck_count = 0
    while truck_count < num_trucks:
        var truck: Truck = truck_scenes.pick_random().instantiate()
        
        if truck.title in trucks_spawned:
            truck.queue_free()
            continue

        truck.position = trucks_position[num_trucks - 1][truck_count]
        add_fighter(truck)
        trucks_spawned.append(truck.title)
        truck_count += 1

    add_enemies()

    update_queue()

    draw_bg(true)
    draw_barren()

    sunlight_foreground.texture = sunlight_gradient

    hud.on_move_selected.connect(on_move_selected)
    hud.on_move_cancelled.connect(on_fighter_turn)
    hud.on_move_hovered.connect(on_move_hovered)
    hud.on_target_selected.connect(on_move_confirmed)
    hud.on_target_hovered.connect(on_target_hovered)

func _process(delta: float) -> void:
    if sunlight_foreground.texture.fill_from.x != sun_position:
        sunlight_foreground.texture.fill_from.x = move_toward(sunlight_foreground.texture.fill_from.x, sun_position, delta / 3)
    if is_proceeding:
        var trucks = get_trucks()
        for truck in trucks:
            truck.current_shake = 1
        bg_tile_map.position += Vector2.LEFT * delta * 150

        proceed_interval -= delta
        barren_interval -= delta

        if barren_interval <= 0:
            barren_interval = BARREN_INTERVAL
            draw_barren()
            # draw_barren_darker()
        if proceed_interval <= 0:
            add_enemies()
            proceed_interval = PROCEED_INTERVAL
            is_proceeding = false
            update_queue()
        return
    if is_ticking:
        tick_interval -= delta
        if tick_interval <= 0:
            tick_interval = TICK_INTERVAL
            tick += 1
            if tick == MAX_TICK:
                print("day over")
            on_tick()
    if is_next_turn:
        if len(turn_fighters) == 0:
            return
        current_fighter = turn_fighters[current_fighter_index]
        current_fighter_index += 1
        
        hud.update_turn_display(turn_queue, new_queue_item(current_fighter, move_index))
        is_next_turn = false
        on_fighter_turn()
    

#region Queue Management

func new_queue_item(f: Fighter, i: int):
    var queue_item = FighterQueue.new()
    queue_item.fighter = f
    queue_item.move_index = i
    return queue_item

func update_queue():
    for fighter in fighters:
        if fighter.slow_debuff_turns > 0:
            # Update queue when slowed (upcoming only)
            # Remove all queue items
            turn_queue = turn_queue.filter(func(f: FighterQueue): return f.fighter != fighter)
            # Retain next move
            turn_queue.append(new_queue_item(fighter, fighter.move_index))
        if fighter.move_index == move_index:
            fighter.update_move_index()
            turn_queue.append(new_queue_item(fighter, fighter.move_index))
        fighter.project_upcoming_move_index()
        turn_queue.append_array(fighter.upcoming_move_indices.map(func(i: int): return new_queue_item(fighter, i)))

    var unique_queue: Array[FighterQueue] = []
    for item in turn_queue:
        var any = unique_queue.any(func(i: FighterQueue): return i.fighter.get_instance_id() == item.fighter.get_instance_id() and i.move_index == item.move_index)
        if not any:
            unique_queue.append(item)
    
    turn_queue = unique_queue.filter(func(i: FighterQueue): return i.move_index >= prev_move_index)
    turn_queue.sort_custom(func(a: FighterQueue, b: FighterQueue): return a.move_index < b.move_index)

    # if from_effect:
    #     for turn in turn_queue:
    #         print(turn.fighter.title, " :: ", turn.move_index)
    hud.update_turn_display(turn_queue)


func on_tick():
    var indices = fighters.map(func(f: Fighter): return f.move_index)
    prev_move_index = move_index
    move_index = indices.min()

    print("tick: ", tick)

    turn_fighters.assign(turn_queue.filter(
        func(f: FighterQueue): return f.move_index == move_index
        ).map(func(f: FighterQueue): return f.fighter))
    update_queue()

    var trucks = get_trucks() as Array[Truck]
    for truck in trucks:
        truck.cool_down(1)

    sun_position = tick as float / MAX_TICK

    current_fighter_index = 0
    is_next_turn = true
    is_ticking = false

#endregion

#region Fighter Management

func add_enemies():
    for i in range(num_enemies):
        var enemy: Enemy = enemy_scenes.pick_random().instantiate()
        enemy.position = enemies_position[num_enemies - 1][i]
        enemy.max_hp = round(randf_range(enemy.max_hp - 2, enemy.max_hp + proceeds))
        enemy.on_move_selected.connect(on_move_selected)
        enemy.on_move_confirmed.connect(on_move_confirmed)
        add_fighter(enemy)

func add_fighter(fighter: Fighter):
    add_child.call_deferred(fighter)
    fighter.on_died.connect(remove_fighter)
    print("added ", fighter.title, " on ", move_index)
    fighters.append(fighter)

func remove_fighter(fighter: Fighter):
    fighters = fighters.filter(func(f: Fighter): return f != fighter)
    if fighter is Truck:
        var trucks = get_trucks() as Array[Truck]
        var counter = 0
        for truck in trucks:
            truck.initial_position = trucks_position[len(trucks) - 1][counter]
            counter += 1
    else:
        var enemies = get_enemies() as Array[Enemy]
        var counter = 0
        for enemy in enemies:
            enemy.initial_position = enemies_position[len(enemies) - 1][counter]
            counter += 1
    turn_queue = turn_queue.filter(func(f: FighterQueue): return f.fighter != fighter)
    turn_fighters = turn_fighters.filter(func(f: Fighter): return f != fighter)
    hud.update_turn_display(turn_queue, new_queue_item(current_fighter, move_index))

    if fighter is Enemy:
        var enemies = get_enemies()
        if len(enemies) == 0:
            proceed()
    else:
        var trucks = get_trucks()
        if len(trucks) == 0:
            turn_queue.clear()
            turn_fighters.clear()
            hud.update_turn_display([])


func on_fighter_turn():
    current_fighter.move_to_center()
    current_fighter.on_ready.connect(on_fighter_ready)

func on_fighter_ready():
    current_fighter.on_ready.disconnect(on_fighter_ready)
    if current_fighter is Truck:
        hud.fighters = fighters
        hud.show_moves(current_fighter)
    elif current_fighter is Enemy:
        await get_tree().create_timer(1.0).timeout
        current_fighter.decide()


#endregion

#region Move Management

func on_move_hovered(move_id: int):
    var move = instance_from_id(move_id) as Move
    if move.target_type == Move.TargetType.Self:
        current_fighter.highlight_duration = .1
    elif move.is_area_target:
        if move.target_type == Move.TargetType.Enemy:
            var enemies = get_enemies()
            for enemy in enemies:
                enemy.highlight_duration = .1
        elif move.target_type == Move.TargetType.Ally:
            var trucks = get_trucks()
            for truck in trucks:
                truck.highlight_duration = .1

func on_target_hovered(target_id: int):
    var target = instance_from_id(target_id) as Fighter
    target.highlight_duration = .1

func on_move_selected(move: Move):
    if move.target_type == Move.TargetType.Self:
        on_move_confirmed(move, [])
    else:
        var targets: Array[Fighter] = []

        if current_fighter is Truck:
            targets = get_trucks() if move.target_type == Move.TargetType.Ally else get_enemies()
        else:
            targets = get_enemies() if move.target_type == Move.TargetType.Ally else get_trucks()

        if move.is_area_target:
            on_move_confirmed(move, targets)
        else:
            if current_fighter is Enemy:
                current_fighter.select_target(move, targets)
            else:
                hud.show_targets(move, targets)


func on_move_confirmed(move: Move, targets: Array[Fighter]):
    var text = current_fighter.title
    if current_fighter.stun_debuff_turns > 0:
        text += " is stunned"
    else:
        text += " used " + move.title
    var floating_text = floating_text_scene.instantiate()
    var floating_text_label = floating_text.get_child(1).get_child(0) as Label
    floating_text_label.text = text
    floating_text.position = Vector2(0, -50)
    add_child(floating_text)
    current_fighter.perform_move(move, targets)
    if move.slow_debuff_turns > 0:
        update_queue()
    if current_fighter_index < len(turn_fighters):
        is_next_turn = true
    else:
        is_ticking = true
    hud.hide_moves()

func enemy_decide():
    var move = current_fighter.moves.pick_random()
    var targets: Array[Fighter] = []
    if move.move_type == Move.MoveType.Attack:
        var trucks = get_trucks()
        if move.is_area_target:
            targets = trucks
        else:
            targets = [trucks.pick_random()]
    on_move_confirmed.call_deferred(move, targets)

#endregion

#region Proceed

func proceed():
    proceeds += 1
    current_fighter = null
    turn_queue.clear()
    turn_fighters.clear()
    hud.update_turn_display([])
    is_proceeding = true
    move_index = 0
    prev_move_index = 0
    for fighter in fighters:
        fighter.move_index = 0
    draw_bg()

func draw_bg(initial = false):
    var source_id = bg_tile_set.get_source_id(0)
    var atlas_coords = [Vector2i(8, 2), Vector2i(0, 0), Vector2i(2, 2), Vector2i(2, 6), Vector2i(6, 2)]

    var max_bg_x = bg_x + 11
    if initial:
        max_bg_x = abs(BG_X_INITIAL)

    bg_tile_map.local_to_map(Vector2.ZERO)
        
    for x in range(bg_x, max_bg_x):
        for y in range(bg_y, bg_y + abs(BG_Y_INITIAL) * 2):
            var coords = Vector2i(x, y)
            bg_tile_map.set_cell(coords, source_id, atlas_coords.pick_random())
        bg_x = x
    bg_y = BG_Y_INITIAL
    

func draw_barren():
    var source_id = bg_tile_set.get_source_id(1)
    var distance = Vector2(position.x, bg_tile_map.position.y).distance_to(bg_tile_map.position)
    var target_x = bg_tile_map.local_to_map(Vector2(distance + (25 * (proceeds - 2)), 0)).x - (10 * proceeds)
    for y in range(bg_y, bg_y + abs(BG_Y_INITIAL) * 2):
        var t_x = target_x - round(abs(y) / randf_range(1.5, 4.5))
        for x in range(BG_X_INITIAL + (5 * proceeds), t_x):
            var coords = Vector2i(x, y)
            var atlas_coords = bg_tile_map.get_cell_atlas_coords(coords)
            bg_tile_map.set_cell(coords, source_id, atlas_coords)
    
# func draw_barren_darker():
#     var source_id = bg_tile_set.get_source_id(2)
#     var distance = Vector2(position.x, bg_tile_map.position.y).distance_to(bg_tile_map.position)
#     var target_x = bg_tile_map.local_to_map(Vector2(distance + (25 * (proceeds - 2)), 0)).x - (10 * proceeds)
#     target_x -= 5
#     for y in range(bg_y, bg_y + abs(BG_Y_INITIAL) * 2):
#         var t_x = target_x - round(abs(y) / randf_range(1.5, 4.5))
#         for x in range(BG_X_INITIAL + (5 * proceeds), t_x):
#             var coords = Vector2i(x, y)
#             var atlas_coords = bg_tile_map.get_cell_atlas_coords(coords)
#             bg_tile_map.set_cell(coords, source_id, atlas_coords)

#endregion

#region utils

func get_trucks():
    return fighters.filter(func(f: Fighter): return f is Truck)

func get_enemies():
    return fighters.filter(func(f: Fighter): return f is Enemy)


#endregion
