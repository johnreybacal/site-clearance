extends Node2D
class_name GameManager

class FighterQueue:
    var fighter: Fighter
    var move_index: int

@export var hud: HUD
@export var truck_scenes: Array[PackedScene]
@export var enemy_scenes: Array[PackedScene]
@export var bg_container: Node2D
@export var bg_tile_map: TileMapLayer
@export var bg_tile_set: TileSet
@export var sunlight_foreground: Sprite2D
@export var sunlight_gradient: GradientTexture2D
@export var end_transition_foreground: Sprite2D
@export var tree_scene: PackedScene
@export var floating_text_scene: PackedScene

var MAX_TICK = 50
var tick = 0
var is_ticking = true
const TICK_INTERVAL = 1.25
var tick_interval = 2.25

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
var sun_position = 0
var is_ending = false
var trees: Array[TreeClass] = []

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
    var num_trucks = len(Global.operators)
    while truck_count < num_trucks:
        var truck: Truck = truck_scenes.pick_random().instantiate()
        
        if truck.title in trucks_spawned or truck.title in Global.last_trucks_used:
            truck.queue_free()
            continue
        truck.position = trucks_position[num_trucks - 1][truck_count]
        truck.operator = Global.operators[truck_count]
        truck.init_stats()
        add_fighter(truck)
        Global.last_trucks_used.append(truck.title)
        trucks_spawned.append(truck.title)
        truck_count += 1

    # if greater than 5 (or 6)
    if len(Global.last_trucks_used) > 5:
        # remove the first three from the queue
        # so that the last three won't be reused next game
        Global.last_trucks_used.pop_front()
        Global.last_trucks_used.pop_front()
        Global.last_trucks_used.pop_front()

    add_enemies()

    update_queue()
    hud.update_turn_display(turn_queue)

    draw_bg(true)
    draw_barren()
    draw_trees()

    sunlight_foreground.texture = sunlight_gradient

    hud.on_move_selected.connect(on_move_selected)
    hud.on_move_cancelled.connect(on_fighter_turn)
    hud.on_move_hovered.connect(on_move_hovered)
    hud.on_target_selected.connect(on_move_confirmed)
    hud.on_target_hovered.connect(on_target_hovered)

func _process(delta: float) -> void:
    if len(text_queue) > 0:
        text_interval -= delta
        if text_interval <= 0:
            var item = text_queue.pop_back()
            display_text(item.text, item.color)
            text_interval = TEXT_INTERVAL if len(text_queue) > 0 else 0.0
    if is_ending:
        end_transition_foreground.modulate.a = move_toward(end_transition_foreground.modulate.a, 1, delta / 3)
        if end_transition_foreground.modulate.a == 1:
            get_tree().change_scene_to_file(Global.MENU_SCENE)
        return
    if sunlight_foreground.texture.fill_from.x != sun_position:
        sunlight_foreground.texture.fill_from.x = move_toward(sunlight_foreground.texture.fill_from.x, sun_position, delta / 3)
    if is_proceeding:
        var trucks = get_trucks()
        for truck in trucks:
            truck.current_shake = 1
        bg_container.position += Vector2.LEFT * delta * 150

        proceed_interval -= delta
        barren_interval -= delta

        if barren_interval <= 0:
            barren_interval = BARREN_INTERVAL
            draw_barren()
            redraw_trees()
            # draw_barren_darker()
        if proceed_interval <= 0:
            current_fighter = null
            turn_queue.clear()
            turn_fighters.clear()
            add_enemies()
            proceed_interval = PROCEED_INTERVAL
            is_proceeding = false
            is_ticking = true
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
    # turn_queue.clear()
    for fighter in fighters:
        if fighter.is_leaving:
            continue
        if fighter.move_index == move_index:
            # Update move index
            fighter.update_move_index()
        turn_queue.append(new_queue_item(fighter, fighter.move_index))
        # Update projected move index
        fighter.project_upcoming_move_index()
        turn_queue.append_array(fighter.upcoming_move_indices.map(func(i: int): return new_queue_item(fighter, i)))

    var unique_queue: Array[FighterQueue] = []
    for item in turn_queue:
        var any = unique_queue.any(func(i: FighterQueue): return i.fighter == item.fighter and i.move_index == item.move_index)
        if not any:
            unique_queue.append(item)
    
    turn_queue = unique_queue.filter(func(i: FighterQueue): return i.move_index >= prev_move_index)
    turn_queue.sort_custom(func(a: FighterQueue, b: FighterQueue): return a.move_index < b.move_index)

    # print(";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;")
    # for turn in turn_queue:
    #     print(turn.fighter.title, " :: ", turn.move_index)


