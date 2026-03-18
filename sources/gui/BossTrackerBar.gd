extends TrackerBar

#
var currentBossRID : int = DB.UnknownHash

# Accessors
func OnStatsUpdated(agentRID : int):
	var entity : Entity = Entities.Get(agentRID)
	if not entity:
		return

	if currentBossRID == DB.UnknownHash:
		ConnectBoss(entity)
	elif currentBossRID == entity.agentRID:
		pass
	elif Launcher.Player.target and agentRID == Launcher.Player.target.agentRID:
		if currentBossRID != Launcher.Player.target.agentRID:
			DisconnectBoss(currentBossRID)
			ConnectBoss(entity)
	else:
		return

	if entity.stat.health <= 0:
		OnHide(currentBossRID)
	else:
		bar.SetStat(entity.stat.health, entity.stat.current.maxHealth)

func OnHide(agentRID : int):
	if currentBossRID != agentRID:
		return
	DisconnectBoss(agentRID)
	Clear()

# Boss handling
func ConnectBoss(entity : Entity):
	currentBossRID = entity.agentRID
	entity.tree_exiting.connect(OnHide.bind(currentBossRID), CONNECT_ONE_SHOT)
	Display(entity.nick, entity.stat.health, entity.stat.current.maxHealth)

func DisconnectBoss(agentRID : int):
	if currentBossRID != agentRID:
		return

	var entity : Entity = Entities.Get(agentRID)
	if entity:
		var callable : Callable = OnHide.bind(currentBossRID)
		if entity.tree_exiting.is_connected(callable):
			entity.tree_exiting.disconnect(callable)

	currentBossRID = DB.UnknownHash
