extends Node
class_name FileSystem

# Generic
static func FileExists(path : String) -> bool:
	return FileAccess.file_exists(path)

static func ResourceExists(path : String) -> bool:
	return ResourceLoader.exists(path)

static func FileAlloc(path : String) -> Object:
	return ResourceLoader.load(path).new()

static func CanInstantiateResource(res : Object) -> bool:
	return res.has_method("can_instantiate") && res.can_instantiate()

static func ResourceInstance(path : String) -> Object:
	var resourceLoaded : Object		= ResourceLoader.load(path)
	var resourceInstance : Object	= null
	if resourceLoaded != null && CanInstantiateResource(resourceLoaded):
		resourceInstance = resourceLoaded.instantiate()
	return resourceInstance

static func ResourceInstanceOrLoad(path : String) -> Object:
	var resourceLoaded : Object		= ResourceLoader.load(path)
	var resource : Object			= null
	if resourceLoaded != null:
		if CanInstantiateResource(resourceLoaded):
			resource = resourceLoaded.instantiate()
		else:
			resource = resourceLoaded
	return resource

# File
static func LoadFile(path : String) -> String:
	var fullPath : String		= Path.DataRsc + path
	var content : String		= ""

	var pathExists : bool		= FileExists(fullPath)
	assert(pathExists, "Content file not found " + path + " should be located at " + fullPath)

	if pathExists:
		var file : FileAccess = FileAccess.open(fullPath, FileAccess.READ)
		assert(file != null, "File parsing issue on file " + fullPath)
		if file:
			content = file.get_as_text()
			Util.PrintLog("File", "Loading file: " + fullPath)
			file.close()
	return content

static func SaveFile(fullPath : String, content : String):
	var file : FileAccess		= FileAccess.open(fullPath, FileAccess.WRITE)
	assert(file != null, "File parsing issue on file " + fullPath)
	if file:
		file.store_string(content)
		file.close()
		Util.PrintInfo("FileSystem", "Saving file %s" % fullPath)

# DB
static func LoadDB(path : String) -> Dictionary:
	var fullPath : String		= Path.DBRsc + path
	var result : Dictionary		= {}

	var pathExists : bool		= FileExists(fullPath)
	assert(pathExists, "DB file not found " + path + " should be located at " + fullPath)

	if pathExists:
		var DBFile : FileAccess = FileAccess.open(fullPath, FileAccess.READ)

		var jsonInstance : JSON = JSON.new()
		var err : int = jsonInstance.parse(DBFile.get_as_text())

		assert(err == OK, "DB parsing issue on file " + fullPath \
			+ " Line: " + str(jsonInstance.get_error_line()) \
			+ " Error: " + jsonInstance.get_error_message() \
		)
		if err == OK:
			result = jsonInstance.get_data()
			Util.PrintLog("DB", "Loading file: " + fullPath)

	return result

# Map
static func LoadMap(path : String, ext : String) -> Object:
	var mapInstance : Object	= null

	var filePath : String		= Path.MapRsc + path
	var scenePath : String		= filePath + ext
	var pathExists : bool		= ResourceExists(scenePath)

	assert(pathExists, "Map file not found " + scenePath + " should be located at " + Path.MapRsc)
	if pathExists:
		mapInstance = ResourceInstanceOrLoad(scenePath)
		Util.PrintLog("Map", "Loading resource: " + scenePath)

	return mapInstance

# Source
static func LoadGDScript(fullPath : String, alloc : bool = true) -> Object:
	var srcFile : Object		= null

	var pathExists : bool		= ResourceExists(fullPath)
	assert(pathExists, "GDScript file not found " + fullPath)

	if pathExists:
		srcFile = FileAlloc(fullPath) if alloc else ResourceLoader.load(fullPath)
		Util.PrintLog("Source", "Loading script: " + fullPath)

	return srcFile

static func LoadSource(path : String, alloc : bool = true) -> Object:
	return LoadGDScript(Path.Src + path, alloc)

static func LoadScript(path : String, alloc : bool = false) -> Object:
	return LoadGDScript(Path.ScriptSrc + path, alloc)

# Config
static func LoadConfig(path : String, userDir : bool = false) -> ConfigFile:
	var fullPath : String		= (Path.Local if userDir else Path.ConfRsc) + path + Path.ConfExt
	var cfgFile : ConfigFile	= null

	var pathExists : bool = FileExists(fullPath)
	if pathExists or userDir:
		cfgFile = ConfigFile.new()
		if pathExists:
			var err : Error = cfgFile.load(fullPath)
			assert(err == OK, "Error loading the config file " + path + " located at " + fullPath)

			if err != OK:
				cfgFile.free()
				cfgFile = null
			else:
				Util.PrintLog("Config", "Loading file: " + fullPath)
	else:
		assert(pathExists, "Config file not found " + path + " should be located at " + fullPath)

	return cfgFile