func on_tick():
    var indices = fighters.filter(is_active_fighter).map(func(f: Fighter): return f.move_index)
    prev_move_index = move_index
    move_index = indices.min()

    print("tick: ", tick)

    turn_fighters.assign(turn_queue.filter(
        func(f: FighterQueue): return f.move_index == move_index and is_active_fighter(f.fighter)
        ).map(func(f: FighterQueue): return f.fighter))
    update_queue()

    var trucks = get_trucks() as Array[Truck]
    for truck in trucks:
        if truck.heat_level > 0:
            truck.cool_down(1)

    sun_position = tick as float / MAX_TICK

    current_fighter_index = 0
    current_fighter = turn_fighters[current_fighter_index]
    is_next_turn = true
    is_ticking = false

    if len(turn_queue) > 0:
        hud.update_turn_display(turn_queue, new_queue_item(current_fighter, move_index))

#endregion

#region Fighter Management

func add_enemies():
    var num_enemies: int = 1
    if Global.enemies_defeated > 5:
        num_enemies = clampi(randi_range(Global.max_enemies - 2, Global.max_enemies), 1, Global.max_enemies)
    for i in range(num_enemies):
        var enemy: Enemy = enemy_scenes.pick_random().instantiate()
        enemy.init_stats()
        enemy.position = enemies_position[num_enemies - 1][i]
        enemy.max_hp = round(randf_range(enemy.max_hp - 2, enemy.max_hp + proceeds))
        enemy.on_move_selected.connect(on_move_selected)
        enemy.on_move_confirmed.connect(on_move_confirmed)
        add_fighter(enemy)

func add_fighter(fighter: Fighter):
    add_child.call_deferred(fighter)
    fighter.on_died.connect(remove_fighter)
    fighters.append(fighter)

func remove_fighter(fighter: Fighter):
    turn_queue = turn_queue.filter(func(f: FighterQueue): return f.fighter != fighter)
    turn_fighters = turn_fighters.filter(func(f: Fighter): return f != fighter)
    hud.update_turn_display(turn_queue, new_queue_item(current_fighter, move_index))
    fighters = fighters.filter(func(f: Fighter): return f != fighter)
    if fighter is Truck:
        Global.increment_trucks_lost()
        var trucks = get_trucks() as Array[Truck]
        var counter = 0
        for truck in trucks:
            truck.initial_position = trucks_position[len(trucks) - 1][counter]
            counter += 1
    else:
        # Gradual money increase with difficulty
        var money = fighter.max_hp + Global.enemy_stat_modifier.speed + Global.enemy_stat_modifier.damage
        Global.earn_money(money)
        queue_text("+ $" + str(round(money)), Color.GREEN)
        Global.increment_enemies_defeated()
        var enemies = get_enemies() as Array[Enemy]
        var counter = 0
        for enemy in enemies:
            enemy.initial_position = enemies_position[len(enemies) - 1][counter]
            counter += 1

    if fighter is Enemy:
        var enemies = get_enemies()
        draw_barren()
        if len(enemies) == 0:
            hud.update_turn_display([])
            proceed()
    else:
        var trucks = get_trucks()
        if len(trucks) == 0:
            var money = current_fighter.max_hp / 2
            Global.earn_money(money)
            queue_text("+ $" + str(round(money)), Color.GREEN)
            turn_queue.clear()
            turn_fighters.clear()
            hud.update_turn_display([])
            is_ending = true


func on_fighter_turn():
    current_fighter.move_to_center()
    current_fighter.on_ready.connect(on_fighter_ready)

