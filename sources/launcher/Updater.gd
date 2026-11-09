extends Node
class_name UpdaterService

#
const DefaultFeedUrl : String			= LauncherCommons.GitHubReleasesLink + "/latest/download/"
const LatestReleaseUrl : String			= LauncherCommons.GitHubReleasesLink + "/latest"
const ReleaseTagPrefix : String			= "/releases/tag/v"
const FeedFileName : String				= "releases.win.json"
const FullPackageType : String			= "Full"
const FeedUrlArg : String				= "--update-url="
const VelopackHooks : PackedStringArray	= ["--veloapp-install", "--veloapp-updated", "--veloapp-obsolete", "--veloapp-uninstall"]
const FeedTimeout : float				= 10.0

var feedUrl : String					= GetFeedUrl()
var feedRequest : HTTPRequest			= null
var packageRequest : HTTPRequest		= null
var packagePath : String				= ""
var packageHash : String				= ""
var packageVersion : String				= ""
var progressText : String				= ""

#
static func IsVelopackHook() -> bool:
	for arg in OS.get_cmdline_args():
		if arg in VelopackHooks:
			return true
	return false

static func GetFeedUrl() -> String:
	var url = DefaultFeedUrl
	for arg in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if arg.begins_with(FeedUrlArg):
			url = arg.trim_prefix(FeedUrlArg)
	return url if url.ends_with("/") else url + "/"

static func GetUpdateExePath() -> String:
	return OS.get_executable_path().get_base_dir().get_base_dir().path_join("Update.exe")

static func GetPackageDir() -> String:
	return GetUpdateExePath().get_base_dir().path_join("packages")

static func IsVelopackInstall() -> bool:
	return OS.get_name() == "Windows" and FileSystem.FileExists(GetUpdateExePath())

static func IsAvailable() -> bool:
	return not OS.has_feature("editor") and not LauncherCommons.isWeb and not LauncherCommons.isStoreBuild

static func ParseReleaseVersion(headers : PackedStringArray) -> String:
	for header in headers:
		if header.to_lower().begins_with("location:") and header.contains(ReleaseTagPrefix):
			return header.get_slice(ReleaseTagPrefix, 1).strip_edges()
	return ""

static func GetCurrentVersion() -> String:
	return str(ProjectSettings.get_setting("application/config/version", ""))

static func ParseVersion(version : String) -> PackedInt32Array:
	var numbers : PackedInt32Array = []
	for part in version.get_slice("-", 0).get_slice("+", 0).split("."):
		numbers.append(part.to_int())
	return numbers

static func IsNewerVersion(candidate : String, current : String) -> bool:
	var candidateNumbers : PackedInt32Array = ParseVersion(candidate)
	var currentNumbers : PackedInt32Array = ParseVersion(current)
	var count : int = maxi(candidateNumbers.size(), currentNumbers.size())
	candidateNumbers.resize(count)
	currentNumbers.resize(count)
	for i in count:
		if candidateNumbers[i] != currentNumbers[i]:
			return candidateNumbers[i] > currentNumbers[i]
	return false

static func FindLatestFullAsset(feed : Variant) -> Dictionary:
	var latest : Dictionary = {}
	if not feed is Dictionary or not feed.get("Assets") is Array:
		return latest

	for asset in feed["Assets"]:
		if asset is Dictionary and asset.get("Type", "") == FullPackageType:
			if latest.is_empty() or IsNewerVersion(asset.get("Version", ""), latest.get("Version", "")):
				latest = asset
	return latest

# Check
func CheckForUpdate():
	feedRequest = HTTPRequest.new()
	feedRequest.timeout = FeedTimeout
	add_child(feedRequest)
	if IsVelopackInstall():
		feedRequest.request_completed.connect(FeedReceived)
		if feedRequest.request(feedUrl + FeedFileName) != OK:
			Util.PrintLog("Updater", "Could not request the update feed")
	else:
		feedRequest.max_redirects = 0
		feedRequest.request_completed.connect(ReleaseReceived)
		if feedRequest.request(LatestReleaseUrl) != OK:
			Util.PrintLog("Updater", "Could not request the latest release")

func ReleaseReceived(_result : int, responseCode : int, headers : PackedStringArray, _body : PackedByteArray):
	packageVersion = ParseReleaseVersion(headers)
	if packageVersion.is_empty():
		Util.PrintLog("Updater", "Latest release unavailable (code: %d)" % responseCode)
		return

	if not IsNewerVersion(packageVersion, GetCurrentVersion()):
		Util.PrintLog("Updater", "Up to date (%s)" % GetCurrentVersion())
		return

	Util.PrintLog("Updater", "Version %s available" % packageVersion)
	DisplayWhenFree(UICommons.MessageBox.bind("A new version of Source of Mana is available.\n\nCurrent version: %s\nNew version: %s\n\nYou can download it from our itch.io page." % [GetCurrentVersion(), packageVersion],
		OpenDownloadPage, "Download",
		Postpone, "Later"))

