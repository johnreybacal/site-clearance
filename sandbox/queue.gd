extends Node2D

@onready var tick_bar: TextureProgressBar = $TextureProgressBar
@onready var timer: Timer = $Timer
var is_ticking = true

class Char:
    var name: String
    var speed: float
    var last_turn: int = 0
    var slowed: bool

class CharTurn:
    var ch: Char
    var turn: int

var chars: Array[Char]
var char_turns: Array[CharTurn] = []
var turns: Array[int] = []
const MAX_SPEED = 100

var labels: Array[Label] = []

func _ready() -> void:
    # tick_bar.min_value = -50
    # tick_bar.max_value = 50
    timer.timeout.connect(start_tick)
    var a = Char.new()
    a.name = "A"
    a.speed = 10

    var b = Char.new()
    b.name = "B"
    b.speed = 20

    var c = Char.new()
    c.name = "C"
    c.speed = 80

    chars = [a, b, c]

    update_queue()


func _process(delta: float) -> void:
    if is_ticking:
        var d = delta * 50
        # tick_bar.min_value += d
        # tick_bar.max_value += d
        tick_bar.value += d
        var tick = int(round(tick_bar.value))

        if tick in turns:
            var current = char_turns.filter(func(c: CharTurn): return c.turn == tick)
            for ch in current:
                var slowed = randi_range(0, 1) == 1
                ch.ch.slowed = slowed
                if slowed:
                    apply_speed_penalty(ch.ch)
            is_ticking = false
            timer.start()

        if tick == tick_bar.max_value:
            is_ticking = false
            tick_bar.value = 0
            update_queue()

    
func start_tick():
    is_ticking = true

func get_char_turns(ch: Char):
    var c_turns: Array[CharTurn] = []
    var turn = 0
    if ch.last_turn != 0:
        turn = (MAX_SPEED - ch.last_turn) * -1

    while true:
        turn += MAX_SPEED - (ch.speed * .5 if ch.slowed else ch.speed)
        if turn <= 100:
            var char_turn = CharTurn.new()
            char_turn.ch = ch
            char_turn.turn = turn
            c_turns.append(char_turn)
            ch.last_turn = turn
        else:
            break
    return c_turns

func apply_speed_penalty(ch: Char):
    char_turns = char_turns.filter(func(c: CharTurn):
        return c.ch != ch or ( # not the char
            c.ch == ch and c.turn > tick_bar.value # the char but is future turn
        ))
    var new_char_turns = get_char_turns(ch)
    new_char_turns = new_char_turns.filter(func(c: CharTurn): return c.turn > tick_bar.value)
    char_turns.append_array(new_char_turns)

    draw_queue()

func update_queue():
    char_turns.clear()
    turns.clear()

    for ch in chars:
        char_turns.append_array(get_char_turns(ch))

    draw_queue()
    print(turns)
    start_tick()
    
func draw_queue():
    for label in labels:
        label.queue_free()
    labels.clear()
    char_turns.sort_custom(func(x: CharTurn, y: CharTurn): return x.turn < y.turn)

    for ch in char_turns:
        print(ch.ch.name, " :: ", ch.turn, " :: ", ch.ch.last_turn)
        var label = Label.new()
        label.text = ch.ch.name
        label.position = tick_bar.position + Vector2(tick_bar.size.x * (ch.turn / tick_bar.max_value), 0)
        labels.append(label)
        turns.append(ch.turn)
        add_child(label)