extends Node

enum State { IDLE = 0, WALK, SIT, UNKNOWN = -1 }

const ACTION_GP_MOVE_RIGHT		= "gp_move_right"
const ACTION_GP_MOVE_LEFT		= "gp_move_left"
const ACTION_GP_MOVE_UP			= "gp_move_up"
const ACTION_GP_MOVE_DOWN		= "gp_move_down"
const ACTION_GP_SIT				= "gp_sit"

const ACTION_UI_QUIT_GAME		= "ui_quit_game"
const ACTION_UI_INVENTORY		= "ui_inventory"
const ACTION_UI_MINIMAP			= "ui_minimap"
const ACTION_UI_CHAT			= "ui_chat"
