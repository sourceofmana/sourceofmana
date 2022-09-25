extends Node

#
var emoteSprite : Sprite2D			= null
var emoteDelay : float				= 5.0

var currentEmoteTimer : float			= 0.0
var currentEmoteID : int				= -1

#
func RemoveEmoteResource():
	if emoteSprite.get_texture() != null:
		emoteSprite.texture = null

func AddEmoteResource(emoteID : int):
	var emoteStringID : String = str(emoteID)
	if Launcher.DB.EmotesDB && Launcher.DB.EmotesDB[emoteStringID]:
		var emoteIcon : Resource = Launcher.FileSystem.LoadGfx(Launcher.DB.EmotesDB[emoteStringID]._path)
		if emoteIcon:
			emoteSprite.set_texture(emoteIcon)

func DisplayEmote(emoteID : int):
	if currentEmoteID != emoteID:
		RemoveEmoteResource()
		AddEmoteResource(emoteID)
	currentEmoteTimer = Launcher.Conf.GetFloat("Gameplay", "emoteDelay", Launcher.Conf.Type.PROJECT)

func UpdateEmoteDelay(dt : float):
	currentEmoteTimer = clampf(currentEmoteTimer - dt, 0.0, emoteDelay)
	if is_zero_approx(currentEmoteTimer):
		RemoveEmoteResource()

func UpdateInteractiveActions():
	if Input.is_action_just_pressed(Actions.ACTION_IM_3): DisplayEmote(3)
	if Input.is_action_just_pressed(Actions.ACTION_IM_5): DisplayEmote(5)
	if Input.is_action_just_pressed(Actions.ACTION_IM_12): DisplayEmote(12)
	if Input.is_action_just_pressed(Actions.ACTION_IM_21): DisplayEmote(21)
	if Input.is_action_just_pressed(Actions.ACTION_IM_22): DisplayEmote(22)
	if Input.is_action_just_pressed(Actions.ACTION_IM_26): DisplayEmote(26)

func Update(dt : float):
	if emoteSprite == null:
		InitSprite()
	UpdateEmoteDelay(dt)
	UpdateInteractiveActions()

func EmoteWindowClicked(selectedEmote : String):
	DisplayEmote(selectedEmote.to_int())

func InitSprite():
	if Launcher.Entities && Launcher.Entities.activePlayer:
		emoteSprite = Launcher.Entities.activePlayer.get_node("Emote")
	if Launcher.GUI && Launcher.GUI.emoteList:
		Launcher.GUI.emoteList.ItemClicked.connect(EmoteWindowClicked)
