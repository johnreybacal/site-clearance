extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
    var anim = (sprite.sprite_frames.get_animation_names() as Array[String]).pick_random()
    sprite.play(anim)
    sprite.animation_finished.connect(queue_free)
