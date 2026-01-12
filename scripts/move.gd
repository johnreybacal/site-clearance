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
@export var damage: float
@export var self_damage: float

@export_category("Truck only")
@export var heat_cost: float

@export_category("Debuff (turns)")
@export var slow_debuff_turns: int # turns (speed * .75)
@export var stun_debuff_turns: int # turns (skip turn)

@export_category("Buff (instant)")
@export var heal_amount: float # amount
@export var cool_down_amount: float # amount

@export_category("Buff (turns)")
@export var damage_buff_turns: int # turns (damage * 1.25)
@export var defense_buff_turns: int # turns (damage received * .75)
