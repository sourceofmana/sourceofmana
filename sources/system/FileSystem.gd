extends Node

# Generic
func FileExists(path : String) -> bool:
	return FileAccess.file_exists(path)

func ResourceExists(path : String) -> bool:
	return ResourceLoader.exists(path)

func FileLoad(path : String) -> Resource:
	return load(path)

func FileAlloc(path : String) -> Object:
	return FileLoad(path).new()

func CanInstantiateResource(res : Object) -> bool:
	return res.has_method("can_instantiate") && res.can_instantiate()

func ResourceLoad(path : String) -> Object:
	return ResourceLoader.load(path)

func ResourceInstance(path : String) -> Object:
	var resourceLoaded		= ResourceLoad(path)
	var resourceInstance	= null
	if resourceLoaded != null && CanInstantiateResource(resourceLoaded):
		resourceInstance = resourceLoaded.instantiate()
	return resourceInstance

func ResourceInstanceOrLoad(path : String) -> Object:
	var resourceLoaded		= ResourceLoad(path)
	var resource			= null
	if resourceLoaded != null:
		if CanInstantiateResource(resourceLoaded):
			resource = resourceLoaded.instantiate()
		else:
			resource = resourceLoaded
	return resource

# File
func LoadFile(path : String) -> String:
	var fullPath : String		= Launcher.Path.DataRsc + path
	var content : String		= ""

	var pathExists : bool		= FileExists(fullPath)
	Util.Assert(pathExists, "Content file not found " + path + " should be located at " + fullPath)

	if pathExists:
		var file : FileAccess = FileAccess.open(fullPath, FileAccess.READ)
		Util.Assert(file != null, "File parsing issue on file " + fullPath)
		if file:
			content = file.get_as_text()
			Util.PrintLog("File", "Loading file: " + fullPath)
			file.close()
	return content

func SaveFile(fullPath : String, content : String):
	var file : FileAccess		= FileAccess.open(fullPath, FileAccess.WRITE)
	Util.Assert(file != null, "File parsing issue on file " + fullPath)
	if file:
		file.store_string(content)
		Util.PrintLog("File", "Saving file: " + fullPath)
		file.close()

# DB
func LoadDB(path : String) -> Dictionary:
	var fullPath : String		= Launcher.Path.DBRsc + path
	var result : Dictionary		= {}

	var pathExists : bool		= FileExists(fullPath)
	Util.Assert(pathExists, "DB file not found " + path + " should be located at " + fullPath)

	if pathExists:
		var DBFile : FileAccess = FileAccess.open(fullPath, FileAccess.READ)

		var jsonInstance : JSON = JSON.new()
		var err : int = jsonInstance.parse(DBFile.get_as_text())

		Util.Assert(err == OK, "DB parsing issue on file " + fullPath \
			+ " Line: " + str(jsonInstance.get_error_line()) \
			+ " Error: " + jsonInstance.get_error_message() \
		)
		if err == OK:
			result = jsonInstance.get_data()
			Util.PrintLog("DB", "Loading file: " + fullPath)

	return result

func LoadDBInstance(path : String) -> Object:
	var partialPath : String = "db/instance/" + path
	return LoadSource(partialPath, false)

# Map
func LoadMap(path : String, ext : String) -> Object:
	var mapInstance : Object	= null

	var filePath : String		= Launcher.Path.MapRsc + path
	var scenePath : String		= filePath + ext
	var pathExists : bool		= ResourceExists(scenePath)

	Util.Assert(pathExists, "Map file not found " + path + Launcher.Path.MapClientExt + " should be located at " + Launcher.Path.MapRsc)
	if pathExists:
		mapInstance = ResourceInstanceOrLoad(scenePath)
		Util.PrintLog("Map", "Loading resource: " + scenePath)

	return mapInstance

