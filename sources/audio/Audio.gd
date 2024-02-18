extends ServiceBase

var audioPlayer : AudioStreamPlayer				= null
var currentTrack : String = ""

#
func Play(pause : bool = false):
	if pause:
		audioPlayer.pause()
	else:
		audioPlayer.play()

func Stop():
	if audioPlayer.is_playing():
		audioPlayer.stop()
	currentTrack = ""

func Load(soundName : String):
	Util.Assert(audioPlayer != null, "AudioStreamPlayer could not be found")
	if audioPlayer && currentTrack != soundName && not soundName.is_empty() && DB.MusicsDB[soundName] != null:
		var soundStream : Resource = FileSystem.LoadMusic(DB.MusicsDB[soundName]._path as String)
		Util.Assert(soundStream != null, "Could not load music: " + soundName)
		if soundStream != null:
			soundStream.set_loop(true)

			audioPlayer.stream	= soundStream
			currentTrack		= soundName

			audioPlayer.set_autoplay(true)
			audioPlayer.play()

func SetVolume(volume : float):
	Util.Assert(audioPlayer != null, "AudioStreamPlayer could not be found")
	if audioPlayer:
		audioPlayer.set_volume_db(volume)

func Warped():
	if Launcher.Map.mapNode && Launcher.Map.mapNode.has_meta("music"):
		Load(Launcher.Map.mapNode.get_meta("music") as String)
	else:
		Stop()

#
func _post_launch():
	audioPlayer = Launcher.Scene.get_node("AudioStreamPlayer")
	Util.Assert(audioPlayer != null, "Could not find the AudioStreamPlayer instance")

	if Launcher.Map:
		Launcher.Map.PlayerWarped.connect(self.Warped)
		Warped()

	isInitialized = true
