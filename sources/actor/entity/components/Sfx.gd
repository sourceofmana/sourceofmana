extends Node2D
class_name EntitySfx

#
@onready var entity : Entity						= get_parent()

#
var alterationPlayer : AudioStreamPlayer2D			= null
var statePlayer : AudioStreamPlayer2D				= null

var currentAlteration : ActorCommons.Alteration		= ActorCommons.Alteration.UNKNOWN
var currentState : ActorCommons.State				= ActorCommons.State.UNKNOWN


# Alteration player
func PlayAlteration(audioStream : AudioStream):
	if not audioStream or not entity or not entity.data:
		return

	if not alterationPlayer:
		alterationPlayer = AudioStreamPlayer2D.new()
		alterationPlayer.max_distance = ActorCommons.SfxMaxDistance
		alterationPlayer.bus = ActorCommons.SfxAlterationBus
		alterationPlayer.finished.connect(StopAlteration)
		add_child(alterationPlayer)

	alterationPlayer.set_stream(audioStream)
	alterationPlayer.play()

func StopAlteration():
	if currentAlteration != ActorCommons.Alteration.UNKNOWN:
		currentAlteration = ActorCommons.Alteration.UNKNOWN
		if alterationPlayer:
			alterationPlayer.stop()
			alterationPlayer.set_stream(null)

func HandleAlteration(alteration : ActorCommons.Alteration):
	currentAlteration = alteration
	PlayAlteration(ActorCommons.DefaultSfx.get(alteration))

# State player
func PlayState(audioStream : AudioStream):
	if not audioStream or not entity or not entity.data:
		return

	if not statePlayer:
		statePlayer = AudioStreamPlayer2D.new()
		statePlayer.max_distance = ActorCommons.SfxMaxDistance
		statePlayer.bus = ActorCommons.SfxStateBus
		statePlayer.finished.connect(StopState)
		add_child(statePlayer)

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
		if entity.data and entity.data._sfx.has(state):
			PlayState(entity.data._sfx.get(state))
		else:
			StopState()
