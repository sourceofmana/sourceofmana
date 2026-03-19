extends NpcScript

# Mission parameters
var rewardExp : int		= 1000
var rewardGP : int		= 10000

# Wave parameters
var monstersPool : Array[EntityData]	= []
const checkDelay : float			= 2.0
const waveDelay : float				= 300.0
const maxWave : int					= 10
const spawnCenter : Vector2i		= Vector2i(54 * 32, 67 * 32)
const spawnRadius : Vector2i		= Vector2i(200, 200)
const startFightDelay : float		= 10.0
const warmUpTickDelay : float		= 1.0

# Local variables
var waveTimer : Timer				= null
var waveCount : int					= 0
var originalPlayerCount : int		= 0
var waveMaxMonsters : int			= 0
var playerList : Array[PlayerAgent]	= []

#
func OnStart():
	for mobID in DB.EntitiesDB:
		var mob : EntityData = DB.EntitiesDB[mobID]
		if !!(mob._behaviour & AICommons.Behaviour.AGGRESSIVE) and !(mob._behaviour & AICommons.Behaviour.IMMOBILE) and !mob._isBoss:
			monstersPool.append(mob)

func OnCancel():
	ClearTimer(waveTimer)
	ClearPlayerList()
	Reset()
	if IsTriggering():
		Trigger()
	ClearTracker()
	KillMonsters()

func OnTrigger():
	AddTimer(npc, startFightDelay, StartFight)
	TickWarmUp(0)

func TickWarmUp(tick : int):
	if not IsTriggering():
		return
	DisplayTracker("Warm Up", tick, int(startFightDelay), "s")
	if tick < int(startFightDelay):
		AddTimer(npc, warmUpTickDelay, TickWarmUp.bind(tick + 1), "WarmUpTimer")

#
func RemoveFromPlayerList(player : PlayerAgent):
	playerList.erase(player)

func ClearPlayerList():
	for player in playerList:
		Callback.ClearOneShot(player.tree_exiting)
		Callback.ClearOneShot(player.agent_killed)
	playerList.clear()

func StartFight():
	Reset()
	var ownInstance : WorldInstance = WorldAgent.GetInstanceFromAgent(own)
	if ownInstance:
		for player : PlayerAgent in ownInstance.players:
			if ActorCommons.IsAlive(player):
				playerList.append(player)
				Callback.OneShotCallback(player.tree_exiting, RemoveFromPlayerList.bind(player))
				Callback.OneShotCallback(player.agent_killed, RemoveFromPlayerList.bind(player))
	originalPlayerCount = playerList.size()
	waveTimer = AddTimer(npc, waveDelay, TimeoutWave)
	NextWave()

func NextWave():
	waveCount += 1
	if waveCount > maxWave:
		Reward()
	else:
		Notification("Wave %d." % waveCount)
		SpawnMonsters()
		waveMaxMonsters = AliveMonsterCount()
		DisplayTracker("Monsters", 0, waveMaxMonsters)
		waveTimer.start(waveDelay)
		AddTimer(npc, checkDelay, CheckWave, "CheckTimer")

func Reset():
	waveTimer = null
	waveCount = 0
	originalPlayerCount = 0
	waveMaxMonsters = 0

func Reward():
	Notification("Congrats, you won")
	ClearTracker()
	for player : PlayerAgent in playerList:
		NpcCommons.AddExp(player, rewardExp)
		NpcCommons.AddGP(player, rewardGP)
	ClearPlayerList()
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
				Spawn(mob._id, spawnAmount, spawnCenter, spawnRadius)

func CheckWave():
	if not IsTriggering():
		return

	if AlivePlayerCount() == 0:
		OnCancel()
	else:
		var mobCount : int = AliveMonsterCount()
		if mobCount > 0:
			waveMaxMonsters = max(waveMaxMonsters, mobCount)
			DisplayTracker("Monsters", waveMaxMonsters - mobCount, waveMaxMonsters)
			AddTimer(npc, checkDelay, CheckWave, "CheckTimer")
		else:
			NextWave()

func TimeoutWave():
	Notification("You were not able to clear the corruption in time.")
	OnCancel()
