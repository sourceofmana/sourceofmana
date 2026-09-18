extends AudioStreamPlayer

const DefaultTrack : String				= "LaJohanne"

var currentTrack : int					= DB.UnknownHash
var soundStream : AudioStreamOggVorbis	= null

#
func Stop():
	if is_playing():
		stop()
	currentTrack = DB.UnknownHash

func Load(soundID : int):
	if currentTrack != soundID:
		if soundStream:
			soundStream = null
			currentTrack = DB.UnknownHash

		var soundData : FileData = DB.MusicDB.get(soundID, null)
		if not soundData:
			assert(false, "Could not load music database id: %s" % soundID)
			return

		soundStream = soundData._resource as AudioStreamOggVorbis
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
func _post_launch():
	if not Launcher.dbInitialized.is_connected(PlayDefault):
		Launcher.dbInitialized.connect(PlayDefault)
	if Launcher.Map and not Launcher.Map.PlayerWarped.is_connected(Warped):
		Launcher.Map.PlayerWarped.connect(Warped)
		Warped()
