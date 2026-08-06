extends Node
class_name Path

# Paths
const Rsc : String						= "res://"

const DataRsc : String					= Rsc + "data/"
const GfxRsc : String					= DataRsc + "graphics/"
const ItemRsc : String					= GfxRsc + "items/"
const ItemDataRsc : String				= DataRsc + "items/"
const MinimapRsc : String				= GfxRsc + "minimaps/"
const MapRsc : String					= DataRsc + "maps/"
const MusicRsc : String					= DataRsc + "music/"
const DBRsc : String					= DataRsc + "db/"
const ConfRsc : String					= DataRsc + "conf/"
const TemplateRsc : String				= ConfRsc + "templates/"
const MigrationRsc : String				= ConfRsc + "migrations/"

const Src : String						= Rsc + "sources/"
const ScriptSrc : String				= Src + "scripts/"
const DBInstSrc : String				= Src + "db/instance/"

const Pst : String						= Rsc + "presets/"
const EffectsPst : String				= Pst + "effects/"
const GuiPst : String					= Pst + "gui/"
const EntityPst : String				= Pst + "entities/"
const CellPst : String					= Pst + "cells/"
const PalettesPst : String				= Pst + "palettes/"
const QuestPst : String					= Pst + "quests/"
const MaterialPst : String				= Pst + "materials/"
const MapPst : String					= Pst + "maps/"

const EmotePst : String					= CellPst + "emotes/"
const ItemPst : String					= CellPst + "items/"
const SkillPst : String					= CellPst + "skills/"

const HairstylePst : String				= Pst + "hairstyles/"
const MusicPst : String					= Pst + "music/"
const RacesPst : String					= Pst + "races/"
const PaletteHairPst : String			= PalettesPst + "hair/"
const PaletteSkinPst : String			= PalettesPst + "skin/"
const PaletteEquipPst : String			= PalettesPst + "equip/"

const EntityComponent : String			= EntityPst + "components/"
const EntitySprite : String				= EntityPst + "sprites/"

const MapLayerPst : String				= MapPst + "layers/"
const MapServerPst : String				= MapPst + "server/"
const MapDataPst : String				= MapPst + "data/"
const MapNavPst : String				= MapPst + "navigations/"

const ParticlePst : String				= EffectsPst + "particles/"

# Local
const Local : String					= "user://"
const CanaryFile : String				= Local + "canary"

# Extentions
const GfxExt: String					= ".png"
const MusicExt: String					= ".ogg"
const DBExt: String						= ".db"
const ConfExt: String					= ".cfg"
const SceneExt: String					= ".tscn"
const RscExt: String					= ".tres"
const MapExt: String					= ".tmx"
const DataExt: String					= ".json"
const SQLExt: String					= ".sql"
const RemapExt: String					= ".remap"
