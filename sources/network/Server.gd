extends Node

const SERVER_LOCAL_IP = "127.0.0.1"
const SERVER_PORT = 6903

var network = NetworkedMultiplayerENet.new()

func _ready():
	ConnectToServer()

func ConnectToServer():
	network.create_client(SERVER_LOCAL_IP, SERVER_PORT)
	get_tree().set_network_peer(network)

	network.connect("connection_failed", self, "_OnConnectionFailed")
	network.connect("connection_succeeded", self, "_OnConnectionSucceeded")

func _OnConnectionFailed():
	print("Connection failed")

func _OnConnectionSucceeded():
	print("Connection succeeded")

func FetchInventoryList(category, requester):
	rpc_id(1, "FetchInventoryList", category, requester)

remote func ReturnInventoryList(s_inventoryList, requester):
	instance_from_id(requester).ReturnInventoryList(s_inventoryList)