func on_fighter_ready(fighter: Fighter):
    fighter.on_ready.disconnect(on_fighter_ready)
    if fighter is Truck:
        if fighter.stun_debuff_turns > 0:
            await get_tree().create_timer(1.0).timeout
            on_move_confirmed(fighter.moves[0], [fighter])
        else:
            hud.fighters = fighters
            hud.show_moves(fighter)
    elif fighter is Enemy:
        await get_tree().create_timer(1.0).timeout
        fighter.decide()


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
    hud.hide_moves()
    var text = current_fighter.title
    if current_fighter.stun_debuff_turns > 0:
        text += " is stunned"
    else:
        text += " used " + move.title
    queue_text(text)
    current_fighter.perform_move(move, targets)
    if move.slow_debuff_turns > 0:
        for fighter in targets:
            if fighter.is_leaving:
                continue
            if fighter.slow_debuff_turns > 0:
                # Remove all queue items
                turn_queue = turn_queue.filter(func(f: FighterQueue): return f.fighter != fighter)
                if fighter.is_recently_slowed:
                    # Apply speed penalty on current move_index
                    # if fighter's move index is in the future
                    # OR they move this turn but have'nt yet
                    if fighter.move_index > move_index or (fighter in turn_fighters and turn_fighters.find(fighter) > current_fighter_index):
                        fighter.move_index += int(fighter.get_speed_penalty())
                    fighter.is_recently_slowed = false
                turn_queue.append(new_queue_item(fighter, fighter.move_index))
                # invoke to reorder queue
                update_queue()
    
    if current_fighter_index < len(turn_fighters):
        is_next_turn = true
    else:
        is_ticking = true

#endregion

#region Proceed

func proceed():
    proceeds += 1
    is_proceeding = true
    turn_queue.clear()
    turn_fighters.clear()
    hud.update_turn_display([])
    move_index = 0
    prev_move_index = 0
    for fighter in fighters:
        fighter.move_index = 0
    draw_bg()
    draw_trees(400, 700)

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
    var atlas_coords = [Vector2i(7, 11), Vector2i(5, 8), Vector2i(3, 8), Vector2i(5, 7)]
    var distance = Vector2(position.x, bg_container.position.y).distance_to(bg_container.position)
    var target_x = bg_tile_map.local_to_map(Vector2(distance + (25 * (proceeds - 2)), 0)).x - (10 * proceeds)
    for y in range(bg_y, bg_y + abs(BG_Y_INITIAL) * 2):
        var t_x = target_x - round(abs(y) / randf_range(1.5, 4.5))
        for x in range(BG_X_INITIAL + (5 * proceeds), t_x):
            var coords = Vector2i(x, y)
            
            bg_tile_map.set_cell(coords, source_id, atlas_coords.pick_random())


func draw_trees(x = -425, to_x = 425):
    var index = 0
    while x < to_x:
        x += randi_range(-25, 100)
        var y = randi_range(-135, -200) if index % 2 == 0 else randi_range(150, 250)
        var tree: TreeClass = tree_scene.instantiate()
        # Trees container
        bg_container.get_child(0 if y < 0 else 1).add_child(tree)
        tree.global_position = Vector2(int(x), int(y))
        tree.z_index = int(tree.position.y - 10)
        trees.append(tree)
        index += 1

    redraw_trees.call_deferred()

func redraw_trees():
    var indices_to_remove: Array[int] = []
    var index = -1
    for tree in trees:
        index += 1
        if tree.global_position.x < -500:
            indices_to_remove.append(index)
        if tree.global_position.x > 175:
            tree.update_leaf_state(TreeClass.LeafState.GREEN)
        elif tree.global_position.x > -50:
            tree.update_leaf_state(TreeClass.LeafState.GREEN_YELLOW)
        elif tree.global_position.x > -200:
            tree.update_leaf_state(TreeClass.LeafState.YELLOW)
        else:
            tree.update_leaf_state(TreeClass.LeafState.YELLOW)
            tree.fall()

    for i in range(len(indices_to_remove) - 1, 0, -1):
        trees[i].queue_free()
        trees.remove_at(i)
        

#endregion

#region utils

func get_trucks():
    return fighters.filter(func(f: Fighter): return f is Truck)

func get_enemies():
    return fighters.filter(func(f: Fighter): return f is Enemy)

func is_active_fighter(f: Fighter):
    return not f.is_leaving

#endregion


#region Floating Text

class TextQueue:
    var text: String
    var color: Color

var text_queue: Array[TextQueue] = []
const TEXT_INTERVAL = 0.5
var text_interval = 0

func queue_text(value: String, color: Color = "#FFFFFF"):
    var item = TextQueue.new()
    item.text = value
    item.color = color
    text_queue.push_front(item)

func display_text(value: String, color: Color = "#FFFFFF"):
    var floating_text: FloatingText = floating_text_scene.instantiate()
    floating_text.position = Vector2(0, -50)
    floating_text.color = color
    floating_text.font_size = 20
    floating_text.text = value

    add_child(floating_text)

#endregion
