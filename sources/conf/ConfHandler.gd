extends Node

var confFiles : Array		= \
[ \
	FileSystem.LoadConfig("project"),			\
	FileSystem.LoadConfig("map"),				\
	FileSystem.LoadConfig("window"),			\
	FileSystem.LoadConfig("gameplay"),			\
	FileSystem.LoadConfig("network"),			\
	FileSystem.LoadConfig("auth"),				\
	FileSystem.LoadConfig("debug")				\
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
