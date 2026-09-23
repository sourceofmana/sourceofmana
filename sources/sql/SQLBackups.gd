extends Node
class_name SQLBackups

#
var thread : Thread						= Thread.new()
var isRunning : bool					= false
var stopRequested : bool				= false

#
func CreateDailyBackup() -> String:
	var date : Dictionary = Time.get_datetime_dict_from_system()
	var frequencyDir : String = SQLCommons.GetBackupFrequencyPath(SQLCommons.BackupFrequency.DAILY)
	var backupFile : String = frequencyDir + "%d-%02d-%02d_%02d-%02d-%02d" % [date.year, date.month, date.day, date.hour, date.minute, date.second] + Path.DBExt
	if Launcher.SQL.Backup(backupFile):
		Util.PrintInfo("SQL", "Backup created: " + backupFile)
		return backupFile
	else:
		Util.PrintLog("SQL", "Backup failed: " + backupFile)
		return ""

func CopyBackup(backupFilePath : String, backupFrequency : SQLCommons.BackupFrequency) -> String:
	var newFile : String = SQLCommons.GetBackupFrequencyPath(backupFrequency) + backupFilePath.get_file()
	var errorCode : Error = DirAccess.copy_absolute(backupFilePath, newFile)

	if (errorCode == Error.OK):
		Util.PrintInfo("SQL", "Backup created: " + newFile)
		return newFile
	else:
		Util.PrintLog("SQL", "Backup failed for file %s with code %d" % [newFile, errorCode])
		return ""

func GetLastBackupTimestamp(backupFrequency : SQLCommons.BackupFrequency) -> int:
	var frequencyDir : String = SQLCommons.GetBackupFrequencyPath(backupFrequency)
	var dir : DirAccess = DirAccess.open(frequencyDir)
	if not dir:
		return 0

	var lastTimestamp : int = 0
	for file in dir.get_files():
		if file.get_extension() == "db":
			lastTimestamp = maxi(lastTimestamp, FileAccess.get_modified_time(frequencyDir + file))

	return lastTimestamp

func PruneBackups() -> void:
	for backupFrequency in SQLCommons.BackupFrequency.values():
		var dir : DirAccess = DirAccess.open(SQLCommons.GetBackupFrequencyPath(backupFrequency))
		if not dir:
			continue
		
		var dirFiles : PackedStringArray = dir.get_files()
		var backupFiles : PackedStringArray = []
		for file in dirFiles:
			if file.get_extension() == "db":
				backupFiles.append(file)

		while backupFiles.size() > SQLCommons.BackupLimits[backupFrequency]:
			backupFiles.sort() # Oldest backups first
			var prunedFile : String = backupFiles[0]
			var err : Error = dir.remove(prunedFile)
			if err == OK:
				Util.PrintInfo("SQL", "Backup removed: " + prunedFile)
			else:
				Util.PrintLog("SQL", "Backup removal failed: %s [%d]" % [prunedFile, err])
			backupFiles.remove_at(0)

#
func Run():
	Thread.set_thread_safety_checks_enabled(false)

	var lastDailyBackupTimestamp : int = GetLastBackupTimestamp(SQLCommons.BackupFrequency.DAILY)
	var lastWeeklyBackupTimestamp : int = GetLastBackupTimestamp(SQLCommons.BackupFrequency.WEEKLY)
	var lastMonthlyBackupTimestamp : int = GetLastBackupTimestamp(SQLCommons.BackupFrequency.MONTHLY)
	var lastPlayerUpdateTimestamp : int = SQLCommons.Timestamp()
	var lastStopCheckTimestamp : int = SQLCommons.Timestamp()

	while isRunning:
		var timestamp : int = SQLCommons.Timestamp()

		if timestamp - lastDailyBackupTimestamp >= SQLCommons.DailyBackupIntervalSec:
			var backupFilePath: String = CreateDailyBackup()
			lastDailyBackupTimestamp = timestamp

			if not backupFilePath.is_empty():
				if timestamp - lastWeeklyBackupTimestamp >= SQLCommons.WeeklyBackupIntervalSec \
						and not CopyBackup(backupFilePath, SQLCommons.BackupFrequency.WEEKLY).is_empty():
					lastWeeklyBackupTimestamp = timestamp

				if timestamp - lastMonthlyBackupTimestamp >= SQLCommons.MonthlyBackupIntervalSec \
						and not CopyBackup(backupFilePath, SQLCommons.BackupFrequency.MONTHLY).is_empty():
					lastMonthlyBackupTimestamp = timestamp

			PruneBackups()

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

	for backupFrequency in SQLCommons.BackupFrequency.values():
		var frequencyDir : String = SQLCommons.GetBackupFrequencyPath(backupFrequency)
		if not DirAccess.dir_exists_absolute(frequencyDir):
			DirAccess.make_dir_absolute(frequencyDir)
