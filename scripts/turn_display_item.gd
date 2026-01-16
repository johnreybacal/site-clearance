extends Sprite2D
class_name TurnDisplayItem

var move_index: int
var fighter_id: int
var transition_speed = 1
var target_position_y
func _ready() -> void:
    target_position_y = position.y
    position.y -= 50

func _process(delta: float) -> void:
    if position.y != target_position_y:
        position.y = move_toward(position.y, target_position_y, (delta * transition_speed))