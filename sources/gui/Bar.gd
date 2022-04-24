extends TextureProgress

const defaultTexturePath	= "res://data/graphics/gui/barprogressdefault.png"

func _ready():
	if get_progress_texture() == null:
		SetSpriteTexture(defaultTexturePath)

func SetSpriteTexture(texturePath):
	var texture = load(texturePath)
	assert(texture != null, "Progress bar ressource not found!")
	if texture != null:
		set_progress_texture(texture)
