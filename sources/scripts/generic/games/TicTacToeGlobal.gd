extends NpcScript
class_name TicTacToeGlobal

#
static var BOARD_POSITION : Vector2i			= Vector2i(120, 80) * 32 + Vector2i(16, 32) # Tile 120,80 with an offset of 16,32 pixels
static var CELL_ID : int						= "TicTacToeCell".hash()
const CELL_COUNT : int							= 9
const WINNING_LINES : Array[Array]				= [
	[0, 1, 2],
	[3, 4, 5],
	[6, 7, 8],
	[0, 3, 6],
	[1, 4, 7],
	[2, 5, 8],
	[0, 4, 8],
	[2, 4, 6],
]
const IDLE_TIMEOUT : float						= 30.0
const NPC_DELAY_MIN : float						= 0.2
const NPC_DELAY_MAX : float						= 1.0

#
enum State
{
	NONE = 0,
	X,
	O
}

var boardStates : Array[State]					= [
	State.NONE, State.NONE, State.NONE,
	State.NONE, State.NONE, State.NONE,
	State.NONE, State.NONE, State.NONE
]
var boardNpcs : Array[NpcAgent]					= [
	null, null, null,
	null, null, null,
	null, null, null
]

var playerX : PlayerAgent						= null
var playerO : PlayerAgent						= null
var idleTimer : Timer							= null

var startStep : State							= State.NONE
var currentTurn : State							= State.NONE

# Board handling
func SpawnCells():
	var map : WorldMap = WorldAgent.GetMapFromAgent(npc)
	if not map:
		return

	var inst : WorldInstance = WorldAgent.GetInstanceFromAgent(npc)
	if not inst:
		return

	var spawn : SpawnObject = SpawnObject.new()
	spawn.id = CELL_ID
	spawn.type = "Npc"
	spawn.state = ActorCommons.State.IDLE
	spawn.is_persistant = false
	spawn.map = map
	for cellIdx in CELL_COUNT:
		spawn.spawn_position = BOARD_POSITION + Vector2i((cellIdx % 3) * 32, int(cellIdx / 3.0) * 32)
		var spawnedAgent : BaseAgent = WorldAgent.CreateAgent(spawn, inst.id)
		if spawnedAgent and spawnedAgent is NpcAgent:
			boardNpcs[cellIdx] = spawnedAgent
			boardNpcs[cellIdx].interacted.connect(CellSelected.bind(boardNpcs[cellIdx]))

func CellSelected(playerAgent : BaseAgent, cellAgent : NpcAgent):
	if playerAgent is not PlayerAgent:
		return

	if cellAgent:
		var cellIdx : int = boardNpcs.find(cellAgent)
		if cellIdx >= 0:
			MakeMove(playerAgent, cellIdx)

func DespawnCells():
	for cellIdx in CELL_COUNT:
		if boardNpcs[cellIdx]:
			if is_instance_valid(boardNpcs[cellIdx]):
				WorldAgent.RemoveAgent(boardNpcs[cellIdx])
			boardNpcs[cellIdx] = null

func DespawnUnusedCells():
	for cellIdx in CELL_COUNT:
		if boardStates[cellIdx] == State.NONE and boardNpcs[cellIdx] and is_instance_valid(boardNpcs[cellIdx]):
			WorldAgent.RemoveAgent(boardNpcs[cellIdx])
			boardNpcs[cellIdx] = null

# PvP matchmaking
func StartPvP(player : PlayerAgent) -> State:
	if not player or not is_instance_valid(player):
		return State.NONE

	if startStep != State.O:
		if not playerX or not is_instance_valid(playerX) or WorldAgent.GetInstanceFromAgent(playerX) != WorldAgent.GetInstanceFromAgent(player):
			playerX = player
			Callback.AddCallback(playerX.tree_exiting, LeaveQueue, [playerX], ConnectFlags.CONNECT_ONE_SHOT)
			startStep = State.X
			return startStep
		elif not playerO or not is_instance_valid(playerO) or WorldAgent.GetInstanceFromAgent(playerO) != WorldAgent.GetInstanceFromAgent(player):
			playerO = player
			startStep = State.O
			StartGame()
			return startStep
	return State.NONE

