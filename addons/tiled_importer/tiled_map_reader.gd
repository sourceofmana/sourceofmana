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
extends RefCounted

# Constants for tile flipping
# http://doc.mapeditor.org/reference/tmx-map-format/#tile-flipping
const FLIPPED_HORIZONTALLY_FLAG = 0x80000000
const FLIPPED_VERTICALLY_FLAG   = 0x40000000
const FLIPPED_DIAGONALLY_FLAG   = 0x20000000

# XML Format reader
const TiledXMLToDictionary = preload("res://addons/tiled_importer/tiled_xml_to_dict.gd")

# Polygon vertices sorter
const PolygonSorter = preload("polygon_sorter.gd")

# Custom objects
const WarpObject = preload("WarpObject.gd")
const SpawnObject = preload("SpawnObject.gd")

# Prefix for error messages, make easier to identify the source
const error_prefix = "Tiled Importer: "

# Properties to save the value in the metadata
const whitelist_properties = [
	"backgroundcolor",
	"compression",
	"draworder",
	"gid",
	"height",
	"imageheight",
	"imagewidth",
	"infinite",
	"margin",
	"name",
	"orientation",
	"probability",
	"spacing",
	"tilecount",
	"tiledversion",
	"tileheight",
	"tilewidth",
	"type",
	"version",
	"visible",
	"width",
	"custom_material",
]

# All templates loaded, can be looked up by path name
var _loaded_templates = {}
# Maps each tileset file used by the map to it's first gid; Used for template parsing
var _tileset_path_to_first_gid = {}
# Store the max gid parsed to define the navigation polygon
var max_gid = 0
# Navigation polygon to be used on top of every tilemaps
#var nav_polygon_instance : NavigationPolygonInstance = NavigationPolygonInstance.new()
# Collision polygons
var collisionPool : Array = []
# Navigation polygons
var navigationPool : Array = []
# JSON Instance
var JSONInstance = JSON.new()
# Tile DB
var tileDic : Dictionary = {}

func reset_global_memebers():
	_loaded_templates = {}
	_tileset_path_to_first_gid = {}

# Main function
# Reads a source file and gives back a scene
func build(source_path, options):
	reset_global_memebers()
	var map = read_file(source_path)
	if typeof(map) == TYPE_INT:
		return map
	if typeof(map) != TYPE_DICTIONARY:
		return ERR_INVALID_DATA

	var err = validate_map(map)
	if err != OK:
		return err

	var cell_size = Vector2(int(map.tilewidth), int(map.tileheight))
	var map_mode = TileSet.TILE_SHAPE_SQUARE
	var map_offset = TileSet.TILE_SHAPE_HALF_OFFSET_SQUARE
	var map_pos_offset = Vector2()
	var map_background = Color()
	var cell_offset = Vector2()
	if "orientation" in map:
		match map.orientation:
			"isometric":
				map_mode = TileSet.TILE_SHAPE_ISOMETRIC
			"staggered":
				map_pos_offset.y -= cell_size.y / 2
				match map.staggeraxis:
					"x":
						map_offset = TileMap.HALF_OFFSET_Y
						cell_size.x /= 2.0
						if map.staggerindex == "even":
							cell_offset.x += 1
							map_pos_offset.x -= cell_size.x
					"y":
						map_offset = TileMap.HALF_OFFSET_X
						cell_size.y /= 2.0
						if map.staggerindex == "even":
							cell_offset.y += 1
							map_pos_offset.y -= cell_size.y
			"hexagonal":
				# Godot maps are always odd and don't have an "even" setting. To
				# imitate even staggering we simply start one row/column late and
				# adjust the position of the whole map.
				match map.staggeraxis:
					"x":
						map_offset = TileMap.HALF_OFFSET_Y
						cell_size.x = int((cell_size.x + map.hexsidelength) / 2)
						if map.staggerindex == "even":
							cell_offset.x += 1
							map_pos_offset.x -= cell_size.x
					"y":
						map_offset = TileMap.HALF_OFFSET_X
						cell_size.y = int((cell_size.y + map.hexsidelength) / 2)
						if map.staggerindex == "even":
							cell_offset.y += 1
							map_pos_offset.y -= cell_size.y

	var root = Node2D.new()
	root.set_name(source_path.get_file().get_basename())
	if options.save_tiled_properties:
		set_tiled_properties_as_meta(root, map)
	if options.custom_properties:
		set_custom_properties(root, map)

	var tileset = build_tileset_for_scene(map.tilesets, source_path, options, root)
	if typeof(tileset) != TYPE_OBJECT:
		# Error happened
		return tileset

	var map_data = {
		"options": options,
		"map_mode": map_mode,
		"map_offset": map_offset,
		"map_pos_offset": map_pos_offset,
		"map_background": map_background,
		"cell_size": cell_size,
		"cell_offset": cell_offset,
		"tileset": tileset,
		"source_path": source_path,
		"infinite": bool(map.infinite) if "infinite" in map else false
	}

	var layerID = 0
	var zOrder = 0
	var level = TileMap.new()
	tileset.tile_size = cell_size
	level.set_tileset(tileset)
	level.set("editor/display_folded", true)
	root.add_child(level)
	level.set_owner(root)
	level.set_name(source_path.get_file().get_basename())
	level.set_y_sort_enabled(true)

	for tmxLayer in map.layers:
		if tmxLayer.name == "Fringe":
			break
		else:
			zOrder -= 1

	for tmxLayer in map.layers:
		level.add_layer(layerID)
		err = make_layer(level, tmxLayer, root, root, map_data, zOrder, layerID)
		layerID +=1
		zOrder += 1

		if err != OK:
			return err

#	create_collision_layer()
#	create_navigation_layer()
#
#	var nav_polygon : NavigationPolygon = NavigationPolygon.new()
#	for navPolygon in navigationPool:
#		nav_polygon.add_outline(navPolygon)
#		nav_polygon.make_polygons_from_outlines()
#
#	nav_polygon_instance.set_navigation_polygon(nav_polygon)
#
#	if nav_polygon_instance:
#		root.add_child(nav_polygon_instance)
#		nav_polygon_instance.owner = root

	if options.add_background and "backgroundcolor" in map:
		var bg_color = str(map.backgroundcolor)
		if (!bg_color.is_valid_html_color()):
			print_error("Invalid background color format: " + bg_color)
			return root

		map_background = Color(bg_color)

		var viewport_size = Vector2(ProjectSettings.get("display/window/size/width"), ProjectSettings.get("display/window/size/height"))
		var parbg = ParallaxBackground.new()
		var parlayer = ParallaxLayer.new()
		var colorizer = ColorRect.new()

		parbg.scroll_ignore_camera_zoom = true
		parlayer.motion_mirroring = viewport_size
		colorizer.color = map_background
		colorizer.rect_size = viewport_size
		colorizer.rect_min_size = viewport_size

		parbg.name = "Background"
		root.add_child(parbg)
		parbg.owner = root
		parlayer.name = "BackgroundLayer"
		parbg.add_child(parlayer)
		parlayer.owner = root
		colorizer.name = "BackgroundColor"
		parlayer.add_child(colorizer)
		colorizer.owner = root

	return root

