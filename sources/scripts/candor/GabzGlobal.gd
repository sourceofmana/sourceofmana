extends NpcScript

# Wave parameters
var monstersPool : Array			= []
const waveDelay : float				= 5.0
const maxWave : int					= 10
const spawnCenter : Vector2i		= Vector2i(54 * 32, 67 * 32)
const spawnRadius : Vector2i		= Vector2i(200, 200)
const startFightDelay : float		= 5.0

# Local variables
var waveCount : int					= 0
var originalPlayerCount : int		= 0
#
func OnStart():
	for mobID in DB.EntitiesDB:
		var mob : EntityData = DB.EntitiesDB[mobID]
		if !!(mob._behaviour & AICommons.Behaviour.AGGRESSIVE) and !(mob._behaviour & AICommons.Behaviour.IMMOBILE):
			monstersPool.append(mob)

func OnCancel():
	Reset()
	if IsTriggering():
		Trigger()
	KillMonsters()

func OnTrigger():
	AddTimer(npc, startFightDelay, StartFight)

#
func StartFight():
	Reset()
	originalPlayerCount = AlivePlayerCount()
	NextWave()

func NextWave():
	waveCount += 1
	Notification("New wave")
	if waveCount > maxWave:
		Reward()
	else:
		SpawnMonsters()
		AddTimer(own, waveDelay, HandleWave)

func Reset():
	waveCount = 0
	originalPlayerCount = 0

func Reward():
	Notification("Congrats, you won")
	AddExp(100)
	AddGP(100)
	Reset()
	if IsTriggering():
		Trigger()

func SpawnMonsters():
	var remainingPoints : int = (5 * waveCount) + ceili(originalPlayerCount * 0.7)
	monstersPool.shuffle()
	var isStuck : bool = false
	while(remainingPoints > 0 and not isStuck):
		isStuck = true
		for mob in monstersPool:
			var mobPoint : int = mob._stats["Level"] if "Level" in mob._stats else 1
			if mobPoint <= remainingPoints:
				remainingPoints -= mobPoint
				Spawn(mob._name, 1, spawnCenter, spawnRadius)

func HandleWave():
	if AlivePlayerCount() > 0:
		var mobCount : int = MonsterCount()
		if mobCount > 0:
			Notification("You still have %d Kaore corrupted beings around." % mobCount)
			AddTimer(own, waveDelay, HandleWave)
		else:
			NextWave()
	else:
		OnCancel()
