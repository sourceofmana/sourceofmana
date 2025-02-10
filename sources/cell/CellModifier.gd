extends Resource
class_name CellModifier

#
@export var _effects : Dictionary				= {}
@export var _keep : bool						= false

#
func GetHP() -> int: return _effects.get(CellCommons.effectHP, 0)
func GetMana() -> int: return _effects.get(CellCommons.effectMana, 0)
func GetStamina() -> int: return _effects.get(CellCommons.effectStamina, 0)
func GetDamage() -> int: return _effects.get(CellCommons.effectDamage, 0)

func Apply(actor : Actor):
	if not actor:
		assert(false, "Actor not found, could not apply the cell modifier")

	if _keep:
		pass
	else:
		var hp : int = GetHP();
		if hp != 0: actor.stat.SetHealth(hp)
		var mana : int = GetMana();
		if mana != 0: actor.stat.SetMana(mana)
		var stamina : int = GetStamina();
		if stamina != 0: actor.stat.SetStamina(stamina)

#
func _init(effects : Dictionary = {}, keep = false):
	_effects = effects
	_keep = keep