func OpenDownloadPage():
	OS.shell_open(LauncherCommons.ItchPageLink)

func FeedReceived(result : int, responseCode : int, _headers : PackedStringArray, body : PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS or responseCode != 200:
		Util.PrintLog("Updater", "Update feed unavailable (result: %d, code: %d)" % [result, responseCode])
		return

	var asset : Dictionary = FindLatestFullAsset(JSON.parse_string(body.get_string_from_utf8()))
	if asset.is_empty():
		Util.PrintLog("Updater", "No full package found in the update feed")
		return

	packageVersion = asset.get("Version", "")
	if not IsNewerVersion(packageVersion, GetCurrentVersion()):
		Util.PrintLog("Updater", "Up to date (%s)" % GetCurrentVersion())
		return

	packageHash = str(asset.get("SHA256", "")).to_lower()
	if packageHash.is_empty():
		Util.PrintLog("Updater", "Version %s has no SHA256 in the update feed" % packageVersion)
		return

	packagePath = GetPackageDir().path_join(str(asset.get("FileName", "")).get_file())
	Util.PrintLog("Updater", "Version %s available" % packageVersion)
	DisplayWhenFree(UICommons.MessageBox.bind("A new version of Source of Mana is available.\n\nCurrent version: %s\nNew version: %s\n\nThe game will restart once the update is installed." % [GetCurrentVersion(), packageVersion],
		Download, "Update",
		Postpone, "Later"))

func Postpone():
	Util.PrintLog("Updater", "Update to %s postponed" % packageVersion)

# Download
func Download():
	DirAccess.make_dir_recursive_absolute(GetPackageDir())
	packageRequest = HTTPRequest.new()
	packageRequest.use_threads = true
	packageRequest.download_file = packagePath
	add_child(packageRequest)
	packageRequest.request_completed.connect(PackageReceived)
	if packageRequest.request(feedUrl + packagePath.get_file()) != OK:
		ShowError("Could not start the download.")
		return

	UICommons.MessageBox("Downloading version %s..." % packageVersion)
	Launcher.GUI.messageBox.closeCallback = Callable()
	progressText = Launcher.GUI.messageBox.label.get_text()
	set_process(true)

func PackageReceived(result : int, responseCode : int, _headers : PackedStringArray, _body : PackedByteArray):
	set_process(false)
	if result != HTTPRequest.RESULT_SUCCESS or responseCode != 200:
		DirAccess.remove_absolute(packagePath)
		ShowError("The download failed (result: %d, code: %d)." % [result, responseCode])
		return

	if FileAccess.get_sha256(packagePath) != packageHash:
		DirAccess.remove_absolute(packagePath)
		ShowError("The downloaded update is corrupted.")
		return

	RemoveOtherPackages()
	Apply()

func RemoveOtherPackages():
	for fileName in FileSystem.GetFiles(GetPackageDir()):
		if fileName.ends_with(Path.PackageExt) and fileName != packagePath.get_file():
			DirAccess.remove_absolute(GetPackageDir().path_join(fileName))

func _process(_delta : float):
	if not packageRequest or Launcher.GUI.messageBox.label.get_text() != progressText:
		return

	var totalBytes : int = packageRequest.get_body_size()
	var downloadedBytes : int = packageRequest.get_downloaded_bytes()
	var progress : String = String.humanize_size(downloadedBytes)
	if totalBytes > 0:
		progress = "%d%% (%s / %s)" % [floori(downloadedBytes * 100.0 / totalBytes), progress, String.humanize_size(totalBytes)]
	progressText = "Downloading version %s...\n\n%s" % [packageVersion, progress]
	Launcher.GUI.messageBox.label.set_text(progressText)

# Apply
func Apply():
	var arguments : PackedStringArray = ["apply", "--package", packagePath, "--waitPid", str(OS.get_process_id())]
	if OS.create_process(GetUpdateExePath(), arguments) == -1:
		ShowError("Could not start the updater.")
		return

	Util.PrintLog("Updater", "Applying version %s, quitting" % packageVersion)
	Launcher.Quit()

func ShowError(reason : String):
	Util.PrintLog("Updater", reason)
	if Launcher.GUI.messageBox.label.get_text() == progressText:
		Launcher.GUI.messageBox.Clear()
	DisplayWhenFree(UICommons.MessageBox.bind("Could not update Source of Mana.\n\n%s" % reason, Postpone, "OK"))

func DisplayWhenFree(display : Callable):
	if Launcher.GUI.messageBox.hasActionLock:
		Launcher.GUI.messageBox.visibility_changed.connect(DisplayWhenFree.bind(display), CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	else:
		display.call()

#
func _ready():
	set_process(false)
	CheckForUpdate()
