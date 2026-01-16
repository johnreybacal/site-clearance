extends Node2D
class_name AchievementNotification

@onready var title: Label = $Sprite2D/Title
@onready var description: Label = $Sprite2D/Description
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var title_text: String
var description_text: String
var is_exiting = false

func _ready() -> void:
    title.text = title_text
    description.text = description_text
    global_position = Vector2(400, -200)

func _on_timer_timeout() -> void:
    animation_player.play("exit")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
    if anim_name == "exit":
        queue_free()
