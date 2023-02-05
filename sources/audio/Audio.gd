extends Node

var audioPlayer : AudioStreamPlayer				= null
var currentTrack : String = ""

#
func Play(pause : bool = false):
	if pause:
		audioPlayer.pause()
	else:
		audioPlayer.play()
	pass

func Stop():
	if audioPlayer.is_playing():
		audioPlayer.Stop()

func Load(soundName : String):
	assert(audioPlayer, "AudioStreamPlayer could not be found")
	if audioPlayer && currentTrack != soundName && not soundName.is_empty() && Launcher.DB.MusicsDB[soundName] != null:
		var soundStream : Resource = Launcher.FileSystem.LoadMusic(Launcher.DB.MusicsDB[soundName]._path)
		Launcher.Util.Assert(soundStream != null, "Could not load music: " + soundName)
		if soundStream != null:
			soundStream.set_loop(true)

			audioPlayer.stream	= soundStream
			currentTrack		= soundName

			audioPlayer.set_autoplay(true)
			audioPlayer.play()

func Warped():
	if Launcher.Map.mapNode && Launcher.Map.mapNode.has_meta("music"):
		Load(Launcher.Map.mapNode.get_meta("music"))

#
func _post_run():
	audioPlayer = Launcher.Scene.get_node("AudioStreamPlayer")
	Launcher.Util.Assert(audioPlayer != null, "Could not find the AudioStreamPlayer instance")

	if Launcher.Map:
		Launcher.Map.PlayerWarped.connect(self.Warped)
		Warped()
