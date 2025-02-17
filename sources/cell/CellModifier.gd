extends Resource
class_name CellModifier

#
@export var _modifiers : Array[StatModifier]			= []

#
func Get(effect : CellCommons.Modifier, persistent : bool = false, default : Variant = 0) -> Variant:
	for modifier in _modifiers:
		if modifier._effect == effect:
			return modifier._value if modifier and modifier._persistent == persistent else default
	return default

#
func Add(modifier : StatModifier):
	_modifiers.append(modifier)

func Remove(modifier : StatModifier):
	_modifiers.erase(modifier)

#
func Apply(actor : Actor):
	if not actor:
		assert(false, "Actor not found, could not apply the cell modifier")

	for modifier in _modifiers:
		if modifier:
			match modifier._effect:
				CellCommons.Modifier.Health:
					var hp : int = Get(modifier._effect);
					if hp != 0: actor.stat.SetHealth(hp)
				CellCommons.Modifier.Mana:
					var mana : int = Get(modifier._effect);
					if mana != 0: actor.stat.SetMana(mana)
				CellCommons.Modifier.Stamina:
					var stamina : int = Get(modifier._effect);
					if stamina != 0: actor.stat.SetStamina(stamina)

func Equip(actor : Actor):
	for modifier in _modifiers:
		if modifier and modifier._persistent:
			actor.stat.modifiers.Add(modifier)

func Unequip(actor : Actor):
	for modifier in _modifiers:
		if modifier and modifier._persistent:
			actor.stat.modifiers.Remove(modifier)
