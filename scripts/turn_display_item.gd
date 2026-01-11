extends TextureRect
class_name TurnDisplayItem

var move_index: int
var fighter_id: int

func _ready() -> void:
    expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    var label = Label.new()
    label.text = str(move_index)
    add_child(label)