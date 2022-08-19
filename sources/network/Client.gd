extends Node

const SERVER_LOCAL_IP = "127.0.0.1"
const SERVER_PORT = 6903

var client = WebSocketClient.new()

#
func _ready():
	client.connection_closed.connect(connectionClosed)
	client.connection_error.connect(connectionError)
	client.connection_established.connect(connectionEstablished)
	client.data_received.connect(dataReceived)

	var err = client.connect_to_url(SERVER_LOCAL_IP, ["lws-mirror-protocol"])
	if err != OK:
		print("Unable to connect")
		set_process(false)

#
func connectionClosed(clean : bool = false):
	print("Connection closed: " + "Clean" if clean else "")
	set_process(false)

func connectionError():
	print("Connection error")
	set_process(false)

func connectionEstablished(protocol : String = ""):
	print("Connection established with protocol: " + protocol)
	client.get_peer(1).put_packet("Test packet".to_utf8_buffer())

func dataReceived():
	print("Data received: " + client.get_peer(1).get_packet().get_string_from_utf8())

#
func _process(delta):
	client.poll()