func build_collision_pool(tilemap, gid):
	var used_tiles = tilemap.get_used_cells_by_id(gid)
	for tile in used_tiles:
		var polygon_offset = tilemap.map_to_world(tile)
		var tile_region = tilemap.get_cell_autotile_coord(tile[0], tile[1])
		var tile_transform = tilemap.get_tileset().tile_get_shape_transform(gid, tile_region[0])

		var polygon_shape = null
		var col_shape = tilemap.get_tileset().tile_get_shape(gid, tile_region[0])
		if col_shape:
			if col_shape is ConvexPolygonShape2D:
				polygon_shape = col_shape.get_points()
			elif col_shape is ConcavePolygonShape2D:
				polygon_shape = col_shape.get_segments()
			elif col_shape is RectangleShape2D:
				var shapeExtents = col_shape.get_extents()
				polygon_shape = [ \
					Vector2(-shapeExtents.x, -shapeExtents.y), \
					Vector2(shapeExtents.x, -shapeExtents.y), \
					Vector2(shapeExtents.x, -shapeExtents.y), \
					Vector2(shapeExtents.x, shapeExtents.y), \
					Vector2(shapeExtents.x, shapeExtents.y), \
					Vector2(-shapeExtents.x, shapeExtents.y), \
					Vector2(-shapeExtents.x, shapeExtents.y), \
					Vector2(-shapeExtents.x, -shapeExtents.y) \
				]
			else:
				print("ERROR: this shape is not supported (" + str(col_shape) + ") ")

		if polygon_shape:
			var new_polygon = PackedVector2Array()
			for vertex in polygon_shape:
				vertex += polygon_offset
				new_polygon.append(tile_transform.xform(vertex))
			if new_polygon.size() > 0:
				collisionPool.append(new_polygon)

func create_collision_layer():
	var newPool : Array = []
	var isIntersected : bool = true

	while collisionPool.size() > 0:
		isIntersected = false

		var polygonLeft = collisionPool.pop_front()
		for polygonRight in collisionPool:
			var mergedPool = Geometry2D.merge_polygons(polygonLeft, polygonRight)
			if mergedPool.size() == 1:
				isIntersected = true
				collisionPool.erase(polygonRight)
				collisionPool.append(mergedPool[0])
				break
		if isIntersected == false:
			newPool.append(polygonLeft)

	for colPolygon in newPool:
		var hullPolygon : PackedVector2Array = colPolygon
		if hullPolygon[0] == hullPolygon[hullPolygon.size() - 1]:
			hullPolygon.remove_at(hullPolygon.size() - 1)
		collisionPool.append(hullPolygon)

func create_navigation_layer():
	navigationPool.append(PackedVector2Array([
			Vector2(0, 0),
			Vector2(3424, 0),
			Vector2(3424,2848),
			Vector2(0, 2848)
	]))

	for colPolygon in collisionPool:
		var newNavPolygon = []
		for navPolygon in navigationPool:
			newNavPolygon.append_array(Geometry2D.exclude_polygons(navPolygon, colPolygon))
		navigationPool.clear()
		navigationPool = newNavPolygon

# Creates a layer node from the data
# Returns an error code
func make_layer(level, tmxLayer, parent, root, data, zindex, layerID):
	var err = validate_layer(tmxLayer)
	if err != OK:
		return err

	# Main map data
	var map_pos_offset = data.map_pos_offset
	var cell_size = data.cell_size
	var cell_offset = data.cell_offset
	var options = data.options
	var tileset = data.tileset
	var source_path = data.source_path
	var infinite = data.infinite

	var opacity = float(tmxLayer.opacity) if "opacity" in tmxLayer else 1.0
	var visible = bool(tmxLayer.visible) if "visible" in tmxLayer else true

	level.set_layer_name(layerID, tmxLayer.name)
	if tmxLayer.type == "tilelayer":
		var layer_size = Vector2(int(tmxLayer.width), int(tmxLayer.height))
		level.set_layer_modulate(layerID, Color(1.0, 1.0, 1.0, opacity))
		level.set_layer_enabled(layerID, visible)
		level.set_layer_z_index(layerID, zindex)
		if "Fringe" in tmxLayer.name:
			level.set_layer_y_sort_enabled(layerID, true)
			level.set_layer_y_sort_origin(layerID, 21)

		var offset = Vector2()
		if "offsetx" in tmxLayer:
			offset.x = int(tmxLayer.offsetx)
		if "offsety" in tmxLayer:
			offset.y = int(tmxLayer.offsety)

		var chunks = []

		if infinite:
			chunks = tmxLayer.chunks
		else:
			chunks = [tmxLayer]

		for chunk in chunks:
			err = validate_chunk(chunk)
			if err != OK:
				return err

			var chunk_data = chunk.data

			if "encoding" in tmxLayer and tmxLayer.encoding == "base64":
				if "compression" in tmxLayer:
					chunk_data = decompress_layer_data(chunk.data, tmxLayer.compression, layer_size)
					if typeof(chunk_data) == TYPE_INT:
						# Error happened
						return chunk_data
				else:
					chunk_data = read_base64_layer_data(chunk.data)

			var count = 0
			for tile_id in chunk_data:
				var int_id = str(tile_id).to_int() & 0xFFFFFFFF

				if int_id == 0:
					count += 1
					continue

				var gid = int_id & ~(FLIPPED_HORIZONTALLY_FLAG | FLIPPED_VERTICALLY_FLAG | FLIPPED_DIAGONALLY_FLAG)

				var cell_x = cell_offset.x + chunk.x + (count % int(chunk.width))
				var cell_y = cell_offset.y + chunk.y + int(count / chunk.width)

				level.set_cell(layerID, Vector2i(cell_x, cell_y), tileDic[gid][0], tileDic[gid][1])

				if gid > max_gid:
					max_gid = gid

				count += 1

		if options.save_tiled_properties:
			set_tiled_properties_as_meta(level, tmxLayer)
		if options.custom_properties:
			set_custom_properties(level, tmxLayer)

		var gid= 0
