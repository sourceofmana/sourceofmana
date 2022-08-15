extends Node

var directory = Directory.new();

# Generic
func FileExists(path : String) -> bool:
	return directory.file_exists(path)

func ResourceExists(path : String) -> bool:
	return ResourceLoader.exists(path)

func FileLoad(path : String) -> Resource:
	return load(path)

func ResourceLoad(path : String) -> Resource:
	return ResourceLoader.load(path)

# DB
func LoadDB(path : String) -> Dictionary:
	var fullPath : String		= Launcher.Path.DBRsc + path
	var result : Dictionary		= {}

	var pathExists : bool		= FileExists(fullPath)
	assert(pathExists, "DB file not found " + path + " should be located at " + fullPath)

	if pathExists:
		var DBFile : File	= File.new()
		var err : int		= DBFile.open(fullPath, File.READ)

		assert(err == OK, "DB parsing error loading JSON file '" + fullPath + "'" \
			+ " Error: " + str(err) \
		)
		if err == OK:
			var DBJson : JSONParseResult = JSON.parse(DBFile.get_as_text())
			DBFile.close()

			assert(DBJson.error == OK, "DB parsing issue on file " + fullPath \
				+ " Error: " + str(DBJson.error) \
				+ " Error Line: " + str(DBJson.error_line) \
				+ " Error String: " + str(DBJson.error_string) \
			)
			if DBJson.error == OK:
				result = DBJson.result
				print("Loading DB: " + fullPath)

	return result

# Map
func LoadMap(path : String) -> Node:
	var mapInstance : Node		= null

	var filePath : String		= Launcher.Path.MapRsc + path
	var scenePath : String		= filePath + Launcher.Path.SceneExt
	var mapPath : String		= filePath + Launcher.Path.MapExt
	var usedPath : String		= ""

	if ResourceExists(scenePath):
		usedPath = scenePath
	elif ResourceExists(mapPath):
		usedPath = mapPath
	else:
		assert(true, "Map file not found " + path + "(.tmx/.tscn) should be located at " + Launcher.Path.MapRsc)

	if usedPath != "":
		mapInstance = ResourceLoad(usedPath).instance()
		print("Loading map: " + usedPath)

	return mapInstance

# Scene
func LoadScene(path : String) -> Node:
	var scnInstance : Node		= null
	var fullPath : String		= Launcher.Path.Scn + path + Launcher.Path.SceneExt
	var pathExists : bool		= ResourceExists(fullPath)

	assert(pathExists, "Scene file not found " + fullPath + " should be located at " + Launcher.Path.Scn)
	if pathExists:
		scnInstance = ResourceLoad(fullPath).instance()
		print("Loading scene: " + fullPath)

	return scnInstance

# Preset
func LoadPreset(path : String) -> Node:
	var presetInstance : Node	= null
	var fullPath : String		= Launcher.Path.PresetScn + path + Launcher.Path.SceneExt
	var pathExists : bool		= ResourceExists(fullPath)

	assert(pathExists, "Preset file not found " + fullPath + " should be located at " + Launcher.Path.PresetScn)
	if pathExists:
		presetInstance = ResourceLoad(fullPath).instance()
		print("Loading preset: " + fullPath)

	return presetInstance

# Source
func LoadSource(path : String) -> Node:
	var fullPath : String		= Launcher.Path.Src + path
	var srcFile : Node			= null
	if OS.has_feature("standalone"):
		fullPath += "c"

	var pathExists : bool		= ResourceExists(fullPath)
	assert(pathExists, "Source file not found " + path + " should be located at " + fullPath)

	if pathExists:
		srcFile = ResourceLoad(fullPath).new()
		print("Loading Source: " + fullPath)

	return srcFile

# Config
func LoadConfig(path : String) -> ConfigFile:
	var fullPath : String		= Launcher.Path.ConfRsc + path + Launcher.Path.ConfExt
	var localPath : String		= Launcher.Path.ConfLocal + path + Launcher.Path.ConfExt
	var cfgFile : ConfigFile	= null

	var pathExists : bool = false
	if FileExists(localPath):
		pathExists = true
		fullPath = localPath
	else:
		pathExists = FileExists(fullPath)
	assert(pathExists, "Config file not found " + path + " should be located at " + fullPath)

	if pathExists:
		cfgFile = ConfigFile.new()

		var err = cfgFile.load(fullPath)
		assert(err == OK, "Error loading the config file " + path + " located at " + fullPath)

		if err != OK:
			cfgFile.free()
			cfgFile = null
		else:
			print("Loading Config: " + fullPath)

	return cfgFile

func SaveConfig(path : String, cfgFile : ConfigFile):
	var fullPath = Launcher.Path.ConfLocal + path
	assert(cfgFile, "Config file " + path + " not initialized")

	if cfgFile:
		var pathExists : bool = FileExists(fullPath)
		assert(pathExists, "Config file not found " + path + " should be located at " + fullPath)

		if pathExists:
			var err = cfgFile.save(fullPath)
			assert(err == OK, "Error saving the config file " + path + " located at " + fullPath)
			print("Saving Config: " + fullPath)