func LeavePvP(player : PlayerAgent):
	if not player or not is_instance_valid(player):
		if playerX and is_instance_valid(playerX):
			NpcCommons.PushNotification(playerX, "Your opponent left. You win!")
		elif playerO and is_instance_valid(playerO):
			NpcCommons.PushNotification(playerO, "Your opponent left. You win!")
	elif startStep == State.O and (player == playerX or player == playerO):
		var opponent : PlayerAgent = playerO if player == playerX else playerX
		if opponent and is_instance_valid(opponent):
			NpcCommons.PushNotification(opponent, "Your opponent left. You win!")
	EndGame()

func LeaveQueue(player : PlayerAgent):
	if player and is_instance_valid(player) and  player == playerX:
		EndGame()

# Game management
func StartGame():
	if currentTurn != State.NONE:
		return

	startStep = State.O
	currentTurn = State.X

	DespawnCells()
	SpawnCells()
	StartIdleTimer()

	if playerX:
		Callback.RemoveCallback(playerX.tree_exiting, LeaveQueue)
		Callback.AddCallback(playerX.tree_exiting, LeavePvP, [playerX], ConnectFlags.CONNECT_ONE_SHOT)
		NpcCommons.PushNotification(playerX, "Tic Tac Toe started! You play X!")
	if playerO:
		Callback.AddCallback(playerO.tree_exiting, LeavePvP, [playerO], ConnectFlags.CONNECT_ONE_SHOT)
		NpcCommons.PushNotification(playerO, "Tic Tac Toe started! You play O!")

func StartPvE(player : PlayerAgent) -> bool:
	if startStep == State.NONE:
		playerX = player
		playerO = null
		StartGame()
		return startStep == State.O
	return false

# Move handling
func MakeMove(player : PlayerAgent, cellIndex : int) -> bool:
	if currentTurn == State.NONE or cellIndex < 0 or cellIndex >= CELL_COUNT:
		return false

	var mark : State = boardStates[cellIndex]
	if mark != State.NONE:
		return false

	if player == playerX and currentTurn == State.X:
		mark = State.X
	elif player == playerO and currentTurn == State.O:
		mark = State.O
	else:
		return false

	boardStates[cellIndex] = mark

	UpdateCellVisual(cellIndex)
	currentTurn = State.X if currentTurn == State.O else State.O
	OnMovePlayed()
	StartIdleTimer()
	return true

func OnMovePlayed():
	if startStep != State.O:
		return

	var result : State = CheckWin()
	if result != State.NONE or CheckDraw():
		AnnounceResult(result)
	elif not playerO:
		NotifyTurn()
		var delay : float = randf_range(NPC_DELAY_MIN, NPC_DELAY_MAX)
		Callback.SelfDestructTimer(npc, delay, PlayNPCMove)
	else:
		NotifyTurn()

func PlayNPCMove():
	if currentTurn != State.O or playerO:
		return

	var npcMove : int = GetNPCMove()
	if npcMove >= 0:
		MakeMove(null, npcMove)

func NotifyTurn():
	if currentTurn == State.NONE:
		return

	if playerO:
		var activePlayer : PlayerAgent = playerX if currentTurn == State.X else playerO
		var waitingPlayer : PlayerAgent = playerO if currentTurn == State.X else playerX
		if activePlayer and is_instance_valid(activePlayer):
			NpcCommons.PushNotification(activePlayer, "Your turn!")
		if waitingPlayer and is_instance_valid(waitingPlayer):
			NpcCommons.PushNotification(waitingPlayer, "Waiting for opponent...")
	else:
		if currentTurn == State.X:
			if playerX and is_instance_valid(playerX):
				NpcCommons.PushNotification(playerX, "Your turn!")
		else:
			if playerX and is_instance_valid(playerX):
				NpcCommons.PushNotification(playerX, "Waiting for opponent...")

