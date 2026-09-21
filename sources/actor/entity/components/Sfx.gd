extends Node2D
class_name EntitySfx

#
@onready var entity : Entity						= get_parent()

#
static var othersVolumeDb : float					= 0.0

var alterationPlayer : AudioStreamPlayer2D			= null
var notificationPlayer : AudioStreamPlayer2D		= null
var statePlayer : AudioStreamPlayer2D				= null

var currentAlteration : ActorCommons.Alteration		= ActorCommons.Alteration.UNKNOWN
var currentState : ActorCommons.State				= ActorCommons.State.UNKNOWN

#
func CreatePlayer(bus : StringName, onFinished : Callable) -> AudioStreamPlayer2D:
	var player : AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	player.max_distance = ActorCommons.SfxMaxDistance
	player.bus = bus
	player.finished.connect(onFinished)
	add_child(player)
	return player

func GetVolumeDb(involved : bool) -> float:
	return 0.0 if involved else othersVolumeDb

func IsLocallyInvolved() -> bool:
	return entity == Launcher.Player or entity == Entities.target

# Alteration player
func PlayAlteration(audioStream : AudioStream, involved : bool):
	if not audioStream or not entity or not entity.data:
		return

	if not alterationPlayer:
		alterationPlayer = CreatePlayer(ActorCommons.SfxAlterationBus, StopAlteration)

	alterationPlayer.set_volume_db(GetVolumeDb(involved))
	alterationPlayer.set_stream(audioStream)
	alterationPlayer.play()

func StopAlteration():
	if currentAlteration != ActorCommons.Alteration.UNKNOWN:
		currentAlteration = ActorCommons.Alteration.UNKNOWN
		if alterationPlayer:
			alterationPlayer.stop()
			alterationPlayer.set_stream(null)

# Notification player
func PlayNotification(audioStream : AudioStream):
	if not audioStream or not entity or not entity.data:
		return

	if not notificationPlayer:
		notificationPlayer = CreatePlayer(ActorCommons.SfxNotificationBus, StopNotification)

	notificationPlayer.set_stream(audioStream)
	notificationPlayer.play()

func StopNotification():
	if notificationPlayer:
		notificationPlayer.stop()
		notificationPlayer.set_stream(null)

func HandleAlteration(alteration : ActorCommons.Alteration, involved : bool = true):
	if not entity or not entity.data:
		return

	var audioStream : AudioStream = entity.data._alterationSFX[alteration] if entity.data._alterationSFX.has(alteration) else ActorCommons.DefaultSfx.get(alteration)
	if ActorCommons.IsNotificationAlteration(alteration) and entity == Launcher.Player:
		PlayNotification(audioStream)
	else:
		currentAlteration = alteration
		PlayAlteration(audioStream, involved)

# State player
func PlayState(audioStream : AudioStream):
	if not audioStream or not entity or not entity.data:
		return

	if not statePlayer:
		statePlayer = CreatePlayer(ActorCommons.SfxStateBus, StopState)

	statePlayer.set_volume_db(GetVolumeDb(IsLocallyInvolved()))
	statePlayer.set_stream(audioStream)
	statePlayer.play()

func StopState():
	if currentState != ActorCommons.State.UNKNOWN:
		currentState = ActorCommons.State.UNKNOWN
		if statePlayer:
			statePlayer.stop()
			statePlayer.set_stream(null)

func HandleState(state : ActorCommons.State):
	if currentState != state:
		currentState = state
		if entity.data and entity.data._stateSFX.has(state):
			PlayState(entity.data._stateSFX[state])
		else:
			StopState()
