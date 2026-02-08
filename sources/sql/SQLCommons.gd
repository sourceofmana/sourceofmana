extends RefCounted
class_name SQLCommons

# Constant variables
const DBNameTemplate : String			= "sqlite.template.db"
const DBNameTesting : String			= "testing.db"
const DBName : String					= "live.db"
const BackupPath : String				= "sql-backups/"
const BackupPathTesting : String		= "sql-testing-backups/"
const BackupCheckIntervalSec : int		= 2
const BackupPlayersSec : int			= 10 * 60 # Every minute

const DailyBackupIntervalSec : int		= 60 * 60 * 24
const WeeklyBackupIntervalSec : int		= 60 * 60 * 24 * 7
const MonthlyBackupIntervalSec : int	= 60 * 60 * 24 * 7 * 4

enum BackupFrequency {DAILY, WEEKLY, MONTHLY}

const BackupLimits : Dictionary[BackupFrequency, int] = {
	BackupFrequency.DAILY: 7,
	BackupFrequency.WEEKLY: 4,
	BackupFrequency.MONTHLY: 12
}

# Utils
static func HasValue(data : Dictionary, key : String) -> bool:
	return data[key] != null if data.has(key) else false

static func GetOrAddValue(data : Dictionary, key : String, defaultVal : Variant) -> Variant:
	return data[key] if HasValue(data, key) else defaultVal

static func Timestamp() -> int:
	return int(Time.get_unix_time_from_system()) # Remove sub-seconds precision

# Live/Testing DB handling
static func GetBackupPath() -> String:
	return Path.Local + (BackupPathTesting if LauncherCommons.IsTesting else BackupPath)

static func GetDBPath() -> String:
	return Path.Local + (DBNameTesting if LauncherCommons.IsTesting else DBName)

static func CopyDatabase(targetPath : String) -> bool:
	# Try to copy the live database
	if LauncherCommons.IsTesting:
		if FileSystem.CopyFile(Path.Local + DBName, targetPath):
			return true
	# Try to copy the template database
	if FileSystem.CopyFile(Path.TemplateRsc + DBNameTemplate, targetPath):
		return true
	assert(false, "Could not find the default database template")
	return false