#		while gid <= max_gid:
#			build_collision_pool(tilemap, gid)
#			gid += 1
	elif tmxLayer.type == "imagelayer":
		var image = null
		if tmxLayer.image != "":
			image = load_image(tmxLayer.image, source_path, options)
			if typeof(image) != TYPE_OBJECT:
				# Error happened
				return image

		var pos = Vector2()
		var offset = Vector2()

		if "x" in tmxLayer:
			pos.x = float(tmxLayer.x)
		if "y" in tmxLayer:
			pos.y = float(tmxLayer.y)
		if "offsetx" in tmxLayer:
			offset.x = float(tmxLayer.offsetx)
		if "offsety" in tmxLayer:
			offset.y = float(tmxLayer.offsety)

		var sprite = Sprite2D.new()
		sprite.set_name(str(tmxLayer.name))
		sprite.centered = false
		sprite.texture = image
		sprite.visible = visible
		sprite.modulate = Color(1.0, 1.0, 1.0, opacity)
		if options.save_tiled_properties:
			set_tiled_properties_as_meta(sprite, tmxLayer)
		if options.custom_properties:
			set_custom_properties(sprite, tmxLayer)

		sprite.set("editor/display_folded", true)
		parent.add_child(sprite)
		sprite.position = pos + offset
		sprite.set_owner(root)
	elif tmxLayer.type == "objectgroup":
		var object_layer = null
		var is_navigation_layer = false

		if "name" in tmxLayer and not str(tmxLayer.name).is_empty() && str(tmxLayer.name) == "Navigation":
			object_layer = NavigationRegion2D.new()
			is_navigation_layer = true
		else:
			object_layer = Node2D.new()
			
		if options.save_tiled_properties:
			set_tiled_properties_as_meta(object_layer, tmxLayer)
		if options.custom_properties:
			set_custom_properties(object_layer, tmxLayer)
			object_layer.set("editor/display_folded", true)
		if is_navigation_layer:
			object_layer.navpoly = NavigationPolygon.new()
			object_layer.set_name("Navigation2D")
			parent.add_child(object_layer)
			object_layer.set_owner(root)
		else:
			parent.add_child(object_layer)
			object_layer.set_owner(root)
		if "name" in tmxLayer and not str(tmxLayer.name).is_empty():
			object_layer.set_name(str(tmxLayer.name))

		if not "draworder" in tmxLayer or tmxLayer.draworder == "topdown":
			tmxLayer.objects.sort_custom(object_sorter)

		for object in tmxLayer.objects:
			if "template" in object:
				var template_file = object["template"]
				var template_data_immutable = get_template(remove_filename_from_path(data["source_path"]) + template_file)
				if typeof(template_data_immutable) != TYPE_DICTIONARY:
					# Error happened
					print("Error getting template for object with id " + str(data["id"]))
					continue

				# Overwrite template data with current object data
				apply_template(object, template_data_immutable)

				set_default_obj_params(object)

			if "point" in object and object.point:
				var point = Node2D.new()
				if not "x" in object or not "y" in object:
					print_error("Missing coordinates for point in object tmxLayer.")
					continue
				point.position = Vector2(float(object.x), float(object.y))
				point.visible = bool(object.visible) if "visible" in object else true
				object_layer.add_child(point)
				point.set_owner(root)
				if "name" in object and not str(object.name).is_empty():
					point.set_name(str(object.name))
				elif "id" in object and not str(object.id).is_empty():
					point.set_name(str(object.id))
				if options.save_tiled_properties:
					set_tiled_properties_as_meta(point, object)
				if options.custom_properties:
					set_custom_properties(point, object)

			elif not "gid" in object:
				# Not a tile object
				if "type" in object and object.type == "navigation":
					# Can't make navigation objects right now
					print_error("Navigation polygons aren't supported in an object tmxLayer.")
					continue # Non-fatal error
				var shape = shape_from_object(object)

				if typeof(shape) != TYPE_OBJECT:
					# Error happened
					return shape

				if "type" in object and object.type == "occluder":
					var occluder = LightOccluder2D.new()
					var pos = Vector2()
					var rot = 0

					if "x" in object:
						pos.x = float(object.x)
					if "y" in object:
						pos.y = float(object.y)
					if "rotation" in object:
						rot = float(object.rotation)

					occluder.visible = bool(object.visible) if "visible" in object else true
					occluder.position = pos
					occluder.rotation_degrees = rot
					occluder.occluder = shape
					if "name" in object and not str(object.name).is_empty():
						occluder.set_name(str(object.name))
					elif "id" in object and not str(object.id).is_empty():
						occluder.set_name(str(object.id))

					if options.save_tiled_properties:
						set_tiled_properties_as_meta(occluder, object)
					if options.custom_properties:
						set_custom_properties(occluder, object)

					object_layer.add_child(occluder)
					occluder.set_owner(root)

				else:
					var offset = Vector2()
					var customObject
					var collisionObject
					var pos = Vector2()
					var rot = 0

					if not ("polygon" in object or "polyline" in object):
						# Regular shape
						if object.type == "Spawn":
#							customObject = Shape2D.new()
							continue
						else:
							customObject = Shape2D.new()
						customObject.shape = shape
						if shape is RectangleShape2D:
							offset = shape.extents
						elif shape is CircleShape2D:
							offset = Vector2(shape.radius, shape.radius)
						elif shape is CapsuleShape2D:
							offset = Vector2(shape.radius, shape.height)
							if shape.radius > shape.height:
								var temp = shape.radius
								shape.radius = shape.height
								shape.height = temp
								customObject.rotation_degrees = 90
							shape.height *= 2
						customObject.position = offset
					else:
						if object.type == "Warp":
							customObject = WarpObject.new()
							collisionObject = CollisionPolygon2D.new()
						else:
							customObject = Polygon2D.new()

						var points = null
						if shape is ConcavePolygonShape2D:
							points = []
							var segments = shape.segments
							for i in range(0, segments.size()):
								if i % 2 != 0:
									continue
								points.push_back(segments[i])
#							customObject.build_mode = Polygon2D.BUILD_SEGMENTS
						else:
							points = shape.points
#							customObject.build_mode = Polygon2D.BUILD_SOLIDS
						if collisionObject:
							collisionObject.polygon = points
						else:
							customObject.polygon = points

#					customObject.one_way_collision = object.type == "one-way"

					if "x" in object:
						pos.x = float(object.x)
					if "y" in object:
						pos.y = float(object.y)
					if "rotation" in object:
						rot = float(object.rotation)

					if "name" in object and not str(object.name).is_empty():
						customObject.set_name(str(object.name))
					elif "id" in object and not str(object.id).is_empty():
						customObject.set_name(str(object.id))
					if collisionObject:
						collisionObject.set_name(customObject.get_name())

					if customObject && object_layer:
						if is_navigation_layer:
							var polygon_offseted : PackedVector2Array = []
							for poly in customObject.polygon:
								polygon_offseted.append(pos + poly)
							var nav_polygon : NavigationPolygon = object_layer.get_navigation_polygon()
							if nav_polygon == null:
								nav_polygon = NavigationPolygon.new()
							nav_polygon.add_outline(polygon_offseted)
							nav_polygon.make_polygons_from_outlines()

							object_layer.set_navigation_polygon(nav_polygon)
						else:
							customObject.set("editor/display_folded", true)
							object_layer.add_child(customObject)
							customObject.set_owner(root)

					if collisionObject:
						collisionObject.set("editor/display_folded", true)
						customObject.add_child(collisionObject)
						collisionObject.set_owner(root)

					if options.save_tiled_properties:
						set_tiled_properties_as_meta(customObject, object)
					if options.custom_properties:
						set_custom_properties(customObject, object)

					# Warp
					if "type" in object and object.type == "Warp":
						if "properties" in object:
							if "dest_map" in object.properties and not str(object.properties.dest_map).is_empty():
								customObject.destinationMap = object.properties.dest_map
							if "dest_pos_x" in object.properties and "dest_pos_y" in object.properties:
								customObject.destinationPos = Vector2(object.properties.dest_pos_x, object.properties.dest_pos_y)

					# Spawn
					elif "type" in object and object.type == "Spawn":
						if "properties" in object:
							if "max_count" in object.properties:
								customObject.maxCount = object.properties.max_count
							if "mob_id" in object.properties:
								customObject.mobID = object.properties.mob_id
							if "mob_level" in object.properties:
								customObject.mobLevel = object.properties.mob_level
							if "respawn_timer" in object.properties:
								customObject.respawnTimer = object.properties.respawn_timer

					customObject.visible = bool(object.visible) if "visible" in object else true
					customObject.position = pos

			else: # "gid" in object
				var tile_raw_id = str(object.gid).to_int() & 0xFFFFFFFF
				var tile_id = tile_raw_id & ~(FLIPPED_HORIZONTALLY_FLAG | FLIPPED_VERTICALLY_FLAG | FLIPPED_DIAGONALLY_FLAG)

				var is_tile_object = tileset.tile_get_region(tile_id).get_area() == 0
				var collisions = tileset.tile_get_shape_count(tile_id)
				var has_collisions = collisions > 0 && object.has("type") && object.type != "sprite"
				var sprite = Sprite2D.new()
				var pos = Vector2()
				var rot = 0
				var scale = Vector2(1, 1)
				sprite.texture = tileset.tile_get_texture(tile_id)
				var texture_size = sprite.texture.get_size() if sprite.texture != null else Vector2()

				if not is_tile_object:
					sprite.region_enabled = true
					sprite.region_rect = tileset.tile_get_region(tile_id)
					texture_size = tileset.tile_get_region(tile_id).size

				sprite.flip_h = bool(tile_raw_id & FLIPPED_HORIZONTALLY_FLAG)
				sprite.flip_v = bool(tile_raw_id & FLIPPED_VERTICALLY_FLAG)

				if "x" in object:
					pos.x = float(object.x)
				if "y" in object:
					pos.y = float(object.y)
				if "rotation" in object:
					rot = float(object.rotation)
				if texture_size != Vector2():
					if "width" in object and float(object.width) != texture_size.x:
						scale.x = float(object.width) / texture_size.x
					if "height" in object and float(object.height) != texture_size.y:
						scale.y = float(object.height) / texture_size.y

				var obj_root = sprite
				if has_collisions:
					match object.type:
						"area": obj_root = Area2D.new()
						"kinematic": obj_root = KinematicCollision2D.new()
						"rigid": obj_root = RigidBody2D.new()
						_: obj_root = StaticBody2D.new() 

					object_layer.add_child(obj_root)
					obj_root.owner = root

					obj_root.add_child(sprite)
					sprite.owner = root

					var shapes = tileset.tile_get_shapes(tile_id)
					for s in shapes:
						var collision_node = CollisionShape2D.new()
						collision_node.shape = s.shape

						collision_node.transform = s.shape_transform
						if sprite.flip_h:
							collision_node.position.x *= -1
							collision_node.position.x -= cell_size.x
							collision_node.scale.x *= -1
						if sprite.flip_v:
							collision_node.scale.y *= -1
							collision_node.position.y *= -1
							collision_node.position.y -= cell_size.y
						obj_root.add_child(collision_node)
						collision_node.owner = root

				if "name" in object and not str(object.name).is_empty():
					obj_root.set_name(str(object.name))
				elif "id" in object and not str(object.id).is_empty():
					obj_root.set_name(str(object.id))

				obj_root.position = pos
				obj_root.rotation_degrees = rot
				obj_root.visible = bool(object.visible) if "visible" in object else true
				obj_root.scale = scale
				# Translate from Tiled bottom-left position to Godot top-left
				sprite.centered = false
				sprite.region_filter_clip = options.uv_clip
				sprite.offset = Vector2(0, texture_size.y)

				if not has_collisions:
					object_layer.add_child(sprite)
					sprite.set_owner(root)

				if options.save_tiled_properties:
					set_tiled_properties_as_meta(obj_root, object)
				if options.custom_properties:
					if options.tile_metadata:
						var tile_meta = tileset.get_meta("tile_meta")
						if typeof(tile_meta) == TYPE_DICTIONARY and tile_id in tile_meta:
							for prop in tile_meta[tile_id]:
								obj_root.set_meta(prop, tile_meta[tile_id][prop])
					set_custom_properties(obj_root, object)

	elif tmxLayer.type == "group":
		var group = Node2D.new()
		var pos = Vector2()
		if "x" in tmxLayer:
			pos.x = float(tmxLayer.x)
		if "y" in tmxLayer:
			pos.y = float(tmxLayer.y)
		group.modulate = Color(1.0, 1.0, 1.0, opacity)
		group.visible = visible
		group.position = pos

		if options.save_tiled_properties:
			set_tiled_properties_as_meta(group, tmxLayer)
		if options.custom_properties:
			set_custom_properties(group, tmxLayer)

		if "name" in tmxLayer and not str(tmxLayer.name).is_empty():
			group.set_name(str(tmxLayer.name))

		group.set("editor/display_folded", true)
		parent.add_child(group)
		group.set_owner(root)

		#create_collision_layer()

	else:
		print_error("Unknown tmxLayer type ('%s') in '%s'" % [str(tmxLayer.type), str(tmxLayer.name) if "name" in tmxLayer else "[unnamed tmxLayer]"])
		return ERR_INVALID_DATA

	return OK

