extends AudioStreamPlayer

var currentTrack : String = ""

#
func Stop():
	if is_playing():
		stop()
	currentTrack = ""

func Load(soundName : String):
	if currentTrack != soundName && not soundName.is_empty() && DB.MusicsDB[soundName] != null:
		var soundStream : Resource = FileSystem.LoadMusic(DB.MusicsDB[soundName]._path as String)
		assert(soundStream != null, "Could not load music: " + soundName)
		if soundStream != null:
			soundStream.set_loop(true)
			set_stream(soundStream)
			currentTrack		= soundName

			set_autoplay(true)
			play()

func SetVolume(volume : float):
	set_volume_db(volume)

func Warped():
	if Launcher.Map.mapNode && Launcher.Map.mapNode.has_meta("music"):
		Load(Launcher.Map.mapNode.get_meta("music") as String)
	else:
		Stop()

#
func _post_launch():
	if Launcher.FSM and not Launcher.FSM.exit_game.is_connected(Stop):
		Launcher.FSM.exit_game.connect(Stop)
	if Launcher.Map and not Launcher.Map.PlayerWarped.is_connected(Warped):
		Launcher.Map.PlayerWarped.connect(Warped)
		Warped()
