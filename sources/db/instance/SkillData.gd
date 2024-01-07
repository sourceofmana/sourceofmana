extends Node
class_name SkillData

@export var _id : int
@export var _name : String
@export var _iconPath : String
@export var _castPresetPath : String
@export var _castTextureOverride : String
@export var _castColor : Color
@export var _castTime : float
@export var _cooldownTime : float

# Stats, must have the same name than their relatives in EntityStats
@export var stamina : int
@export var mana : int

func _init():
	_id = 0
	_name = "Unknown"
	_iconPath = "res://data/graphics/default.png"
	_castPresetPath = ""
	_castTextureOverride = ""
	_castColor = Color.PINK
	_castTime = 0.0
	_cooldownTime = 0.0
	stamina = 0
	mana = 0
