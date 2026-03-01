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
		var skillsArray : PackedInt64Array = resource.get("_skillSet")
		if not skillsArray or skillsArray.is_empty():
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

	var skillsArray : PackedInt64Array = selectedEntity.get("_skillSet")
	var skillsProba : Dictionary = selectedEntity.get("_skillProba")

	if not skillsArray or skillsArray.is_empty():
		var noSkillsLabel : Label = Label.new()
		noSkillsLabel.text = "No skills configured. Click 'Add Skill' to add one."
		skillsContainer.add_child(noSkillsLabel)
		return

	for i in skillsArray.size():
		var skillId : int = skillsArray[i]
		var probability : float = skillsProba.get(skillId, 100.0) if skillsProba else 100.0
		CreateSkillWidget(skillId, probability, i)

func CreateSkillWidget(skillId : int, probability : float, index : int):
	var hbox : HBoxContainer = HBoxContainer.new()

	var iconRect : TextureRect = TextureRect.new()
	iconRect.custom_minimum_size = Vector2(32, 32)
	iconRect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	iconRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var skillCell : SkillCell = skillCache.get(skillId)
	if skillCell and skillCell.icon:
		iconRect.texture = skillCell.icon

	hbox.add_child(iconRect)

	var skillNameEdit : LineEdit = LineEdit.new()
	skillNameEdit.custom_minimum_size = Vector2(150, 0)
	skillNameEdit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if skillCell:
		skillNameEdit.text = skillCell.name
	skillNameEdit.placeholder_text = "Skill name"
	skillNameEdit.set_meta("skill_index", index)
	skillNameEdit.text_submitted.connect(_on_skill_name_changed.bind(index))
	hbox.add_child(skillNameEdit)

	var probLabel : Label = Label.new()
	probLabel.text = "Probability:"
	hbox.add_child(probLabel)

	var probSpin : SpinBox = SpinBox.new()
	probSpin.min_value = 0
	probSpin.max_value = 100
	probSpin.step = 0.1
	probSpin.value = probability
	probSpin.suffix = "%"
	probSpin.custom_minimum_size = Vector2(100, 0)
	probSpin.set_meta("skill_index", index)
	probSpin.value_changed.connect(_on_skill_probability_changed.bind(index))
	hbox.add_child(probSpin)

	var deleteBtn : Button = Button.new()
	deleteBtn.text = "X"
	deleteBtn.set_meta("skill_index", index)
	deleteBtn.pressed.connect(_on_delete_skill_pressed.bind(index))
	hbox.add_child(deleteBtn)

	skillsContainer.add_child(hbox)

func _on_skill_name_changed(newName : String, index : int):
	if not selectedEntity:
		return

	var skillsArray : PackedInt64Array = selectedEntity.get("_skillSet")
	var skillsProba : Dictionary = selectedEntity.get("_skillProba")
	if not skillsArray or index >= skillsArray.size():
		return

	var skillCell : SkillCell = FindSkillByName(newName)
	if skillCell:
		var oldSkillId : int = skillsArray[index]
		var oldProb : float = skillsProba.get(oldSkillId, 100.0) if skillsProba else 100.0

		skillsArray[index] = skillCell.id

		if not skillsProba:
			skillsProba = {}
			selectedEntity.set("_skillProba", skillsProba)

		if skillsProba.has(oldSkillId):
			skillsProba.erase(oldSkillId)
		skillsProba[skillCell.id] = oldProb

		SaveEntity()
		RefreshSkillsDisplay()

func _on_skill_probability_changed(newValue : float, index : int):
	if not selectedEntity:
		return

	var skillsArray : PackedInt64Array = selectedEntity.get("_skillSet")
	var skillsProba : Dictionary = selectedEntity.get("_skillProba")
	if not skillsArray or index >= skillsArray.size():
		return

	var skillId : int = skillsArray[index]

	if not skillsProba:
		skillsProba = {}
		selectedEntity.set("_skillProba", skillsProba)

	skillsProba[skillId] = newValue
	SaveEntity()

func _on_delete_skill_pressed(index : int):
	if not selectedEntity:
		return

	var skillsArray : PackedInt64Array = selectedEntity.get("_skillSet")
	var skillsProba : Dictionary = selectedEntity.get("_skillProba")
	if not skillsArray or index >= skillsArray.size():
		return

	var skillId : int = skillsArray[index]

	skillsArray.remove_at(index)

	if skillsProba and skillsProba.has(skillId):
		skillsProba.erase(skillId)

	SaveEntity()
	RefreshSkillsDisplay()

func _on_add_skill_pressed():
	if not selectedEntity:
		return

	var skillsArray : PackedInt64Array = selectedEntity.get("_skillSet")
	var skillsProba : Dictionary = selectedEntity.get("_skillProba")

	if not skillsArray:
		skillsArray = PackedInt64Array()
		selectedEntity.set("_skillSet", skillsArray)

	if not skillsProba:
		skillsProba = {}
		selectedEntity.set("_skillProba", skillsProba)

	skillsArray.append(0)
	skillsProba[0] = 100.0

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
