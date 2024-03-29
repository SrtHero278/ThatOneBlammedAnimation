@tool extends Node

## Adding a texture into here will make a res file if an xml is found.
## Thanks to @what-is-a-git for the parser. (even tho i just yoinked it)
@export var sparrow_to_parse:CompressedTexture2D:
	set(texture):
		var base_path = texture.resource_path.get_basename()
		
		if not FileAccess.file_exists(base_path + ".xml"):
			printerr("XML FOR \"" + base_path + "\" WAS NOT FOUND.")
			return
			
		var frames:SpriteFrames = SpriteFrames.new()
		frames.remove_animation("default")
		
		var xml:XMLParser = XMLParser.new()
		xml.open(base_path + ".xml")
		
		var previous_atlas:AtlasTexture
		var previous_rect:Rect2
		
		while xml.read() == OK:
			if xml.get_node_type() != XMLParser.NODE_TEXT:
				var node_name:StringName = xml.get_node_name()
				
				if node_name.to_lower() == "subtexture":
					var frame_data:AtlasTexture
					
					var animation_name = xml.get_named_attribute_value("name")
					animation_name = animation_name.left(len(animation_name) - 4)
					
					var frame_rect:Rect2 = Rect2(
						Vector2(
							xml.get_named_attribute_value("x").to_float(),
							xml.get_named_attribute_value("y").to_float()
						),
						Vector2(
							xml.get_named_attribute_value("width").to_float(),
							xml.get_named_attribute_value("height").to_float()
						)
					)
					
					#Normally there would be a `if optimized` but i got rid of that
					if previous_rect == frame_rect:
						frame_data = previous_atlas
					else:
						frame_data = AtlasTexture.new()
						frame_data.atlas = texture
						frame_data.region = frame_rect
						
						if xml.has_attribute("frameX"):
							var margin:Rect2
							
							var raw_frame_x:int = xml.get_named_attribute_value("frameX").to_int()
							var raw_frame_y:int = xml.get_named_attribute_value("frameY").to_int()
							
							var raw_frame_width:int = xml.get_named_attribute_value("frameWidth").to_int()
							var raw_frame_height:int = xml.get_named_attribute_value("frameHeight").to_int()
							
							var frame_size_data:Vector2 = Vector2(
								raw_frame_width,
								raw_frame_height
							)
							
							if frame_size_data == Vector2.ZERO:
								frame_size_data = frame_rect.size
							
							margin = Rect2(Vector2(-raw_frame_x, -raw_frame_y),
									Vector2(raw_frame_width - frame_rect.size.x,
											raw_frame_height - frame_rect.size.y)
							)
							
							if margin.size.x < abs(margin.position.x):
								margin.size.x = abs(margin.position.x)
							if margin.size.y < abs(margin.position.y):
								margin.size.y = abs(margin.position.y)
							
							frame_data.margin = margin
						
						frame_data.filter_clip = true
						
						previous_atlas = frame_data
						previous_rect = frame_rect
					
					if not frames.has_animation(animation_name):
						frames.add_animation(animation_name)
						frames.set_animation_loop(animation_name, false)
						frames.set_animation_speed(animation_name, 24)
					
					frames.add_frame(animation_name, frame_data)

		ResourceSaver.save(frames, base_path + ".res", ResourceSaver.FLAG_COMPRESS)
		print("Parsed Spritesheet and Saved .res file at " + base_path + ".res")
	get:
		return null;
