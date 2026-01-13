extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
    print(position)
    var anim = (sprite.sprite_frames.get_animation_names() as Array[String]).pick_random()
    print("smoke ", anim)
    sprite.play(anim)
    sprite.animation_finished.connect(queue_free)
