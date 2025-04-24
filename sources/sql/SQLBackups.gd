extends Node
class_name SQLBackups

#
var thread : Thread						= Thread.new()
var isRunning : bool					= false
var stopRequested : bool				= false

#
func CreateBackup() -> void:
	var date : Dictionary = Time.get_datetime_dict_from_system()
	var backupFile : String = SQLCommons.GetBackupPath() + "%d-%02d-%02d_%02d-%02d-%02d" % [date.year, date.month, date.day, date.hour, date.minute, date.second] + Path.DBExt
	if Launcher.SQL.db.backup_to(backupFile):
		Util.PrintInfo("SQL", "Backup created: " + backupFile)
	else:
		Util.PrintLog("SQL", "Backup failed: " + backupFile)

func PruneBackups() -> void:
	var dir : DirAccess = DirAccess.open(SQLCommons.GetBackupPath())
	if not dir:
		return
	
	var dirFiles : PackedStringArray = dir.get_files()
	var backupFiles : Array[String] = []
	for file in dirFiles:
		if file.get_extension() == "db":
			backupFiles.append(file)

		backupFiles.sort() # Oldest backups first
		while backupFiles.size() > SQLCommons.BackupLimit:
			var prunedFile : String = backupFiles.pop_front()
			var err : Error = dir.remove(prunedFile)
			if err == OK:
				Util.PrintInfo("SQL", "Backup removed: " + prunedFile)
			else:
				Util.PrintLog("SQL", "Backup removal failed: %s [%d]" % [prunedFile, err])

#
func Run():
	Thread.set_thread_safety_checks_enabled(false)

	var lastBackupTimestamp : int = SQLCommons.Timestamp()
	var lastPlayerUpdateTimestamp : int = SQLCommons.Timestamp()
	var lastStopCheckTimestamp : int = SQLCommons.Timestamp()

	while isRunning:
		var timestamp : int = SQLCommons.Timestamp()

		if timestamp - lastBackupTimestamp >= SQLCommons.BackupIntervalSec:
			CreateBackup()
			PruneBackups()
			lastBackupTimestamp = timestamp

		if timestamp - lastPlayerUpdateTimestamp >= SQLCommons.BackupPlayersSec:
			if Launcher.World:
				Launcher.World.BackupPlayers()
			lastPlayerUpdateTimestamp = timestamp

		if timestamp - lastStopCheckTimestamp >= SQLCommons.BackupCheckIntervalSec:
			if stopRequested:
				isRunning = false
				break
			lastStopCheckTimestamp = timestamp

		OS.delay_msec(100)

func Start():
	if not isRunning:
		isRunning = true
		thread.start(Run, Thread.PRIORITY_LOW)

func Stop():
	if isRunning and not stopRequested:
		stopRequested = true
		thread.wait_to_finish()

#
func _init():
	var backupPath : String = SQLCommons.GetBackupPath()
	if not DirAccess.dir_exists_absolute(backupPath):
		DirAccess.make_dir_absolute(backupPath)

	Start()