static func SaveConfig(path : String, cfgFile : ConfigFile):
	assert(cfgFile != null, "Config file " + path + " not initialized")

	if cfgFile:
		var fullPath : String = Path.Local + path + Path.ConfExt
		var err : Error = cfgFile.save(fullPath)
		assert(err == OK, "Error saving the config file " + path + " located at " + fullPath)
		Util.PrintLog("Config", "Saving file: " + fullPath)

# Resource
static func LoadResource(fullPath : String, instantiate : bool = true) -> Object:
	var rscInstance : Object	= null
	var pathExists : bool		= ResourceExists(fullPath)

	assert(pathExists, "Resource file not found at: " + fullPath)
	if pathExists:
		rscInstance = ResourceInstance(fullPath) if instantiate else ResourceLoader.load(fullPath)

	return rscInstance

# Effect
static func LoadEffect(path : String, instantiate : bool = true) -> Node:
	var fullPath : String = Path.EffectsPst + path + Path.SceneExt
	return LoadResource(fullPath, instantiate)

# Entity
static func LoadEntitySprite(type : String, instantiate : bool = true) -> Node2D:
	var fullPath : String = Path.EntitySprite + type + Path.SceneExt
	return LoadResource(fullPath, instantiate)

static func LoadEntityComponent(type : String, instantiate : bool = true) -> Node:
	var fullPath : String = Path.EntityComponent + type + Path.SceneExt
	return LoadResource(fullPath, instantiate)

static func LoadEntityVariant(instantiate : bool = true) -> Entity:
	var fullPath : String = Path.EntityPst + "Entity" + Path.SceneExt
	return LoadResource(fullPath, instantiate)

# GUI
static func LoadGui(path : String, instantiate : bool = true) -> Resource:
	var fullPath : String = Path.GuiPst + path + Path.SceneExt
	return LoadResource(fullPath, instantiate)

# Music
static func LoadMusic(path : String) -> Resource:
	var fullPath : String = Path.MusicRsc + path
	var musicFile : Resource			= null

	var pathExists : bool		= ResourceExists(fullPath)
	assert(pathExists, "Music file not found " + path + " should be located at " + fullPath)

	if pathExists:
		musicFile = ResourceLoader.load(fullPath)
		Util.PrintLog("Music", "Loading file: " + fullPath)

	return musicFile

# Cell
static func LoadCell(path : String) -> BaseCell:
	var fullPath : String = path
	return LoadResource(fullPath, false)

# Generic texture loading
static func LoadGfx(path : String) -> Resource:
	var fullPath : String = Path.GfxRsc + path
	return LoadResource(fullPath, false)

# Minimap
static func LoadMinimap(path : String) -> Resource:
	var fullPath : String = Path.MinimapRsc + path + Path.GfxExt
	return LoadResource(fullPath, false)

static func GetFiles(path : String) -> PackedStringArray:
	return DirAccess.get_files_at(path)

static func SaveScreenshot():
	var image : Image = Util.GetScreenCapture()
	assert(image != null, "Could not get a viewport screenshot")
	if image:
		var dir : DirAccess = DirAccess.open(OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS))
		if not dir.dir_exists("Screenshots"):
			dir.make_dir("Screenshots")
		dir.change_dir("Screenshots")

		var date : Dictionary = Time.get_datetime_dict_from_system()
		var savePath : String = dir.get_current_dir(true)
		savePath += "/Screenshot-%d-%02d-%02d_%02d-%02d-%02d" % [date.year, date.month, date.day, date.hour, date.minute, date.second]
		savePath += Path.GfxExt

		if not dir.dir_exists(savePath):
			var ret : Error = image.save_png(savePath)
			assert(ret == OK, "Could not save the screenshot, error code: " + str(ret))
			if ret == OK:
				Util.PrintInfo("FileSystem", "Saving capture: " + savePath)

static func CopySQLDatabase(templateName : String, currentName : String) -> bool:
	var dir : DirAccess = DirAccess.open(Path.TemplateRsc)
	if dir:
		dir.list_dir_begin();
		var fileName : String = dir.get_next()
		while (fileName != ""):
			if fileName == templateName:
				dir.copy(Path.TemplateRsc + templateName, Path.Local + currentName)
				return true
			fileName = dir.get_next()
		assert(false, "Can't find the template resource file: %s" % templateName)
	else:
		assert(false, "Can't acces template resource path: %s" % Path.TemplateRsc)
	return false
