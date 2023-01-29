extends Node

class_name EntityData

@export var _id : int
@export var _name : String 
@export var _ethnicity : String
@export var _gender : String
@export var _hairstyle : String
@export var _animation : String
@export var _animationTree : String 
@export var _navigationAgent : String
@export var _collision : String
@export var _customTexture : String
@export var _walkSpeed : int
@export var _displayName : bool

func _init():
	_id = -1
	_name = ""
	_ethnicity = ""
	_gender = ""
	_hairstyle = ""
	_animation = ""
	_animationTree = ""
	_navigationAgent = ""
	_collision = ""
	_customTexture = ""
	_walkSpeed = 125
	_displayName = false
