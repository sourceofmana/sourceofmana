extends Node
class_name SQLBackups

#
var thread : Thread						= Thread.new()
var isRunning : bool					= false
var stopRequested : bool				= false
var skipBackup : bool					= true

#
func CreateBackup() -> void:
	var date : Dictionary = Time.get_datetime_dict_from_system()
	var backupFile : String = Path.Local + SQLCommons.BackupDBPath + "%d-%02d-%02d_%02d-%02d-%02d" % [date.year, date.month, date.day, date.hour, date.minute, date.second] + Path.DBExt
	if Launcher.SQL.db.backup_to(backupFile):
		Util.PrintInfo("SQL", "Backup created: " + backupFile)
	else:
		Util.PrintLog("SQL", "Backup failed: " + backupFile)

func PruneBackups() -> void:
	var dir : DirAccess = DirAccess.open("user://" + SQLCommons.BackupDBPath)
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
	while isRunning:
		if not skipBackup:
			CreateBackup()
			PruneBackups()

		var sleepTime : int = SQLCommons.BackupIntervalSec
		while sleepTime > 0 and not stopRequested:
			OS.delay_msec(SQLCommons.BackupCheckIntervalSec * 1000)
			sleepTime -= SQLCommons.BackupCheckIntervalSec
		skipBackup = false

		if stopRequested:
			isRunning = false

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
	var dir : DirAccess = DirAccess.open("user://")
	if not dir.dir_exists(SQLCommons.BackupDBPath):
		dir.make_dir(SQLCommons.BackupDBPath)

	Start()