func set_default_obj_params(object):
	# Set default values for object
	for attr in ["width", "height", "rotation", "x", "y"]:
		if not attr in object:
			object[attr] = 0
	if not "type" in object:
		object.type = ""
	if not "visible" in object:
		object.visible = true

var flags

# Makes a tileset from a array of tilesets data
# Since Godot supports only one TileSet per TileMap, all tilesets from Tiled are combined
func build_tileset_for_scene(tilesets, source_path, options, root):
	var err = ERR_INVALID_DATA
	var tile_meta = {}
	var tsGroup = TileSet.new()
	tsGroup.add_physics_layer()

	for tileset in tilesets:
		var tsAtlas = TileSetAtlasSource.new()
		var layerID = tsGroup.add_source(tsAtlas)
		var ts = tileset
		var ts_source_path = source_path
		if "source" in ts:
			if not "firstgid" in tileset or not str(tileset.firstgid).is_valid_int():
				print_error("Missing or invalid firstgid tileset property.")
				return ERR_INVALID_DATA

			ts_source_path = source_path.get_base_dir().path_join(ts.source)
			# Used later for templates
			_tileset_path_to_first_gid[ts_source_path] = tileset.firstgid

			if ts.source.get_extension().to_lower() == "tsx":
				var tsx_reader = TiledXMLToDictionary.new()
				ts = tsx_reader.read_tsx(ts_source_path)

				if typeof(ts) != TYPE_DICTIONARY:
					# Error happened
					return ts
			else: # JSON Tileset
				var f = File.new()
				err = f.open(ts_source_path, File.READ)
				if err != OK:
					print_error("Error opening tileset '%s'." % [ts.source])
					return err

				var json_res = JSONInstance.parse(f.get_as_text())
				if json_res.error != OK:
					print_error("Error parsing tileset '%s' JSON: %s" % [ts.source, json_res.error_string])
					return ERR_INVALID_DATA

				ts = json_res.result
				if typeof(ts) != TYPE_DICTIONARY:
					print_error("Tileset '%s' is not a dictionary." % [ts.source])
					return ERR_INVALID_DATA

			ts.firstgid = tileset.firstgid
		err = validate_tileset(ts)
		if err != OK:
			return err

		var has_global_image = "image" in ts

		var spacing = int(ts.spacing) if "spacing" in ts and str(ts.spacing).is_valid_int() else 0
		var margin = int(ts.margin) if "margin" in ts and str(ts.margin).is_valid_int() else 0
		var firstgid = int(ts.firstgid)
		var columns = int(ts.columns) if "columns" in ts and str(ts.columns).is_valid_int() else -1

		var image = null
		var imagesize = Vector2()

		if has_global_image:
			image = load_image(ts.image, ts_source_path, options)
			if typeof(image) != TYPE_OBJECT:
				# Error happened
				return image
			imagesize = Vector2(int(ts.imagewidth), int(ts.imageheight))

		var tilesize = Vector2(int(ts.tilewidth), int(ts.tileheight))
		var tilecount = int(ts.tilecount)

		var gid = firstgid

		var x = margin
		var y = margin

		var i = 0
		var column = 0
		var tileRegions = []

		while i < tilecount:
			var tilepos = Vector2(x, y)
			var region = Rect2(tilepos, tilesize)

			tileRegions.push_back(region)

			column += 1
			i += 1

			x += int(tilesize.x) + spacing
			if (columns > 0 and column >= columns) or x >= int(imagesize.x) - margin or (x + int(tilesize.x)) > int(imagesize.x):
				x = margin
				y += int(tilesize.y) + spacing
				column = 0

		i = 0

		while i < tilecount:
			var region = tileRegions[i]

			var rel_id = str(gid - firstgid)

			if has_global_image:
				tsAtlas.set_texture(image)
#				if options.apply_offset:
#					tsAtlas.set_margins(Vector2(0, 32-tilesize.y))
			elif not rel_id in ts.tiles:
				gid += 1
				continue
			else:
				var image_path = ts.tiles[rel_id].image
				image = load_image(image_path, ts_source_path, options)
				if typeof(image) != TYPE_OBJECT:
					# Error happened
					return image
				tsAtlas.set_texture(image)
#				if options.apply_offset:
#					tsAtlas.set_margins(Vector2(0, 32-image.get_height()))
			var atlasPos : Vector2i = region.position / region.size
			tileDic[gid] = [layerID, atlasPos]
			tsAtlas.set_texture_region_size(region.size)
			tsAtlas.create_tile(atlasPos, region.size / region.size)

			var tileData : TileData = tsAtlas.get_tile_data(atlasPos, 0)
			var textureOffset : Vector2i = Vector2i.ZERO
			if region.size.x > 32 || region.size.y > 32:
				textureOffset.x = -(region.size.x - 32) / 2
				textureOffset.y = (region.size.y - 32) / 2
				tileData.set_texture_offset(textureOffset)

