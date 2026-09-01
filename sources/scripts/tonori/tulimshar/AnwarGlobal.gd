extends NpcScript

# Constants
const DAILY_COOLDOWN_SECS : float			= 24.0 * 60 * 60

# Cooldowns saved across every player delivery
var dailyCooldowns : Dictionary[int, float]	= {}

# Player-script accessors
func CanTurnInDaily(playerRID : int) -> bool:
	var expiry : float = dailyCooldowns.get(playerRID, 0.0)
	return Time.get_unix_time_from_system() > expiry

func StartCooldown(playerRID : int):
	dailyCooldowns[playerRID] = Time.get_unix_time_from_system() + DAILY_COOLDOWN_SECS
