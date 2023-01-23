extends Node

var confFiles : Array		= \
[ \
	Launcher.FileSystem.LoadConfig("project"),			\
	Launcher.FileSystem.LoadConfig("map"),				\
	Launcher.FileSystem.LoadConfig("window"),			\
	Launcher.FileSystem.LoadConfig("gameplay"),			\
	Launcher.FileSystem.LoadConfig("server")			\
]

#
func GetValue(category : String, param : String, type : int, default):
	var value = default
	
	if type != Launcher.Conf.Type.NONE\
	&& confFiles[type]\
	&& confFiles[type].has_section_key(category, param):
		value = confFiles[type].get_value(category, param, default)
	else:
		for conf in confFiles:
			if conf && conf.has_section_key(category, param):
				value = conf.get_value(category, param, default)

	return value