#			if rel_id in ts.tiles && "animation" in ts.tiles[rel_id]:
#				tsAtlas.set_tile_animation_frames_count(region.position / region.size, ts.tiles[rel_id].animation.size() - 1)
#				tsAtlas.set_tile_animation_columns(region.position / region.size, ts.tiles[rel_id].animation.size() - 1)
#
#				var c = 0
#				# Animated texture wants us to have seperate textures for each frame
#				# so we have to pull them out of the tileset
#				var tilesetTexture = image.get_image()
#				for g in ts.tiles[rel_id].animation:
#					tsAtlas.set_tile_animation_frame_duration(region.position / region.size, c, g.duration.to_float() * 0.001)
#					c += 1

			if "tiles" in ts and rel_id in ts.tiles and "objectgroup" in ts.tiles[rel_id] \
					and "objects" in ts.tiles[rel_id].objectgroup:

				for object in ts.tiles[rel_id].objectgroup.objects:

					var shape = shape_from_object(object)

					if typeof(shape) != TYPE_OBJECT:
						# Error happened
						return shape

					var offset = Vector2(float(object.x), float(object.y))
					offset -= Vector2(16,16) if region.size == Vector2(32,32) else Vector2(16, region.size.y - 16)

					var polygonShape : PackedVector2Array = []
					if shape is ConvexPolygonShape2D:
						polygonShape = shape.get_points()
					elif shape is ConcavePolygonShape2D:
						polygonShape = shape.get_segments()
					elif shape is RectangleShape2D:
						var shapeSize = shape.get_size()
						polygonShape = [ \
							Vector2(0, 0), \
							Vector2(0, shapeSize.y), \
							Vector2(0, shapeSize.y), \
							Vector2(shapeSize.x, shapeSize.y), \
							Vector2(shapeSize.x, shapeSize.y), \
							Vector2(shapeSize.x, 0), \
							Vector2(shapeSize.x, 0), \
							Vector2(0, 0) \
							]

					for iVertice in range(0, polygonShape.size()):
						polygonShape[iVertice] += offset
					if polygonShape.is_empty() == false:
						var tilePolygonCount = tileData.get_collision_polygons_count(0)
						tileData.set_collision_polygons_count(0, tilePolygonCount + 1)
						tileData.set_collision_polygon_points(0, tilePolygonCount, polygonShape)

#			if "properties" in ts and "custom_material" in ts.properties:
#				result.tile_set_material(gid, load(ts.properties.custom_material))

			if options.custom_properties and options.tile_metadata and "tileproperties" in ts \
					and "tilepropertytypes" in ts and rel_id in ts.tileproperties and rel_id in ts.tilepropertytypes:
				tile_meta[gid] = get_custom_properties(ts.tileproperties[rel_id], ts.tilepropertytypes[rel_id])
			if options.save_tiled_properties and rel_id in ts.tiles:
				for property in whitelist_properties:
					if property in ts.tiles[rel_id]:
						if not gid in tile_meta: tile_meta[gid] = {}
						tile_meta[gid][property] = ts.tiles[rel_id][property]

			gid += 1
			i += 1

		if str(ts.name) != "":
			tsAtlas.resource_name = str(ts.name)

		if options.save_tiled_properties:
			set_tiled_properties_as_meta(tsAtlas, ts)
		if options.custom_properties:
			if "properties" in ts and "propertytypes" in ts:
				set_custom_properties(tsAtlas, ts)

	if options.custom_properties and options.tile_metadata:
		tsGroup.set_meta("tile_meta", tile_meta)

	return tsGroup

# Makes a standalone TileSet. Useful for importing TileSets from Tiled
# Returns an error code if fails
func build_tileset(source_path, options):
	var set = read_tileset_file(source_path)
	if typeof(set) == TYPE_INT:
		return set
	if typeof(set) != TYPE_DICTIONARY:
		return ERR_INVALID_DATA

	# Just to validate and build correctly using the existing builder
	set["firstgid"] = 0

	return build_tileset_for_scene([set], source_path, options, null)


# Makes a tileset from a array of tilesets data
# Since Godot supports only one TileSet per TileMap, all tilesets from Tiled are combined
func build_navigation_polygon_for_scene(tilesets, source_path, options):
	var result = TileSet.new()
	var err = ERR_INVALID_DATA
	var tile_meta = {}

	for tileset in tilesets:
		var ts = tileset
		var ts_source_path = source_path
		if "source" in ts:
			if not "firstgid" in tileset or not str(tileset.firstgid).is_valid_int():
				print_error("Missing or invalid firstgid tileset property.")
				return ERR_INVALID_DATA

			ts_source_path = source_path.get_base_dir().path_join(ts.source)
			# Used later for templates
			_tileset_path_to_first_gid[ts_source_path] = tileset.firstgid

			if ts.source.get_extension().to_lower() == "tsx":
				var tsx_reader = TiledXMLToDictionary.new()
				ts = tsx_reader.read_tsx(ts_source_path)
				if typeof(ts) != TYPE_DICTIONARY:
					# Error happened
					return ts
			else: # JSON Tileset
				var f = File.new()
				err = f.open(ts_source_path, File.READ)
				if err != OK:
					print_error("Error opening tileset '%s'." % [ts.source])
					return err

				var json_res = JSONInstance.parse(f.get_as_text())
				if json_res.error != OK:
					print_error("Error parsing tileset '%s' JSON: %s" % [ts.source, json_res.error_string])
					return ERR_INVALID_DATA

				ts = json_res.result
				if typeof(ts) != TYPE_DICTIONARY:
					print_error("Tileset '%s' is not a dictionary." % [ts.source])
					return ERR_INVALID_DATA

			ts.firstgid = tileset.firstgid

		err = validate_tileset(ts)
		if err != OK:
			return err

		var has_global_image = "image" in ts

		var spacing = int(ts.spacing) if "spacing" in ts and str(ts.spacing).is_valid_int() else 0
		var margin = int(ts.margin) if "margin" in ts and str(ts.margin).is_valid_int() else 0
		var firstgid = int(ts.firstgid)
		var columns = int(ts.columns) if "columns" in ts and str(ts.columns).is_valid_int() else -1

		var image = null
		var imagesize = Vector2()

		if has_global_image:
			image = load_image(ts.image, ts_source_path, options)
			if typeof(image) != TYPE_OBJECT:
				# Error happened
				return image
			imagesize = Vector2(int(ts.imagewidth), int(ts.imageheight))

		var tilesize = Vector2(int(ts.tilewidth), int(ts.tileheight))
		var tilecount = int(ts.tilecount)

		var gid = firstgid

		var x = margin
		var y = margin

		var i = 0
		var column = 0
		var tileRegions = []

		while i < tilecount:
			var tilepos = Vector2(x, y)
			var region = Rect2(tilepos, tilesize)


			tileRegions.push_back(region)

			column += 1
			i += 1

			x += int(tilesize.x) + spacing
			if (columns > 0 and column >= columns) or x >= int(imagesize.x) - margin or (x + int(tilesize.x)) > int(imagesize.x):
				x = margin
				y += int(tilesize.y) + spacing
				column = 0

		i = 0

		while i < tilecount:
			var region = tileRegions[i]

			var rel_id = str(gid - firstgid)

			result.create_tile(gid)

			if has_global_image:
				if rel_id in ts.tiles && "animation" in ts.tiles[rel_id]:
					var animated_tex = AnimatedTexture.new()
					animated_tex.frames = ts.tiles[rel_id].animation.size()
					animated_tex.fps = 0
					var c = 0
					# Animated texture wants us to have seperate textures for each frame
					# so we have to pull them out of the tileset
					var tilesetTexture = image.get_data()
					for g in ts.tiles[rel_id].animation:
						var frameTex = tilesetTexture.get_rect(tileRegions[g.tileid.to_int()])
						var newTex = ImageTexture.new()
						newTex.create_from_image(frameTex)
						animated_tex.set_frame_texture(c, newTex)
						animated_tex.set_frame_delay(c, float(g.duration) * 0.001)
						c += 1
					result.set_texture(animated_tex)
					result.tile_set_region(gid, Rect2(Vector2(0, 0), tilesize))
				else:
					result.set_texture(image)
				if options.apply_offset:
					result.set_margins(gid, Vector2i(0, 32-tilesize.y))
			elif not rel_id in ts.tiles:
				gid += 1
				continue
			else:
				if rel_id in ts.tiles && "animation" in ts.tiles[rel_id]:
					var animated_tex = AnimatedTexture.new()
					animated_tex.frames = ts.tiles[rel_id].animation.size()
					animated_tex.fps = 0
					var c = 0
					#untested
					var image_path = ts.tiles[rel_id].image
					for g in ts.tiles[rel_id].animation:
						animated_tex.set_frame_texture(c, load_image(image_path, ts_source_path, options))
						animated_tex.set_frame_delay(c, float(g.duration) * 0.001)
						c += 1
					result.tile_set_texture(animated_tex)
					result.tile_set_region(gid, Rect2(Vector2(0, 0), tilesize))
				else:
					var image_path = ts.tiles[rel_id].image
					image = load_image(image_path, ts_source_path, options)
					if typeof(image) != TYPE_OBJECT:
						# Error happened
						return image
					result.tile_set_texture(image)
				if options.apply_offset:
					result.tile_set_texture_offset(gid, Vector2(0, 32-image.get_height()))
			if "tiles" in ts and rel_id in ts.tiles and "objectgroup" in ts.tiles[rel_id] \
					and "objects" in ts.tiles[rel_id].objectgroup:
				for object in ts.tiles[rel_id].objectgroup.objects:

					var shape = shape_from_object(object)

					if typeof(shape) != TYPE_OBJECT:
						# Error happened
						return shape

					var offset = Vector2(float(object.x), float(object.y))
					if "width" in object and "height" in object:
						offset += Vector2(float(object.width) / 2, float(object.height) / 2)

					result.tile_add_shape(gid, shape, Transform2D(0, offset), object.type == "one-way")

					var tileShape = PackedVector2Array([
							Vector2(-offset.x, -offset.y),
							Vector2(tilesize.x - offset.x, -offset.y),
							Vector2(tilesize.x - offset.x, tilesize.y - offset.y),
							Vector2(-offset.x, tilesize.y - offset.y)
					])

					var navOutlines = []
					var colShape = result.tile_get_shape(gid, 0)
					if colShape is ConvexPolygonShape2D:
						navOutlines = Geometry2D.clip_polygons(tileShape, colShape.get_points())
					elif colShape is ConcavePolygonShape2D:
						navOutlines = Geometry2D.clip_polygons(tileShape, colShape.get_segments())

					var shapeNav = NavigationPolygon.new()
					for navOutline in navOutlines:
						shapeNav.add_outline(navOutline)
					shapeNav.make_polygons_from_outlines()

