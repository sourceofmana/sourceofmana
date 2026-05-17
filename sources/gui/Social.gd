extends WindowPanel
class_name Social

#
@onready var playerList : VBoxContainer			= $Margin/TabBar/Online/Scroll/PlayerList
@onready var onlineCount : Label				= $Margin/TabBar/Online/OnlineCount

#
func UpdateCount() -> void:
	var count : int = playerList.get_child_count()
	onlineCount.text = str(count) + " player" + ("s" if count != 1 else "") + " online"

func RefreshOnline(players : PackedStringArray) -> void:
	for child in playerList.get_children():
		child.free()
	for playerName in players:
		playerList.add_child(PlayerLine.new(playerName))
	UpdateCount()

func AddOnlinePlayer(playerName : String) -> void:
	if not playerList.has_node(playerName):
		playerList.add_child(PlayerLine.new(playerName))
		UpdateCount()

func RemoveOnlinePlayer(playerName : String) -> void:
	var line : Node = playerList.get_node_or_null(playerName)
	if line:
		line.free()
		UpdateCount()

#
func _ready():
	FSM.enter_game.connect(Network.RequestOnlineList)
