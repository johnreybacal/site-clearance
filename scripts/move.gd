extends Resource
class_name Move

enum MoveType {
    Attack, Effect
}
enum TargetType {
    Enemy, Ally, Self
}

@export var title: String
@export var description: String

@export var move_type: MoveType
@export var target_type: TargetType
@export var is_area_target: bool

@export var damage: int
@export var self_damage: int

@export var heat_reduction: int
@export var heat_cost: int