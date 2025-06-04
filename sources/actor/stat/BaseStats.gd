extends Node
class_name BaseStats

# Base Stats
@export var weightCapacity : float				= 10.0
@export var walkSpeed : float					= 100.0

@export var attack : int						= 10
@export var defense : int						= 5
@export var mattack : int						= 10
@export var mdefense : int						= 5
@export var attackRange : int					= 32
@export var critRate : float					= 0.01
@export var dodgeRate : float					= 0.01
@export var castAttackDelay : float				= 0.7
@export var cooldownAttackDelay : float			= 0.5

@export var maxHealth : int						= 100
@export var maxStamina : int					= 50
@export var maxMana : int						= 50

@export var regenHealth : int					= 1
@export var regenStamina : int					= 1
@export var regenMana : int						= 1