func UpdateCellVisual(cellIndex : int):
	if cellIndex < 0 or cellIndex >= CELL_COUNT:
		return

	var cellNpc : NpcAgent = boardNpcs[cellIndex]
	if not cellNpc or not is_instance_valid(cellNpc):
		return

	match boardStates[cellIndex]:
		State.NONE:
			cellNpc.state = ActorCommons.State.IDLE
		State.X:
			cellNpc.state = ActorCommons.State.TRIGGER
			if cellNpc.interacted.is_connected(CellSelected):
				cellNpc.interacted.disconnect(CellSelected)
		State.O:
			cellNpc.state = ActorCommons.State.SIT
			if cellNpc.interacted.is_connected(CellSelected):
				cellNpc.interacted.disconnect(CellSelected)
	cellNpc.set_physics_process(true)
	cellNpc.requireFullUpdate = true

# Idle timer
func StartIdleTimer():
	StopIdleTimer()
	idleTimer = Callback.SelfDestructTimer(npc, IDLE_TIMEOUT, IdleTimeout)

func StopIdleTimer():
	if idleTimer and is_instance_valid(idleTimer) and not idleTimer.is_queued_for_deletion():
		idleTimer.stop()
		idleTimer.queue_free()
	idleTimer = null

func IdleTimeout():
	idleTimer = null
	if currentTurn == State.NONE:
		return

	var loser : State = currentTurn
	var winner : State = State.X if loser == State.O else State.O

	var loserPlayer : PlayerAgent = playerX if loser == State.X else playerO
	if loserPlayer and is_instance_valid(loserPlayer):
		NpcCommons.PushNotification(loserPlayer, "You took too long! You lose.")

	AnnounceResult(winner)

# Game end
func EndGame():
	StopIdleTimer()
	ClearPlayerCallbacks()
	DespawnUnusedCells()
	ResetBoard()

func ClearPlayerCallbacks():
	if playerX and is_instance_valid(playerX):
		Callback.RemoveCallback(playerX.tree_exiting, LeavePvP)
	if playerO and is_instance_valid(playerO):
		Callback.RemoveCallback(playerO.tree_exiting, LeavePvP)

func ResetBoard():
	playerX = null
	playerO = null
	startStep = State.NONE
	currentTurn = State.NONE
	for cellIdx in CELL_COUNT:
		boardStates[cellIdx] = State.NONE

# Win detection
func CheckWin() -> State:
	for line in WINNING_LINES:
		var state : State = boardStates[line[0]]
		if state != State.NONE and state == boardStates[line[1]] and state == boardStates[line[2]]:
			return state
	return State.NONE

func CheckDraw() -> bool:
	for cell in boardStates:
		if cell == State.NONE:
			return false
	return true

func AnnounceResult(result : State):
	var msg : String = ""
	match result:
		State.NONE:
			msg = "It's a draw!"
		State.X:
			msg = "%s wins!" % (playerX.nick if playerX else "X")
		State.O:
			msg = "%s wins!" % (playerO.nick if playerO else npc.nick)

	if playerX and is_instance_valid(playerX):
		NpcCommons.PushNotification(playerX, msg)
	if playerO and is_instance_valid(playerO):
		NpcCommons.PushNotification(playerO, msg)
	EndGame()

# NPC AI
func GetNPCMove() -> int:
	var winMove : int = FindWinningMove(State.O)
	if winMove >= 0:
		return winMove

	var blockMove : int = FindWinningMove(State.X)
	if blockMove >= 0:
		return blockMove

	if boardStates[4] == State.NONE:
		return 4

	var corners : Array[int] = [0, 2, 6, 8]
	corners.shuffle()
	for corner in corners:
		if boardStates[corner] == State.NONE:
			return corner

	var edges : Array[int] = [1, 3, 5, 7]
	edges.shuffle()
	for edge in edges:
		if boardStates[edge] == State.NONE:
			return edge

	return -1

func FindWinningMove(state : State) -> int:
	for line : Array in WINNING_LINES:
		var totalPointInLine : int = 0
		var firstEmptyIdx : int = -1

		for idx : int in line:
			if boardStates[idx] == state:
				totalPointInLine += 1
			elif boardStates[idx] == State.NONE:
				firstEmptyIdx = idx

		# Winning move found if 2 out of 3 point in a line are already matching the given state and if an empty index is available
		if totalPointInLine == 2 and firstEmptyIdx >= 0:
			return firstEmptyIdx
	return -1
