extends Node

var Text = ""
var Delay = 5.0
var Timer = 0.0


func OnDisplay(text):
	Text = text
	StartTimer()

func StartTimer():
	Timer = Delay

func _process(delta):
	Timer -= delta
	if Timer < 0.0:
		Timer = 0.0
		Text = ""
	print(Text)
