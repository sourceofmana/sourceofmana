extends Node

var audioPlayer : AudioStreamPlayer2D				= AudioStreamPlayer2D.new()
var currentTrack : String = ""

#
func Play(_pause : bool = false):
#	if pause:
#		audioPlayer.pause()
#	else:
#		audioPlayer.play()
	pass

func Stop():
	if audioPlayer.is_playing():
		audioPlayer.Stop()

func Load(name : String):
	if currentTrack != name:
		if name.empty() == false && Launcher.DB.MusicsDB[name] != null:
			var path = Launcher.Path.MusicRsc + Launcher.DB.MusicsDB[name]._path
			if path.empty() == false:
				var stream : AudioStreamOGGVorbis = load(path)
				stream.set_loop(true)

				audioPlayer.stream	= stream
				currentTrack		= name
#				audioPlayer.set_autoplay(true)
				audioPlayer.play()
