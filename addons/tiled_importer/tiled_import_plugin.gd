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

enum { PRESET_DEFAULT, PRESET_PIXEL_ART }

func _get_importer_name():
	return "vnen.tiled_importer"

func _get_visible_name():
	return "Scene from Tiled"

func _get_recognized_extensions():
	return ["tmx"]

func _get_save_extension():
	return "scn"

func _get_priority():
	return 1

func _get_import_order():
	return 100

func _get_resource_type():
	return "PackedScene"

func _get_preset_count():
	return 2

func _get_preset_name(preset):
	match preset:
		PRESET_DEFAULT: return "Default"
		PRESET_PIXEL_ART: return "Pixel Art"

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
			"name": "uv_clip",
			"default_value": true
		},
		{
			"name": "collision_layer",
			"default_value": 1,
			"property_hint": PROPERTY_HINT_LAYERS_2D_PHYSICS
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
			"name": "add_background",
			"default_value": true
		},
		{
			"name": "export_navigation_mesh",
			"default_value": true
		},
		{
			"name": "export_global_scene",
			"default_value": false
		}
	]

func _get_option_visibility(path, option, options):
	return true

func _import(source_file, save_path, options, r_platform_variants, r_gen_files):
	# Offset is only optional for importing TileSets
	options.apply_offset = true
	var saveRet = OK
	var mapReader = TiledMapReader.new()

	var client_scene : Node2D = mapReader.build_client(source_file, options)
	var server_resource : Resource = mapReader.build_server()
	var nav_region : NavigationRegion2D = mapReader.build_navigation()

	# Navigation import into a separate .tres
	if nav_region and options.export_navigation_mesh:
		NavigationServer2D.bake_from_source_geometry_data(nav_region.navigation_polygon, mapReader.source_data)
		saveRet &= ResourceSaver.save(nav_region.navigation_polygon, "%s.navigation.tres" % [source_file])

	# Import file when opening the .tmx file
	if options.export_global_scene:
		if nav_region:
			nav_region.set_name("NavRegion")
			client_scene.add_child(nav_region)
			nav_region.set_owner(client_scene)
		var packed_scene = PackedScene.new()
		packed_scene.pack(client_scene)
		saveRet &= ResourceSaver.save(packed_scene, "%s.%s" % [save_path, _get_save_extension()]) # Mandatory 
	else:
		# Client Data import (TileMap and warp locations)
		if client_scene:
			# Hide unused data from the client
			for child in client_scene.get_children():
				if child is TileMapLayer:
					child.set_occlusion_enabled(false)
					child.set_collision_enabled(false)
					child.set_navigation_enabled(false)
					if child.get_name() == "Collision":
						client_scene.remove_child(child)
			var packed_scene = PackedScene.new()
			packed_scene.pack(client_scene)
			saveRet &= ResourceSaver.save(packed_scene, "%s.client.%s" % [source_file, _get_save_extension()])

		# Server Data import (Spawn and warp locations)
		if server_resource:
			saveRet &= ResourceSaver.save(server_resource, "%s.server.tres" % [source_file])

		# Empty scene when the user want to open the .tmx, have to check the export_global_scene to generate a global unified scene
		var empty_scene : Node2D = Node2D.new()
		empty_scene.set_name("Empty")
		var packed_scene = PackedScene.new()
		packed_scene.pack(empty_scene)
		saveRet &= ResourceSaver.save(packed_scene, "%s.%s" % [save_path, _get_save_extension()]) # Mandatory 

	return saveRet
