extends NpcScript

# Mission parameters
var rewardExp : int		= 1000
var rewardGP : int		= 10000

# Wave parameters
var monstersPool : Array			= []
const checkDelay : float			= 2.0
const waveDelay : float				= 300.0
const maxWave : int					= 10
const spawnCenter : Vector2i		= Vector2i(54 * 32, 67 * 32)
const spawnRadius : Vector2i		= Vector2i(200, 200)
const startFightDelay : float		= 10.0

# Local variables
var waveTimer : Timer				= null
var waveCount : int					= 0
var originalPlayerCount : int		= 0
#
func OnStart():
	for mobID in DB.EntitiesDB:
		var mob : EntityData = DB.EntitiesDB[mobID]
		if !!(mob._behaviour & AICommons.Behaviour.AGGRESSIVE) and !(mob._behaviour & AICommons.Behaviour.IMMOBILE):
			monstersPool.append(mob)

func OnCancel():
	ClearTimer(waveTimer)
	Reset()
	if IsTriggering():
		Trigger()
	KillMonsters()
	var ownInstance : WorldInstance = WorldAgent.GetInstanceFromAgent(own)
	for player in ownInstance.players:
		Callback.ClearOneShot(player.tree_exiting)
		Callback.ClearOneShot(player.agent_killed)

func OnTrigger():
	AddTimer(npc, startFightDelay, StartFight)

#
func StartFight():
	Reset()
	originalPlayerCount = AlivePlayerCount()
	waveTimer = AddTimer(npc, waveDelay, TimeoutWave)
	NextWave()

func NextWave():
	waveCount += 1
	Notification("Wave %d." % waveCount)
	if waveCount > maxWave:
		Reward()
	else:
		SpawnMonsters()
		waveTimer.start(waveDelay)
		AddTimer(npc, checkDelay, CheckWave, "CheckTimer")

func Reset():
	waveTimer = null
	waveCount = 0
	originalPlayerCount = 0

func Reward():
	Notification("Congrats, you won")
	AddExp(rewardExp)
	AddGP(rewardGP)
	Reset()
	if IsTriggering():
		Trigger()

func SpawnMonsters():
	var isStuck : bool = false
	var remainingPoints : int = (5 * waveCount) + ceili(originalPlayerCount * 0.7)
	monstersPool.shuffle()
	while(remainingPoints > 0 and not isStuck):
		isStuck = true
		for mob in monstersPool:
			var mobPoint : int = mob._stats["Level"] if "Level" in mob._stats else 1
			if mobPoint > 0 and mobPoint <= remainingPoints:
				var spawnAmount : int = randi_range(1, int(remainingPoints / floor(mobPoint)))
				remainingPoints -= mobPoint * spawnAmount
				Spawn(mob._name, spawnAmount, spawnCenter, spawnRadius)

func CheckWave():
	if not IsTriggering():
		return

	if AlivePlayerCount() == 0:
		OnCancel()
	else:
		var mobCount : int = AliveMonsterCount()
		if mobCount > 0:
			if mobCount > 1:
				Notification("%d kaore corrupted beings are still around." % mobCount)
			else:
				Notification("One kaore corrupted being left to kill.")
			AddTimer(npc, checkDelay, CheckWave, "CheckTimer")
		else:
			NextWave()

func TimeoutWave():
	Notification("You were not able to clear the corruption in time.")
	OnCancel()
