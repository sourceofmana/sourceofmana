extends Resource
class_name StatModifier

#
@export var _effect : CellCommons.Modifier	= CellCommons.Modifier.None
@export var _value : Variant				= 0.0
@export var _persistent : bool				= false

#
func Parse(data : Array):
	var arraySize : int = data.size()

	assert(arraySize == 3, "Could not parse stat modifier from array, size mismatches")
	if arraySize == 3:
		assert(data[0] is CellCommons.Modifier, "Stat modifier first parameter is not a StringName, could not parse from array")
		assert(data[2] is bool, "Stat modifier third parameter is not a bool, could not parse from array")
		if data[0] is not CellCommons.Modifier or data[2] is not bool:
			return

		_effect = data[0]
		_value = data[1]
		_persistent = data[2]
