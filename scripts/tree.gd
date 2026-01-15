extends Node2D
class_name TreeClass # Parse Error: Class "Tree" hides a native class.

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow
@export var smoke_scene: PackedScene

var has_fallen = false
enum LeafState {
    YELLOW, GREEN_YELLOW, GREEN
}

func _ready() -> void:
    sprite_2d.frame_coords.x = randi_range(0, sprite_2d.hframes - 1)
    sprite_2d.frame_coords.y = LeafState.GREEN
    shadow.frame_coords.x = randi_range(0, sprite_2d.hframes - 1)
    shadow.frame_coords.y = LeafState.GREEN


func fall():
    if has_fallen:
        return
    animation_player.play("fall")
    has_fallen = true

func update_leaf_state(state: LeafState):
    sprite_2d.frame_coords.y = state


func _on_animation_player_animation_finished(_anim) -> void:
    var smoke: Node2D = smoke_scene.instantiate()
    smoke.scale = Vector2(-1, 1)
    smoke.position = Vector2(80, -20)
    smoke.modulate.a = .5
    add_child(smoke)
