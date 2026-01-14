extends TextureRect
class_name TurnDisplayItem

var move_index: int
var fighter_id: int

func _ready() -> void:
    expand_mode = TextureRect.EXPAND_FIT_WIDTH
    stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST