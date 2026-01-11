extends Resource
class_name Move

enum MoveType {
    Attack, Effect
}
enum TargetType {
    Enemy, Ally, Self
}

@export_category("Metadata")
@export var title: String
@export var description: String

@export var move_type: MoveType
@export var target_type: TargetType
@export var is_area_target: bool

@export_category("Damage")
@export var damage: int
@export var self_damage: int

@export_category("Truck only")
@export var heat_reduction: int
@export var heat_cost: int

@export_category("Debuff")
@export var slow_turn: int # turns (speed * .75)
@export var stun_turn: int # turns (skip turn)
@export var weaken_turn: int # turns (damage * .75)

@export_category("Buff")
@export var heal_amount: int # amount
@export var strengten_turn: int # turns (damage * 1.25)
@export var toughen_turn: int # turns (damage received * .75)
@export var cool_down_amount: int # amount
