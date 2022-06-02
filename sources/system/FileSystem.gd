extends Node

var directory = Directory.new();

# Generic
func Exists(path : String) -> bool:
	return directory.file_exists(path)

# DB
func LoadDB(path : String) -> Dictionary:
	var fullPath : String		= Launcher.Path.DBRsc + path
	var result : Dictionary		= {}

	var pathExists : bool		= Exists(fullPath)
	assert(pathExists, "DB file not found " + path + " should be located at " + fullPath)

	if pathExists:
		var DBFile : File	= File.new()
		var err : int		= DBFile.open(fullPath, File.READ)

		assert(err == OK, "DB parsing error loading JSON file '" + fullPath + "'" \
			+ "\tError: " + str(err) \
		)
		if err == OK:
			var DBJson : JSONParseResult = JSON.parse(DBFile.get_as_text())
			DBFile.close()

			assert(DBJson.error == OK, "DB parsing issue on file " + fullPath \
				+ "\tError: " + str(DBJson.error) \
				+ "\tError Line: " + str(DBJson.error_line) \
				+ "\tError String: " + str(DBJson.error_string) \
			)
			if DBJson.error == OK:
				result = DBJson.result

	return result

# Scene
func LoadScene(path : String) -> Node:
	var fullPath : String		= Launcher.Path.Scn + path
	var scnInstance : Node		= null

	var pathExists : bool		= Exists(fullPath)
	assert(pathExists, "Scene file not found " + path + " should be located at " + fullPath)

	if pathExists:
		scnInstance = load(fullPath).instance()

	return scnInstance

# Source
func LoadSource(path : String) -> Node:
	var fullPath : String		= Launcher.Path.Src + path
	var srcFile : Node			= null

	var pathExists : bool		= Exists(fullPath)
	assert(pathExists, "Source file not found " + path + " should be located at " + fullPath)

	if pathExists:
		srcFile = ResourceLoader.load(fullPath).new()

	return srcFile

# Config
func LoadConfig(path : String) -> ConfigFile:
	var fullPath : String		= Launcher.Path.ConfRsc + path + ".conf"
	var cfgFile : ConfigFile	= null

	var pathExists : bool		= Exists(fullPath)
	assert(pathExists, "Config file not found " + path + " should be located at " + fullPath)

	if pathExists:
		cfgFile = ConfigFile.new()

		var err = cfgFile.load(fullPath)
		assert(err == OK, "Error loading the config file " + path + " located at " + fullPath)

		if err != OK:
			cfgFile.free()
			cfgFile = null

	return cfgFile

func SaveConfig(path : String, cfgFile : ConfigFile):
	var fullPath = Launcher.Path.Config + path
	assert(cfgFile, "Config file " + path + " not initialized")

	if cfgFile:
		var pathExists : bool = Exists(fullPath)
		assert(pathExists, "Config file not found " + path + " should be located at " + fullPath)

		if pathExists:
			var err = cfgFile.save(fullPath)
			assert(err == OK, "Error saving the config file " + path + " located at " + fullPath)