#					result.tile_set_navigation_polygon(gid, shapeNav)
#					result.tile_set_navigation_polygon_offset(gid, offset)
			else:
				var tileShape = PackedVector2Array([
						Vector2(0, 0),
						Vector2(tilesize.x, 0),
						tilesize,
						Vector2(0, tilesize.y)
				])

				var shapeNav = NavigationPolygon.new()
				shapeNav.add_outline(tileShape)
				shapeNav.make_polygons_from_outlines()

				result.tile_set_navigation_polygon(gid, shapeNav)

			if "properties" in ts and "custom_material" in ts.properties:
				result.tile_set_material(gid, load(ts.properties.custom_material))

			if options.custom_properties and options.tile_metadata and "tileproperties" in ts \
					and "tilepropertytypes" in ts and rel_id in ts.tileproperties and rel_id in ts.tilepropertytypes:
				tile_meta[gid] = get_custom_properties(ts.tileproperties[rel_id], ts.tilepropertytypes[rel_id])
			if options.save_tiled_properties and rel_id in ts.tiles:
				for property in whitelist_properties:
					if property in ts.tiles[rel_id]:
						if not gid in tile_meta: tile_meta[gid] = {}
						tile_meta[gid][property] = ts.tiles[rel_id][property]

			gid += 1
			i += 1

		if str(ts.name) != "":
			result.resource_name = str(ts.name)

		if options.save_tiled_properties:
			set_tiled_properties_as_meta(result, ts)
		if options.custom_properties:
			if "properties" in ts and "propertytypes" in ts:
				set_custom_properties(result, ts)

	if options.custom_properties and options.tile_metadata:
		result.set_meta("tile_meta", tile_meta)

	return result


# Loads an image from a given path
# Returns a Texture
func load_image(rel_path, source_path, options):
	var embed = options.embed_internal_images if "embed_internal_images" in options else false

	var ext = rel_path.get_extension().to_lower()
	if ext != "png" and ext != "jpg":
		print_error("Unsupported image format: %s. Use PNG or JPG instead." % [ext])
		return ERR_FILE_UNRECOGNIZED

	var total_path = rel_path
	if rel_path.is_relative_path():
		total_path = ProjectSettings.globalize_path(source_path.get_base_dir()).path_join(rel_path)
	total_path = ProjectSettings.localize_path(total_path)

	var dir = Directory.new()
	if not dir.file_exists(total_path):
		print_error("Image not found: %s" % [total_path])
		return ERR_FILE_NOT_FOUND

	if not total_path.begins_with("res://"):
		# External images need to be embedded
		embed = true

	var image = null
	if embed:
		image = ImageTexture.new()
		image.load(total_path)
	else:
		image = ResourceLoader.load(total_path, "ImageTexture")

	return image

# Reads a file and returns its contents as a dictionary
# Returns an error code if fails
func read_file(path):
	if path.get_extension().to_lower() == "tmx":
		var tmx_to_dict = TiledXMLToDictionary.new()
		var data = tmx_to_dict.read_tmx(path)
		if typeof(data) != TYPE_DICTIONARY:
			# Error happened
			print_error("Error parsing map file '%s'." % [path])
		# Return error or result
		return data

	# Not TMX, must be JSON
	var file = File.new()
	var err = file.open(path, File.READ)
	if err != OK:
		return err


	var error = JSONInstance.parse(file.get_as_text())
	if error != OK:
		print_error("Error parsing JSON: " + error)
		return error

	return JSONInstance.get_data()

# Reads a tileset file and return its contents as a dictionary
# Returns an error code if fails
func read_tileset_file(path):
	if path.get_extension().to_lower() == "tsx":
		var tmx_to_dict = TiledXMLToDictionary.new()
		var data = tmx_to_dict.read_tsx(path)
		if typeof(data) != TYPE_DICTIONARY:
			# Error happened
			print_error("Error parsing map file '%s'." % [path])
		# Return error or result
		return data

	# Not TSX, must be JSON
	var file = File.new()
	var err = file.open(path, File.READ)
	if err != OK:
		return err

	var content = JSONInstance.parse(file.get_as_text())
	if content.error != OK:
		print_error("Error parsing JSON: " + content.error_string)
		return content.error

	return content.result

