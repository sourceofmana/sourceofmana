extends AudioStreamPlayer

var currentTrack : int = DB.UnknownHash

#
func Stop():
	if is_playing():
		stop()
	currentTrack = DB.UnknownHash

func Load(soundID : int):
	if currentTrack != soundID:
		var soundData : FileData = DB.MusicsDB.get(soundID, null)
		if not soundData:
			assert(false, "Could not load music database id: %s" % soundID)
			return

		var soundStream : Resource = FileSystem.LoadMusic(soundData._path)
		if not soundStream:
			assert(false, "Could not load music: %s" % soundData._name)
			return

		soundStream.set_loop(true)
		set_stream(soundStream)
		currentTrack = soundID

		set_autoplay(true)
		play()

func SetVolume(volume : float):
	set_volume_db(volume)

func Warped():
	if Launcher.Map.currentMapNode:
		var mapName : String = Launcher.Map.currentMapNode.get_meta("music", "")
		if not mapName.is_empty():
			Load(mapName.hash())
	else:
		Stop()

#
func _post_launch():
	if not FSM.exit_game.is_connected(Stop):
		FSM.exit_game.connect(Stop)
	if Launcher.Map and not Launcher.Map.PlayerWarped.is_connected(Warped):
		Launcher.Map.PlayerWarped.connect(Warped)
		Warped()
