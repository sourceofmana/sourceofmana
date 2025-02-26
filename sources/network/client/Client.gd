extends Object

#
func WarpPlayer(map : String, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		Launcher.Map.EmplaceMapNode(map)
		PushNotification(map, _rpcID)

	if Launcher.Player:
		Launcher.Player.entityVelocity = Vector2.ZERO

func EmotePlayer(playerID : int, emoteID : int, _rpcID : int = NetworkCommons.RidSingleMode):
	var entity : Entity = Entities.Get(playerID)
	if entity && entity.get_parent() && entity.interactive:
		entity.interactive.DisplayEmote.call_deferred(emoteID)

func AddEntity(agentID : int, entityType : ActorCommons.Type, entityID : String, nick : String, velocity : Vector2, position : Vector2i, orientation : Vector2, state : ActorCommons.State, skillCastID : int, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		Launcher.Map.AddEntity(agentID, entityType, entityID, nick, velocity, position, orientation, state, skillCastID)

func RemoveEntity(agentID : int, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		Launcher.Map.RemoveEntity(agentID)

func ForceUpdateEntity(ridAgent : int, velocity : Vector2, position : Vector2, orientation : Vector2, state : ActorCommons.State, skillCastID : int):
	if Launcher.Map:
		Launcher.Map.UpdateEntity(ridAgent, velocity, position, orientation, state, skillCastID)

func UpdateEntity(ridAgent : int, velocity : Vector2, position : Vector2, orientation : Vector2, state : ActorCommons.State, skillCastID : int):
	if Launcher.Map:
		Launcher.Map.UpdateEntity(ridAgent, velocity, position, orientation, state, skillCastID)

func ChatAgent(ridAgent : int, text : String, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		var entity : Entity = Entities.Get(ridAgent)
		if entity && entity.get_parent():
			if entity.type == ActorCommons.Type.PLAYER && Launcher.GUI:
				Launcher.GUI.chatContainer.AddPlayerText(entity.nick, text)
			if entity.interactive:
				entity.interactive.DisplaySpeech.call_deferred(text)

func ToggleContext(enable : bool, _rpcID : int = NetworkCommons.RidSingleMode):
	Launcher.GUI.dialogueWindow.Toggle(enable)

func ContextText(author : String, text : String, _rpcID : int = NetworkCommons.RidSingleMode):
	if not author.is_empty():
		Launcher.GUI.dialogueWindow.AddName(author)
	Launcher.GUI.dialogueWindow.AddDialogue(text)
	Launcher.GUI.dialogueWindow.ToggleButton(false, "")

func ContextContinue(_rpcID : int = NetworkCommons.RidSingleMode):
	Launcher.GUI.dialogueWindow.ToggleButton(true, "Next")

func ContextClose(_rpcID : int = NetworkCommons.RidSingleMode):
	Launcher.GUI.dialogueWindow.ToggleButton(true, "Close")

func ContextChoice(texts : PackedStringArray, _rpcID : int = NetworkCommons.RidSingleMode):
	Launcher.GUI.dialogueWindow.AddChoices(texts)

func TargetAlteration(ridAgent : int, targetID : int, value : int, alteration : ActorCommons.Alteration, skillID : int, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		var entity : Entity = Entities.Get(targetID)
		var caller : Entity = Entities.Get(ridAgent)
		if caller && entity && entity.get_parent() and entity.interactive:
			entity.interactive.DisplayAlteration.call_deferred(entity, caller, value, alteration, skillID)

func Casted(agentID : int, skillID : int, cooldown : float, _rpcID : int = NetworkCommons.RidSingleMode):
	var entity : Entity = Entities.Get(agentID)
	if entity and entity.get_parent() and entity.interactive:
		entity.interactive.DisplaySkill.call_deferred(entity, skillID, cooldown)

func Morphed(ridAgent : int, morphID : String, morphed : bool, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		var entity : Entity = Entities.Get(ridAgent)
		if entity:
			var morphData : EntityData = Instantiate.FindEntityReference(morphID)
			entity.stat.Morph(morphData)
			entity.SetVisual(morphData, morphed)

func UpdatePrivateStats(ridAgent : int, experience : int, gp : int, mana : int, stamina : int, karma : int, weight : float, shape : String, spirit : String, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		var entity : Entity = Entities.Get(ridAgent)
		if entity and entity.stat:
			entity.stat.experience		= experience
			entity.stat.gp				= gp
			entity.stat.mana			= mana
			entity.stat.stamina			= stamina
			entity.stat.karma			= karma
			entity.stat.weight			= weight
			entity.stat.shape			= shape
			entity.stat.spirit			= spirit
			entity.stat.RefreshVitalStats()

func UpdatePublicStats(ridAgent : int, level : int, health : int, hairstyle : int, haircolor : int, gender : ActorCommons.Gender, race : int, skintone : int, currentShape : String, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		var entity : Entity = Entities.Get(ridAgent)
		if entity and entity.stat:
			entity.stat.level			= level
			entity.stat.health			= health
			entity.stat.currentShape	= currentShape

			var newHair : bool = entity.stat.hairstyle != hairstyle or entity.stat.haircolor != haircolor
			entity.stat.hairstyle		= hairstyle
			entity.stat.haircolor		= haircolor
			if newHair and entity.visual:
				entity.visual.SetHair()

			var newBody : bool = entity.stat.gender != gender or entity.stat.race != race or entity.stat.skintone != skintone
			entity.stat.gender			= gender
			entity.stat.race			= race
			entity.stat.skintone		= skintone
			if newBody and entity.visual:
				entity.visual.SetBody()
				entity.visual.SetFace()

			entity.stat.RefreshVitalStats()

func UpdateAttributes(ridAgent : int, strength : int, vitality : int, agility : int, endurance : int, concentration : int, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		var entity : Entity = Entities.Get(ridAgent)
		if entity and entity.get_parent() and entity.stat:
			entity.stat.strength		= strength
			entity.stat.vitality		= vitality
			entity.stat.agility			= agility
			entity.stat.endurance		= endurance
			entity.stat.concentration	= concentration
			entity.stat.RefreshAttributes()

func LevelUp(ridAgent : int, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		var entity : Entity = Entities.Get(ridAgent)
		if entity and entity.get_parent() and entity.stat:
			entity.LevelUp()

func ItemAdded(itemID : int, customfield : String, count : int, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Player:
		var cell : BaseCell = DB.GetItem(itemID, customfield)
		if cell and Launcher.Player.inventory.PushItem(cell, count):
			if Launcher.GUI:
				Launcher.GUI.pickupPanel.AddLast(cell, count)
				Launcher.GUI.inventoryWindow.RefreshInventory()
			cell.used.emit()

func ItemRemoved(itemID : int, customfield : String, count : int, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Player:
		var cell : BaseCell = DB.GetItem(itemID, customfield)
		if cell:
			Launcher.Player.inventory.PopItem(cell, count)
			CellTile.RefreshShortcuts(cell)
			if Launcher.GUI and Launcher.GUI.inventoryWindow:
				Launcher.GUI.inventoryWindow.RefreshInventory()
			cell.used.emit()

func ItemEquiped(ridAgent : int, itemID : int, customfield : String, state : bool, _rpcID : int = NetworkCommons.RidSingleMode):
	var entity : Entity = Entities.Get(ridAgent)
	if entity:
		var cell : ItemCell = DB.GetItem(itemID, customfield)
		if cell:
			if state:
				entity.inventory.EquipItem(cell)
			else:
				entity.inventory.UnequipItem(cell)

			entity.visual.SetEquipment(cell.slot)
			if entity == Launcher.Player:
				Launcher.GUI.inventoryWindow.RefreshInventory()
				cell.used.emit()

func RefreshInventory(cells : Array[Dictionary], _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Player and Launcher.Player.inventory:
		Launcher.Player.inventory.ImportInventory(cells)
	if Launcher.GUI and Launcher.GUI.inventoryWindow:
		Launcher.GUI.inventoryWindow.RefreshInventory()

func RefreshEquipments(ridAgent : int, equipments : Dictionary, _rpcID : int = NetworkCommons.RidSingleMode):
	var entity : Entity = Entities.Get(ridAgent)
	if entity:
		if entity.inventory:
			entity.inventory.ImportEquipment(equipments)
		if entity == Launcher.Player and Launcher.GUI and Launcher.GUI.inventoryWindow:
			Launcher.GUI.inventoryWindow.RefreshInventory()

func DropAdded(dropID : int, itemID : int, customfield : String, pos : Vector2, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		Launcher.Map.AddDrop(dropID, DB.GetItem(itemID, customfield), pos)

func DropRemoved(dropID : int, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Map:
		Launcher.Map.RemoveDrop(dropID)

#
func PushNotification(notif : String, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.GUI:
		Launcher.GUI.notificationLabel.AddNotification(notif)

#
func AuthError(err : NetworkCommons.AuthError, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.GUI:
		Launcher.GUI.loginPanel.FillWarningLabel(err)

func CharacterError(err : NetworkCommons.AuthError, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.GUI:
		Launcher.GUI.characterPanel.FillWarningLabel(err)

func CharacterInfo(info : Dictionary, equipment : Dictionary, _rpcID : int = NetworkCommons.RidSingleMode):
	Launcher.GUI.characterPanel.AddCharacter(info, equipment)

# Progress
func UpdateSkill(skillID : int, level : int, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Player:
		var skill : SkillCell = DB.GetSkill(skillID)
		if skill:
			Launcher.Player.progress.AddSkill(skill, 1.0, level)
			if Launcher.GUI and Launcher.GUI.skillWindow:
				Launcher.GUI.skillWindow.RefreshSkills()

func UpdateBestiary(mobID : int, count : int, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Player:
		Launcher.Player.progress.AddBestiary(mobID, count)
		if Launcher.GUI and Launcher.GUI.progressWindow:
			Launcher.GUI.progressWindow.RefreshBestiary(mobID)

func UpdateQuest(questID : int, state : int, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Player:
		Launcher.Player.progress.SetQuest(questID, state)
		if Launcher.GUI and Launcher.GUI.progressWindow:
			Launcher.GUI.progressWindow.RefreshQuest(questID)

func RefreshProgress(skills : Dictionary, quests : Dictionary, bestiary : Dictionary, _rpcID : int = NetworkCommons.RidSingleMode):
	if Launcher.Player:
		for skill in skills:
			UpdateSkill(skill, skills[skill].level)
		for quest in quests:
			UpdateQuest(quest, quests[quest])
		for mob in bestiary:
			UpdateBestiary(mob, bestiary[mob])

#
func ConnectServer():
	if Launcher.GUI and Launcher.GUI.loginPanel:
		Launcher.GUI.loginPanel.EnableButtons.call_deferred(true)

func DisconnectServer():
	Launcher.Mode(true, true)
	FSM.EnterState(FSM.States.LOGIN_SCREEN)
	AuthError(NetworkCommons.AuthError.ERR_SERVER_UNREACHABLE)

#
func Init():
	if not Launcher.Root.multiplayer.connected_to_server.is_connected(ConnectServer):
		Launcher.Root.multiplayer.connected_to_server.connect(ConnectServer)
	if not Launcher.Root.multiplayer.connection_failed.is_connected(DisconnectServer):
		Launcher.Root.multiplayer.connection_failed.connect(DisconnectServer)
	if not Launcher.Root.multiplayer.server_disconnected.is_connected(DisconnectServer):
		Launcher.Root.multiplayer.server_disconnected.connect(DisconnectServer)

func Destroy():
	if Launcher.Root.multiplayer.connected_to_server.is_connected(ConnectServer):
		Launcher.Root.multiplayer.connected_to_server.disconnect(ConnectServer)
	if Launcher.Root.multiplayer.connection_failed.is_connected(DisconnectServer):
		Launcher.Root.multiplayer.connection_failed.disconnect(DisconnectServer)
	if Launcher.Root.multiplayer.server_disconnected.is_connected(DisconnectServer):
		Launcher.Root.multiplayer.server_disconnected.disconnect(DisconnectServer)