# Creates a shape from an object data
# Returns a valid shape depending on the object type (collision/occluder/navigation)
func shape_from_object(object):
	var shape = ERR_INVALID_DATA
	set_default_obj_params(object)

	if "polygon" in object or "polyline" in object:
		var vertices = PackedVector2Array()

		if "polygon" in object:
			for point in object.polygon:
				vertices.push_back(Vector2(float(point.x), float(point.y)))
		else:
			for point in object.polyline:
				vertices.push_back(Vector2(float(point.x), float(point.y)))

		if object.type == "navigation":
			shape = NavigationPolygon.new()
			shape.vertices = vertices
			shape.add_outline(vertices)
			shape.make_polygons_from_outlines()
		elif object.type == "occluder":
			shape = OccluderPolygon2D.new()
			shape.polygon = vertices
			shape.closed = "polygon" in object
		else:
			if is_convex(vertices):
				var sorter = PolygonSorter.new()
				vertices = sorter.sort_polygon(vertices)
				shape = ConvexPolygonShape2D.new()
				shape.points = vertices
			else:
				shape = ConcavePolygonShape2D.new()
				var segments = [vertices[0]]
				for x in range(1, vertices.size()):
					segments.push_back(vertices[x])
					segments.push_back(vertices[x])
				segments.push_back(vertices[0])
				shape.segments = PackedVector2Array(segments)

	elif "ellipse" in object:
		if object.type == "navigation" or object.type == "occluder":
			print_error("Ellipse shapes are not supported as navigation or occluder. Use polygon/polyline instead.")
			return ERR_INVALID_DATA

		if not "width" in object or not "height" in object:
			print_error("Missing width or height in ellipse shape.")
			return ERR_INVALID_DATA

		var w = abs(float(object.width))
		var h = abs(float(object.height))

		if w == h:
			shape = CircleShape2D.new()
			shape.radius = w / 2.0
		else:
			# Using a capsule since it's the closest from an ellipse
			shape = CapsuleShape2D.new()
			shape.radius = w / 2.0
			shape.height = h / 2.0

	else: # Rectangle
		if not "width" in object or not "height" in object:
			print_error("Missing width or height in rectangle shape.")
			return ERR_INVALID_DATA

		var size = Vector2(float(object.width), float(object.height))

		if object.type == "navigation" or object.type == "occluder":
			# Those types only accept polygons, so make one from the rectangle
			var vertices = PackedVector2Array([
					Vector2(0, 0),
					Vector2(size.x, 0),
					size,
					Vector2(0, size.y)
			])
			if object.type == "navigation":
				shape = NavigationPolygon.new()
				shape.vertices = vertices
				shape.add_outline(vertices)
				shape.make_polygons_from_outlines()
			else:
				shape = OccluderPolygon2D.new()
				shape.polygon = vertices
		else:
			shape = RectangleShape2D.new()
			shape.extents = size / 2.0

	return shape

# Determines if the set of vertices is convex or not
# Returns a boolean
func is_convex(vertices):
	var size = vertices.size()
	if size <= 3:
		# Less than 3 verices can't be concave
		return true

	var cp = 0

	for i in range(0, size + 2):
		var p1 = vertices[(i + 0) % size]
		var p2 = vertices[(i + 1) % size]
		var p3 = vertices[(i + 2) % size]

		var prev_cp = cp
		cp = (p2.x - p1.x) * (p3.y - p2.y) - (p2.y - p1.y) * (p3.x - p2.x)
		if i > 0 and sign(cp) != sign(prev_cp):
			return false

	return true

# Decompress the data of the layer
# Compression argument is a string, either "gzip" or "zlib"
func decompress_layer_data(layer_data, compression, map_size):
	if compression != "gzip" and compression != "zlib":
		print_error("Unrecognized compression format: %s" % [compression])
		return ERR_INVALID_DATA

	var compression_type = File.COMPRESSION_DEFLATE if compression == "zlib" else File.COMPRESSION_GZIP
	var expected_size = int(map_size.x) * int(map_size.y) * 4
	var raw_data = Marshalls.base64_to_raw(layer_data).decompress(expected_size, compression_type)

	return decode_layer(raw_data)

# Reads the layer as a base64 data
# Returns an array of ints as the decoded layer would be
func read_base64_layer_data(layer_data):
	var decoded = Marshalls.base64_to_raw(layer_data)
	return decode_layer(decoded)

# Reads a PoolByteArray and returns the layer array
# Used for base64 encoded and compressed layers
func decode_layer(layer_data):
	var result = []
	for i in range(0, layer_data.size(), 4):
		var num = (layer_data[i]) | \
				(layer_data[i + 1] << 8) | \
				(layer_data[i + 2] << 16) | \
				(layer_data[i + 3] << 24)
		result.push_back(num)
	return result

# Set the custom properties into the metadata of the object
func set_custom_properties(object, tiled_object):
	if not "properties" in tiled_object or not "propertytypes" in tiled_object:
		return

	var properties = get_custom_properties(tiled_object.properties, tiled_object.propertytypes)
	for property in properties:
		object.set_meta(property, properties[property])

# Get the custom properties as a dictionary
# Useful for tile meta, which is not stored directly
func get_custom_properties(properties, types):
	var result = {}

	for property in properties:
		var value = null
		if str(types[property]).to_lower() == "bool":
			value = bool(properties[property])
		elif str(types[property]).to_lower() == "int":
			value = int(properties[property])
		elif str(types[property]).to_lower() == "float":
			value = float(properties[property])
		elif str(types[property]).to_lower() == "color":
			value = Color(properties[property])
		else:
			value = str(properties[property])
		result[property] = value
	return result

# Get the available whitelisted properties from the Tiled object
# And them as metadata in the Godot object
func set_tiled_properties_as_meta(object, tiled_object):
	for property in whitelist_properties:
		if property in tiled_object:
			object.set_meta(property, tiled_object[property])

# Custom function to sort objects in an object layer
# This is done to support the "topdown" draw order, which sorts by 'y' coordinate
func object_sorter(first, second):
	if first.y == second.y:
		return first.id < second.id
	return first.y < second.y

# Validates the map dictionary content for missing or invalid keys
# Returns an error code
func validate_map(map):
	if not "type" in map or map.type != "map":
		print_error("Missing or invalid type property.")
		return ERR_INVALID_DATA
	elif not "version" in map or int(map.version) != 1:
		print_error("Missing or invalid map version.")
		return ERR_INVALID_DATA
	elif not "tileheight" in map or not str(map.tileheight).is_valid_int():
		print_error("Missing or invalid tileheight property.")
		return ERR_INVALID_DATA
	elif not "tilewidth" in map or not str(map.tilewidth).is_valid_int():
		print_error("Missing or invalid tilewidth property.")
		return ERR_INVALID_DATA
	elif not "layers" in map or typeof(map.layers) != TYPE_ARRAY:
		print_error("Missing or invalid layers property.")
		return ERR_INVALID_DATA
	elif not "tilesets" in map or typeof(map.tilesets) != TYPE_ARRAY:
		print_error("Missing or invalid tilesets property.")
		return ERR_INVALID_DATA
	if "orientation" in map and (map.orientation == "staggered" or map.orientation == "hexagonal"):
		if not "staggeraxis" in map:
			print_error("Missing stagger axis property.")
			return ERR_INVALID_DATA
		elif not "staggerindex" in map:
			print_error("Missing stagger axis property.")
			return ERR_INVALID_DATA
	return OK

