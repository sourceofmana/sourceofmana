# The MIT License (MIT)
#
# Copyright (c) 2018 George Marques
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends EditorImportPlugin


################################################################################



################################################################################

enum { PRESET_DEFAULT, PRESET_PIXEL_ART }

func _get_importer_name():
	return "vnen.tiled_tileset_importer"

func _get_visible_name():
	return "TileSet from Tiled"

func _get_recognized_extensions():
	return ["tsx"]

func _get_save_extension():
	return "res"

func _get_import_order():
	return 0

func _get_resource_type():
	return "TileSet"

func _get_preset_count():
	return 2

func _get_preset_name(preset):
	match preset:
		PRESET_DEFAULT: return "Default"
		PRESET_PIXEL_ART: return "Pixel Art"

func _get_priority():
	return 1

func _get_import_options(path, preset):
	return [
		{
			"name": "custom_properties",
			"default_value": true
		},
		{
			"name": "tile_metadata",
			"default_value": false
		},
		{
			"name": "embed_internal_images",
			"default_value": true if preset == PRESET_PIXEL_ART else false
		},
		{
			"name": "save_tiled_properties",
			"default_value": false
		},
		{
			"name": "apply_offset",
			"default_value": false
		},
		{
			"name": "post_import_script",
			"default_value": "",
			"property_hint": PROPERTY_HINT_FILE,
			"hint_string": "*.gd;GDScript"
		}
	]

func _get_option_visibility(path, option, options):
	return true

func _import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var mapReader = TiledMapReader.new()
	var tileset = mapReader.build_tileset(source_file, options)

	if typeof(tileset) != TYPE_OBJECT:
		# Error happened
		return tileset

	# Post imports script
	if not options.post_import_script.is_empty():
		var script = load(options.post_import_script)
		if not script or not script is GDScript:
			printerr("Post import script is not a GDScript.")
			return ERR_INVALID_PARAMETER

		script = script.new()
		if not script.has_method("post_import"):
			printerr("Post import script does not have a 'post_import' method.")
			return ERR_INVALID_PARAMETER

		tileset = script.post_import(tileset)

		if not tileset or not tileset is TileSet:
			printerr("Invalid TileSet returned from post import script.")
			return ERR_INVALID_DATA

	return ResourceSaver.save(tileset, "%s.%s" % [save_path, _get_save_extension()])
