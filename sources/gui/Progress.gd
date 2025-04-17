extends WindowPanel

# Control accessors
@onready var activeQuestContainer : Container		= $Margin/TabBar/QuestLog/QuestScroll/QuestList/Active
@onready var completedQuestContainer : Container	= $Margin/TabBar/QuestLog/QuestScroll/QuestList/Completed
@onready var questSeparator : Separator				= $Margin/TabBar/QuestLog/QuestScroll/QuestList/HSeparator
@onready var questDescription : RichTextLabel		= $Margin/TabBar/QuestLog/Description

# Quest variables
var quests : Dictionary[int, MenuLine]				= {}
var activeQuests : Dictionary[int, bool]			= {}
var completedQuests : Dictionary[int, bool]			= {}
var currentQuest : int								= DB.UnknownHash

# Bestiary variables
var bestiaries : Dictionary[int, MenuLine]			= {}

# Common progress functions
func Clear():
	for questID in activeQuests.keys():
		activeQuestContainer.remove_child.call_deferred(quests[questID])
	activeQuests.clear()
	for questID in completedQuests.keys():
		completedQuestContainer.remove_child.call_deferred(quests[questID])
	completedQuests.clear()
	quests.clear()
	questSeparator.set_visible(false)
	questDescription.set_text("")
	currentQuest = DB.UnknownHash

	bestiaries.clear()

# Bestiary
func RefreshBestiary(_mobID : int, _state : int):
	pass

# Quest Log
func RefreshQuest(questID : int, state : int):
	var isComplete : bool = state == ProgressCommons.CompletedProgress
	var menuLine : MenuLine = quests.get(questID)

	if not menuLine:
		var questData : QuestData = DB.GetQuest(questID)
		if not questData:
			return
		menuLine = MenuLine.new(questID, questData.name)
		menuLine.set_pressed(true)
		menuLine.line_selected.connect(RefreshQuestDescription)
		quests[questID] = menuLine

	if isComplete:
		if activeQuests.get(questID, false):
			activeQuestContainer.remove_child.call_deferred(menuLine)
			activeQuests.erase(questID)
		if not completedQuests.get(questID, false):
			completedQuestContainer.add_child.call_deferred(menuLine)
			completedQuests[questID] = true
	else:
		if completedQuests.get(questID, false):
			completedQuestContainer.remove_child.call_deferred(menuLine)
			completedQuests.erase(questID)
		if not activeQuests.get(questID, false):
			activeQuestContainer.add_child.call_deferred(menuLine)
			activeQuests[questID] = true

	questSeparator.set_visible(not activeQuests.is_empty() and not completedQuests.is_empty())
	menuLine.Enable(not isComplete)

	if currentQuest == DB.UnknownHash:
		RefreshQuestDescription(questID)

func RefreshQuestDescription(questID : int):
	if questID == currentQuest:
		return

	currentQuest = questID
	questDescription.text = "\n"

	var questData : QuestData = DB.GetQuest(questID)
	if not questData:
		return

	if not questData.description.is_empty():
		questDescription.text += "Description:\n[color=#%s]%s[/color]\n\n" % [UICommons.TextColor.to_html(false), questData.description]
	if not questData.giver.is_empty():
		questDescription.text += "Giver:\n[color=#%s]%s" % [UICommons.WarnTextColor.to_html(false), questData.giver]
		if not questData.giverLocation.is_empty():
			questDescription.text += " (%s)" % questData.giverLocation
		questDescription.text += "[/color]\n\n"
	if not questData.target.is_empty():
		questDescription.text += "Target:\n[color=#%s]%s" % [UICommons.WarnTextColor.to_html(false), questData.target]
		if not questData.targetLocation.is_empty():
			questDescription.text += " (%s)" % questData.targetLocation
		questDescription.text += "[/color]\n\n"
	if not questData.reward.is_empty():
		questDescription.text += "Reward:\n[color=#%s]%s[/color]\n\n" % [UICommons.WarnTextColor.to_html(false), questData.reward]