# Validates the tileset dictionary content for missing or invalid keys
# Returns an error code
func validate_tileset(tileset):
	if not "firstgid" in tileset or not str(tileset.firstgid).is_valid_int():
		print_error("Missing or invalid firstgid tileset property.")
		return ERR_INVALID_DATA
	elif not "tilewidth" in tileset or not str(tileset.tilewidth).is_valid_int():
		print_error("Missing or invalid tilewidth tileset property.")
		return ERR_INVALID_DATA
	elif not "tileheight" in tileset or not str(tileset.tileheight).is_valid_int():
		print_error("Missing or invalid tileheight tileset property.")
		return ERR_INVALID_DATA
	elif not "tilecount" in tileset or not str(tileset.tilecount).is_valid_int():
		print_error("Missing or invalid tilecount tileset property.")
		return ERR_INVALID_DATA
	if not "image" in tileset:
		for tile in tileset.tiles:
			if not "image" in tileset.tiles[tile]:
				print_error("Missing or invalid image in tileset property.")
				return ERR_INVALID_DATA
			elif not "imagewidth" in tileset.tiles[tile] or not str(tileset.tiles[tile].imagewidth).is_valid_int():
				print_error("Missing or invalid imagewidth tileset property 1.")
				return ERR_INVALID_DATA
			elif not "imageheight" in tileset.tiles[tile] or not str(tileset.tiles[tile].imageheight).is_valid_int():
				print_error("Missing or invalid imageheight tileset property.")
				return ERR_INVALID_DATA
	else:
		if not "imagewidth" in tileset or not str(tileset.imagewidth).is_valid_int():
			print_error("Missing or invalid imagewidth tileset property 2.")
			return ERR_INVALID_DATA
		elif not "imageheight" in tileset or not str(tileset.imageheight).is_valid_int():
			print_error("Missing or invalid imageheight tileset property.")
			return ERR_INVALID_DATA
	return OK

# Validates the layer dictionary content for missing or invalid keys
# Returns an error code
func validate_layer(layer):
	if not "type" in layer:
		print_error("Missing or invalid type layer property.")
		return ERR_INVALID_DATA
	elif not "name" in layer:
		print_error("Missing or invalid name layer property.")
		return ERR_INVALID_DATA
	match layer.type:
		"tilelayer":
			if not "height" in layer or not str(layer.height).is_valid_int():
				print_error("Missing or invalid layer height property.")
				return ERR_INVALID_DATA
			elif not "width" in layer or not str(layer.width).is_valid_int():
				print_error("Missing or invalid layer width property.")
				return ERR_INVALID_DATA
			elif not "data" in layer:
				if not "chunks" in layer:
					print_error("Missing data or chunks layer properties.")
					return ERR_INVALID_DATA
				elif typeof(layer.chunks) != TYPE_ARRAY:
					print_error("Invalid chunks layer property.")
					return ERR_INVALID_DATA
			elif "encoding" in layer:
				if layer.encoding == "base64" and typeof(layer.data) != TYPE_STRING:
					print_error("Invalid data layer property.")
					return ERR_INVALID_DATA
				if layer.encoding != "base64" and typeof(layer.data) != TYPE_ARRAY:
					print_error("Invalid data layer property.")
					return ERR_INVALID_DATA
			elif typeof(layer.data) != TYPE_ARRAY:
				print_error("Invalid data layer property.")
				return ERR_INVALID_DATA
			if "compression" in layer:
				if layer.compression != "gzip" and layer.compression != "zlib":
					print_error("Invalid compression type.")
					return ERR_INVALID_DATA
		"imagelayer":
			if not "image" in layer or typeof(layer.image) != TYPE_STRING:
				print_error("Missing or invalid image path for layer.")
				return ERR_INVALID_DATA
		"objectgroup":
			if not "objects" in layer or typeof(layer.objects) != TYPE_ARRAY:
				print_error("Missing or invalid objects array for layer.")
				return ERR_INVALID_DATA
		"group":
			if not "layers" in layer or typeof(layer.layers) != TYPE_ARRAY:
				print_error("Missing or invalid layer array for group layer.")
				return ERR_INVALID_DATA
	return OK

func validate_chunk(chunk):
	if not "data" in chunk:
		print_error("Missing data chunk property.")
		return ERR_INVALID_DATA
	elif not "height" in chunk or not str(chunk.height).is_valid_int():
		print_error("Missing or invalid height chunk property.")
		return ERR_INVALID_DATA
	elif not "width" in chunk or not str(chunk.width).is_valid_int():
		print_error("Missing or invalid width chunk property.")
		return ERR_INVALID_DATA
	elif not "x" in chunk or not str(chunk.x).is_valid_int():
		print_error("Missing or invalid x chunk property.")
		return ERR_INVALID_DATA
	elif not "y" in chunk or not str(chunk.y).is_valid_int():
		print_error("Missing or invalid y chunk property.")
		return ERR_INVALID_DATA
	return OK

# Custom function to print error, to centralize the prefix addition
func print_error(err):
	printerr(error_prefix + err)

func get_template(path):
	# If this template has not yet been loaded
	if not _loaded_templates.has(path):
		# IS XML
		if path.get_extension().to_lower() == "tx":
			var parser = XMLParser.new()
			var err = parser.open(path)
			if err != OK:
				print_error("Error opening TX file '%s'." % [path])
				return err
			var content = parse_template(parser, path)
			if typeof(content) != TYPE_DICTIONARY:
				# Error happened
				print_error("Error parsing template map file '%s'." % [path])
				return false
			_loaded_templates[path] = content

		# IS JSON
		else:
			var file = File.new()
			var err = file.open(path, File.READ)
			if err != OK:
				return err

			var json_res = JSONInstance.parse(file.get_as_text())
			if json_res.error != OK:
				print_error("Error parsing JSON template map file '%s'." % [path])
				return json_res.error

			var result = json_res.result
			if typeof(result) != TYPE_DICTIONARY:
				print_error("Error parsing JSON template map file '%s'." % [path])
				return ERR_INVALID_DATA

			var object = result.object
			if object.has("gid"):
				if result.has("tileset"):
					var ts_path = remove_filename_from_path(path) + result.tileset.source
					var tileset_gid_increment = get_first_gid_from_tileset_path(ts_path) - 1
					object.gid += tileset_gid_increment

			_loaded_templates[path] = object

	var dict = _loaded_templates[path]
	var dictCopy = {}
	for k in dict:
		dictCopy[k] = dict[k]

	return dictCopy

func parse_template(parser, path):
	var err = OK
	# Template root node shouldn't have attributes
	var data = {}
	var tileset_gid_increment = 0
	data.id = 0

	err = parser.read()
	while err == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
			if parser.get_node_name() == "template":
				break

		elif parser.get_node_type() == XMLParser.NODE_ELEMENT:
			if parser.get_node_name() == "tileset":
				var ts_path = remove_filename_from_path(path) + parser.get_named_attribute_value_safe("source")
				tileset_gid_increment = get_first_gid_from_tileset_path(ts_path) - 1
				data.tileset = ts_path

			if parser.get_node_name() == "object":
				var object = TiledXMLToDictionary.parse_object(parser)
				for k in object:
					data[k] = object[k]

		err = parser.read()

	if data.has("gid"):
		data["gid"] += tileset_gid_increment

	return data

func get_first_gid_from_tileset_path(path):
	for t in _tileset_path_to_first_gid:
		if is_same_file(path, t):
			return _tileset_path_to_first_gid[t]

	return 0

static func get_filename_from_path(path):
	var substrings = path.split("/", false)
	var file_name = substrings[substrings.size() - 1]
	return file_name

static func remove_filename_from_path(path):
	var file_name = get_filename_from_path(path)
	var stringSize = path.length() - file_name.length()
	var file_path = path.substr(0,stringSize)
	return file_path

static func is_same_file(path1, path2):
	var file1 = File.new()
	var err = file1.open(path1, File.READ)
	if err != OK:
		return err

	var file2 = File.new()
	err = file2.open(path2, File.READ)
	if err != OK:
		return err

	var file1_str = file1.get_as_text()
	var file2_str = file2.get_as_text()

	if file1_str == file2_str:
		return true

	return false

static func apply_template(object, template_immutable):
	for k in template_immutable:
		# Do not overwrite any object data
		if typeof(template_immutable[k]) == TYPE_DICTIONARY:
			if not object.has(k):
				object[k] = {}
			apply_template(object[k], template_immutable[k])

		elif not object.has(k):
			object[k] = template_immutable[k]
