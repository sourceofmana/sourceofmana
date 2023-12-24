extends Node
class_name SkillData

@export var _id : int
@export var _name : String
@export var _iconPath : String
@export var _castPresetPath : String
@export var _castTextureOverride : String
@export var _castColor : Color
@export var _castTime : float
@export var _staminaCost : int
@export var _manaCost : int

func _init():
	_id = 0
	_name = "Unknown"
	_iconPath = "res://data/graphics/default.png"
	_castPresetPath = ""
	_castTextureOverride = "res://data/graphics/default.png"
	_castColor = Color.PINK
	_castTime = 1.0
	_staminaCost = 0
	_manaCost = 0
