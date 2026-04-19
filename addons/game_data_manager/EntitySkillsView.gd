@tool
extends Control

var resources : Array[Resource] = []
var filteredResources : Array[Resource] = []
var selectedEntity : Resource = null
var skillCache : Dictionary = {}

@onready var entityList : ItemList = $VBoxContainer/HSplitContainer/EntityList
@onready var searchField : LineEdit = $VBoxContainer/TopBar/SearchField
@onready var entityLabel : Label = $VBoxContainer/HSplitContainer/SkillsPanel/VBoxContainer/TopBar/EntityLabel
@onready var skillsContainer : VBoxContainer = $VBoxContainer/HSplitContainer/SkillsPanel/VBoxContainer/ScrollContainer/SkillsContainer

func _ready():
	if not GameDataUtil.is_part_of_edited_scene(self):
		LoadResources()
		RefreshEntityList()

func LoadResources():
	resources.clear()
	skillCache.clear()

	if DirAccess.dir_exists_absolute(Path.EntityPst):
		for resourcePath in FileSystem.ParseResources(Path.EntityPst):
			var loadedResource : Resource = FileSystem.LoadResource(resourcePath, false)
			if loadedResource is EntityData:
				var entity : EntityData = loadedResource as EntityData
				resources.push_back(entity)

	if DirAccess.dir_exists_absolute(Path.SkillPst):
		for resourcePath in FileSystem.ParseResources(Path.SkillPst):
			var cell : SkillCell = FileSystem.LoadResource(resourcePath, false)
			if cell and cell.name:
				skillCache[cell.name.hash()] = cell

func RefreshEntityList():
	ApplyFilter()
	PopulateEntityList()

func ApplyFilter():
	var query : String = searchField.text.to_lower()

	if query.is_empty():
		filteredResources = resources.duplicate()
	else:
		filteredResources.clear()
		for resource in resources:
			if resource.get("_name") and str(resource._name).to_lower().contains(query):
				filteredResources.push_back(resource)

func PopulateEntityList():
	entityList.clear()
	for resource in filteredResources:
		entityList.add_item(resource._name if resource.get("_name") else "Unnamed")
		var idx : int = entityList.item_count - 1
		entityList.set_item_metadata(idx, resource)
		var skills : Dictionary = resource.get("_skills")
		if not skills or skills.is_empty():
			entityList.set_item_custom_fg_color(idx, Color.LIGHT_SLATE_GRAY)

func _on_entity_selected(index : int):
	selectedEntity = entityList.get_item_metadata(index)
	if selectedEntity:
		entityLabel.text = selectedEntity._name + " - Skills"
		RefreshSkillsDisplay()

func RefreshSkillsDisplay():
	for child in skillsContainer.get_children():
		child.queue_free()

	if not selectedEntity:
		return

	var skills : Dictionary = selectedEntity.get("_skills")

	if not skills or skills.is_empty():
		var noSkillsLabel : Label = Label.new()
		noSkillsLabel.text = "No skills configured. Click 'Add Skill' to add one."
		skillsContainer.add_child(noSkillsLabel)
		return

	var index : int = 0
	for skillCell : SkillCell in skills:
		CreateSkillWidget(skillCell, skills[skillCell], index)
		index += 1

func CreateSkillWidget(skillCell : SkillCell, probability : float, index : int):
	var hbox : HBoxContainer = HBoxContainer.new()

	var iconRect : TextureRect = TextureRect.new()
	iconRect.custom_minimum_size = Vector2(32, 32)
	iconRect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	iconRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if skillCell and skillCell.icon:
		iconRect.texture = skillCell.icon

	hbox.add_child(iconRect)

	var skillNameEdit : LineEdit = LineEdit.new()
	skillNameEdit.custom_minimum_size = Vector2(150, 0)
	skillNameEdit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skillNameEdit.text = skillCell.name if skillCell else ""
	skillNameEdit.placeholder_text = "Skill name"
	skillNameEdit.text_submitted.connect(_on_skill_name_changed.bind(skillCell))
	hbox.add_child(skillNameEdit)

	var probLabel : Label = Label.new()
	probLabel.text = "Probability:"
	hbox.add_child(probLabel)

	var probSpin : SpinBox = SpinBox.new()
	probSpin.min_value = 0
	probSpin.max_value = 100
	probSpin.step = 0.1
	probSpin.value = probability * 100.0
	probSpin.suffix = "%"
	probSpin.custom_minimum_size = Vector2(100, 0)
	probSpin.value_changed.connect(_on_skill_probability_changed.bind(skillCell))
	hbox.add_child(probSpin)

	var deleteBtn : Button = Button.new()
	deleteBtn.text = "X"
	deleteBtn.pressed.connect(_on_delete_skill_pressed.bind(skillCell))
	hbox.add_child(deleteBtn)

	skillsContainer.add_child(hbox)

func _on_skill_name_changed(newName : String, oldCell : SkillCell):
	if not selectedEntity:
		return

	var skills : Dictionary = selectedEntity.get("_skills")
	if not skills:
		return

	var newCell : SkillCell = FindSkillByName(newName)
	if newCell and skills.has(oldCell):
		var oldProb : float = skills[oldCell]
		skills.erase(oldCell)
		skills[newCell] = oldProb
		SaveEntity()
		RefreshSkillsDisplay()

func _on_skill_probability_changed(newValue : float, skillCell : SkillCell):
	if not selectedEntity:
		return

	var skills : Dictionary = selectedEntity.get("_skills")
	if not skills or not skills.has(skillCell):
		return

	skills[skillCell] = newValue / 100.0
	SaveEntity()

func _on_delete_skill_pressed(skillCell : SkillCell):
	if not selectedEntity:
		return

	var skills : Dictionary = selectedEntity.get("_skills")
	if not skills or not skills.has(skillCell):
		return

	skills.erase(skillCell)
	SaveEntity()
	RefreshSkillsDisplay()

func _on_add_skill_pressed():
	if not selectedEntity:
		return

	var skills : Dictionary = selectedEntity.get("_skills")
	if not skills:
		skills = {}
		selectedEntity.set("_skills", skills)

	var emptyCell : SkillCell = SkillCell.new()
	skills[emptyCell] = 1.0
	SaveEntity()
	RefreshSkillsDisplay()

func FindSkillByName(skillName : String) -> SkillCell:
	for skillCell : SkillCell in skillCache.values():
		if skillCell.name.to_lower() == skillName.to_lower():
			return skillCell
	return null

func SaveEntity():
	if not selectedEntity:
		return
	GameDataUtil.SaveResource(selectedEntity)

func _on_search_changed(_newText : String):
	RefreshEntityList()

func _on_refresh_pressed():
	LoadResources()
	RefreshEntityList()
	if selectedEntity:
		RefreshSkillsDisplay()