# Source
func LoadSource(path : String, alloc : bool = true) -> Object:
	var fullPath : String		= Launcher.Path.Src + path
	var srcFile : Object		= null

	var pathExists : bool		= ResourceExists(fullPath)
	Util.Assert(pathExists, "Source file not found " + path + " should be located at " + fullPath)

	if pathExists:
		srcFile = FileAlloc(fullPath) if alloc else FileLoad(fullPath)
		Util.PrintLog("Source", "Loading script: " + fullPath)

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
	Util.Assert(pathExists, "Config file not found " + path + " should be located at " + fullPath)

	if pathExists:
		cfgFile = ConfigFile.new()

		var err = cfgFile.load(fullPath)
		Util.Assert(err == OK, "Error loading the config file " + path + " located at " + fullPath)

		if err != OK:
			cfgFile.free()
			cfgFile = null
		else:
			Util.PrintLog("Config", "Loading file: " + fullPath)

	return cfgFile

func SaveConfig(path : String, cfgFile : ConfigFile):
	var fullPath = Launcher.Path.ConfLocal + path
	Util.Assert(cfgFile != null, "Config file " + path + " not initialized")

	if cfgFile:
		var pathExists : bool = FileExists(fullPath)
		Util.Assert(pathExists, "Config file not found " + path + " should be located at " + fullPath)

		if pathExists:
			var err = cfgFile.save(fullPath)
			Util.Assert(err == OK, "Error saving the config file " + path + " located at " + fullPath)
			Util.PrintLog("Config", "Saving file: " + fullPath)

# Resource
func LoadResource(fullPath : String, instantiate : bool = true) -> Object:
	var rscInstance : Object	= null
	var pathExists : bool		= ResourceExists(fullPath)

	Util.Assert(pathExists, "Resource file not found at: " + fullPath)
	if pathExists:
		rscInstance = ResourceInstance(fullPath) if instantiate else ResourceLoad(fullPath)

	return rscInstance

# Entity
func LoadEntitySprite(type : String, instantiate : bool = true) -> BaseEntity:
	var fullPath : String = Launcher.Path.EntitySprite + type + Launcher.Path.SceneExt
	return LoadResource(fullPath, instantiate)

func LoadEntityComponent(type : String, instantiate : bool = true) -> BaseEntity:
	var fullPath : String = Launcher.Path.EntityComponent + type + Launcher.Path.SceneExt
	return LoadResource(fullPath, instantiate)

func LoadEntity(type : String, instantiate : bool = true) -> BaseEntity:
	var fullPath : String = Launcher.Path.EntityVariant + type + Launcher.Path.SceneExt
	return LoadResource(fullPath, instantiate)

# GUI
func LoadGui(path : String, instantiate : bool = true) -> Resource:
	var fullPath : String = Launcher.Path.GuiPst + path + Launcher.Path.SceneExt
	return LoadResource(fullPath, instantiate)

# Music
func LoadMusic(path : String) -> Resource:
	var fullPath : String = Launcher.Path.MusicRsc + path
	var musicFile : Resource			= null

	var pathExists : bool		= ResourceExists(fullPath)
	Util.Assert(pathExists, "Music file not found " + path + " should be located at " + fullPath)

	if pathExists:
		musicFile = FileLoad(fullPath)
		Util.PrintLog("Music", "Loading file: " + fullPath)

	return musicFile

# Generic texture loading
func LoadGfx(path : String) -> Resource:
	var fullPath : String = Launcher.Path.GfxRsc + path
	return LoadResource(fullPath, false)

# Minimap
func LoadMinimap(path : String) -> Resource:
	var fullPath : String = Launcher.Path.MinimapRsc + path + Launcher.Path.GfxExt
	return LoadResource(fullPath, false)

func SaveScreenshot():
	var image : Image = Launcher.Util.GetScreenCapture()
	Util.Assert(image != null, "Could not get a viewport screenshot")
	if image:
		var dir = DirAccess.open(OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS))
		if not dir.dir_exists("Screenshots"):
			dir.make_dir("Screenshots")
		dir.change_dir("Screenshots")

		var date : Dictionary = Time.get_datetime_dict_from_system()
		var savePath : String = dir.get_current_dir(true)
		savePath += "/Screenshot-%d-%02d-%02d_%02d-%02d-%02d" % [date.year, date.month, date.day, date.hour, date.minute, date.second]
		savePath += Launcher.Path.GfxExt

		if not dir.dir_exists(savePath):
			var ret = image.save_png(savePath)
			Util.Assert(ret == OK, "Could not save the screenshot, error code: " + str(ret))
			if ret == OK:
				Util.PrintLog("Screenshot", "Saving capture: " + savePath)
