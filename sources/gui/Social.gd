extends WindowPanel
class_name Social

#
@onready var playerList : VBoxContainer			= $Layout/Margin/TabBar/Online/Scroll/PlayerList
@onready var onlineCount : Label				= $Layout/Margin/TabBar/Online/OnlineCount

#
func UpdateCount() -> void:
	var count : int = playerList.get_child_count()
	onlineCount.text = str(count) + " player" + ("s" if count != 1 else "") + " online"

func AddPlayerLine(playerName : String) -> void:
	var line : PlayerLine = PlayerLine.new(playerName)
	line.line_selected.connect(OnPlayerSelected)
	playerList.add_child(line)

func OnPlayerSelected(playerName : String) -> void:
	if Launcher.Player and playerName != Launcher.Player.nick:
		Network.TriggerCommand("query " + playerName)

func RefreshOnline(players : PackedStringArray) -> void:
	for child in playerList.get_children():
		child.free()
	for playerName in players:
		AddPlayerLine(playerName)
	UpdateCount()

func AddOnlinePlayer(playerName : String) -> void:
	if not playerList.has_node(playerName):
		AddPlayerLine(playerName)
		UpdateCount()

func RemoveOnlinePlayer(playerName : String) -> void:
	var line : Node = playerList.get_node_or_null(playerName)
	if line:
		line.free()
		UpdateCount()

#
func _ready():
	FSM.enter_game.connect(Network.RequestOnlineList)
