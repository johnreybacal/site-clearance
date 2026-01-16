extends Node2D
class_name TreeClass # Parse Error: Class "Tree" hides a native class.

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
@export var smoke_scene: PackedScene

var has_fallen = false
enum LeafState {
    YELLOW, GREEN_YELLOW, GREEN
}

func _ready() -> void:
    sprite_2d.frame_coords.x = randi_range(0, sprite_2d.hframes - 1)
    sprite_2d.frame_coords.y = LeafState.GREEN
    sprite_2d.flip_h = randi_range(0, 1) == 1
    shadow.frame_coords.x = sprite_2d.frame_coords.x
    shadow.frame_coords.y = LeafState.GREEN
    audio.pitch_scale = randf_range(0.8, 1.2)


func fall():
    if has_fallen:
        return
    await get_tree().create_timer(randf()).timeout
    animation_player.play("fall")
    has_fallen = true
    Global.increment_trees_fallen()

func update_leaf_state(state: LeafState):
    sprite_2d.frame_coords.y = state


func _on_animation_player_animation_finished(_anim) -> void:
    var smoke: Node2D = smoke_scene.instantiate()
    smoke.scale = Vector2(-1, 1)
    smoke.position = Vector2(80, -20)
    smoke.modulate.a = .5
    add_child(smoke)
