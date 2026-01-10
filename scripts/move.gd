extends Resource
class_name Move

enum MoveType {
    Attack, Effect
}
enum TargetType {
    SingleEnemy, MultipleEnemy, SingleAlly, MultipleAlly
}

@export var title: String
@export var description: String

@export var move_type: MoveType
@export var target_type: TargetType

@export var damage: int
@export var self_damage: int

@export var heat_cost: int