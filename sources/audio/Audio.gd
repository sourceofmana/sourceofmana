extends AudioStreamPlayer

const DefaultTrack : String					= "LaJohanne"
const FadeDuration : float					= 1.5
const FadeFloorDb : float					= -40.0

var currentTrack : int						= DB.UnknownHash
var activeStreamPlayer : AudioStreamPlayer	= self
var idleStreamPlayer : AudioStreamPlayer	= null
var fadeTween : Tween						= null
var muteUnfocused : bool					= false

#
func CreateIdleStreamPlayer() -> AudioStreamPlayer:
	var streamPlayer : AudioStreamPlayer = AudioStreamPlayer.new()
	streamPlayer.set_name("Crossfade")
	streamPlayer.set_bus(get_bus())
	add_child(streamPlayer)
	return streamPlayer

func KillFade():
	if fadeTween:
		fadeTween.kill()
		fadeTween = null

func SwapStreamPlayers():
	var previousStreamPlayer : AudioStreamPlayer = activeStreamPlayer
	activeStreamPlayer = idleStreamPlayer
	idleStreamPlayer = previousStreamPlayer

func Crossfade(soundStream : AudioStream):
	if not idleStreamPlayer:
		idleStreamPlayer = CreateIdleStreamPlayer()
	KillFade()

	var previousStreamPlayer : AudioStreamPlayer = activeStreamPlayer
	var canFade : bool = previousStreamPlayer.is_playing() and is_inside_tree()
	SwapStreamPlayers()

	activeStreamPlayer.set_volume_db(FadeFloorDb if canFade else 0.0)
	activeStreamPlayer.set_stream(soundStream)
	activeStreamPlayer.play()

	if not canFade:
		previousStreamPlayer.stop()
		return

	fadeTween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	fadeTween.tween_property(activeStreamPlayer, "volume_db", 0.0, FadeDuration).set_ease(Tween.EASE_OUT)
	fadeTween.tween_property(previousStreamPlayer, "volume_db", FadeFloorDb, FadeDuration).set_ease(Tween.EASE_IN)
	fadeTween.chain().tween_callback(previousStreamPlayer.stop)

func Stop():
	KillFade()
	for streamPlayer in [activeStreamPlayer, idleStreamPlayer]:
		if streamPlayer and streamPlayer.is_playing():
			streamPlayer.stop()
	currentTrack = DB.UnknownHash

func Load(soundID : int):
	if currentTrack == soundID:
		return

	var soundData : FileData = DB.MusicDB.get(soundID, null)
	if not soundData:
		assert(false, "Could not load music database id: %s" % soundID)
		return

	var soundStream : AudioStreamOggVorbis = soundData._resource as AudioStreamOggVorbis
	if not soundStream:
		assert(false, "Could not load music: %s" % soundData._name)
		return

	soundStream.set_loop(true)
	currentTrack = soundID
	Crossfade(soundStream)

func SetMuteUnfocused(enable : bool):
	muteUnfocused = enable
	RefreshMute()

func RefreshMute():
	var muted : bool = muteUnfocused and not DisplayServer.window_is_focused()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(ActorCommons.MasterBus), muted)

func Warped():
	if Launcher.Map and Launcher.Map.currentMapNode:
		var mapName : String = Launcher.Map.currentMapNode.get_meta("music", "")
		if not mapName.is_empty():
			Load(mapName.hash())
	elif DB.isInitialized:
		Load(DefaultTrack.hash())

func PlayDefault():
	if DB.isInitialized and currentTrack == DB.UnknownHash:
		Load(DefaultTrack.hash())

#
func _ready():
	var window : Window = get_window()
	if window:
		window.focus_entered.connect(RefreshMute)
		window.focus_exited.connect(RefreshMute)

func _post_launch():
	if not Launcher.dbInitialized.is_connected(PlayDefault):
		Launcher.dbInitialized.connect(PlayDefault)
	if Launcher.Map and not Launcher.Map.PlayerWarped.is_connected(Warped):
		Launcher.Map.PlayerWarped.connect(Warped)
		Warped()
