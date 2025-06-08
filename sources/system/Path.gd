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

const EmotePst : String					= CellPst + "emotes/"
const ItemPst : String					= CellPst + "items/"
const SkillPst : String					= CellPst + "skills/"

const EntityComponent : String			= EntityPst + "components/"
const EntitySprite : String				= EntityPst + "sprites/"

# Local
const Local : String					= "user://"

# Extentions
const GfxExt: String					= ".png"
const MapClientExt: String				= ".tmx.client.scn"
const MapServerExt: String				= ".tmx.server.scn"
const MapNavigationExt: String			= ".tmx.navigation.tres"
const MusicExt: String					= ".ogg"
const DBExt: String						= ".db"
const ConfExt: String					= ".cfg"
const SceneExt: String					= ".tscn"
const RscExt: String					= ".tres"
const DataExt: String					= ".json"
