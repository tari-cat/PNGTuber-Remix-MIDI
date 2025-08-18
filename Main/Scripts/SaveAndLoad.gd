extends Node


var save_dict : Dictionary = {}
var thread : Thread = Thread.new()


func save_file(path):
	if Settings.theme_settings.use_threading:
		if !thread.is_alive():
			var _err = thread.start(save_model.bind(path))
	else:
		save_model(path)

func save_model(path):
	Global.save_path = path
	var sprites = get_tree().get_nodes_in_group("Sprites")
	var inputs = get_tree().get_nodes_in_group("StateButtons")
	
	
	var sprites_array : Array = []
	var input_array : Array = []
	for input in inputs:
		input_array.append({
			state_name = input.state_name,
			hot_key = input.saved_event,
			
			midi_enabled = input.midi_enabled,
			midi_channel_enabled = input.midi_channel_enabled,
			midi_note_enabled = input.midi_note_enabled,
			midi_velocity_enabled = input.midi_velocity_enabled,
			midi_onoff_state_enabled = input.midi_onoff_state_enabled,
			
			midi_channel = input.midi_channel,
			midi_note = input.midi_note,
			midi_velocity = input.midi_velocity,
			midi_onoff_state = input.midi_onoff_state
		})
	for sprt in sprites:
		sprt.save_state(Global.current_state)
		var img
		if sprt.is_apng:
			var exporter := AImgIOAPNGExporter.new()
			img = exporter.export_animation(sprt.frames, 10, self, "_progress_report", [])
			var normal_img
			if !sprt.frames2.is_empty():
				normal_img = exporter.export_animation(sprt.frames2, 10, self, "_progress_report", [])
			
			var cleaned_array = []
			
			for st in sprt.states:
				if !st.is_empty():
					cleaned_array.append(st)

		#	print(cleaned_array)
			
			var sprt_dict = {
				img = img,
				normal = normal_img,
				states = cleaned_array,
				is_apng = sprt.is_apng,
				sprite_name = sprt.sprite_name,
				sprite_id = sprt.sprite_id,
				parent_id = sprt.parent_id,
				sprite_type = sprt.sprite_type,
				is_asset = sprt.is_asset,
				saved_event = sprt.saved_event,
				was_active_before = sprt.was_active_before,
				should_disappear = sprt.should_disappear,
				saved_keys = sprt.saved_keys,
				show_only = sprt.show_only,
				is_collapsed = sprt.is_collapsed,
				is_premultiplied = true,
				layer_color = sprt.layer_color,
			}
			
			sprites_array.append(sprt_dict)
		else:
			if sprt.img_animated:
				img = sprt.anim_texture
			else:
				img = sprt.get_node("%Sprite2D").texture.diffuse_texture.get_image().save_png_to_buffer()
				
			var normal_img
			if sprt.get_node("%Sprite2D").texture.normal_texture:
				if sprt.img_animated:
					normal_img = sprt.anim_texture_normal
				else:
					normal_img = sprt.get_node("%Sprite2D").texture.normal_texture.get_image().save_png_to_buffer()
			
			var cleaned_array = []
			
			for st in sprt.states:
				if !st.is_empty():
					cleaned_array.append(st)

		#	print(cleaned_array)
			var sprt_dict = {
				img = img,
				normal = normal_img,
				image_data = sprt.image_data,
				normal_data = sprt.normal_data,
				states = cleaned_array,
				img_animated = sprt.img_animated,
				sprite_name = sprt.sprite_name,
				sprite_id = sprt.sprite_id,
				parent_id = sprt.parent_id,
				sprite_type = sprt.sprite_type,
				is_asset = sprt.is_asset,
				saved_event = sprt.saved_event,
				was_active_before = sprt.was_active_before,
				should_disappear = sprt.should_disappear,
				show_only = sprt.show_only,
				saved_keys = sprt.saved_keys,
				is_collapsed = sprt.is_collapsed,
				is_premultiplied = true,
				layer_color = sprt.layer_color,
			}
			sprites_array.append(sprt_dict)
		
	save_dict = {
		version = Global.version,
		sprites_array = sprites_array,
		settings_dict = Global.settings_dict,
		input_array = input_array,
	}
	Settings.save()
	var file = FileAccess.open(path,FileAccess.WRITE)
#	if FileAccess.file_exists(path):
	#	print(file.get_var())
	
	file.store_var(save_dict, true)
	file.close()
	if Settings.theme_settings.use_threading:
		thread.call_deferred("wait_to_finish")

func load_file(path: String, autoload : bool = false):
	if autoload:
		Settings.theme_settings.path = path
		Settings.save()
	if Settings.theme_settings.use_threading:
		if !thread.is_alive():
			if path.get_extension() == "save":
				var _err = thread.start(load_pngplus_file.bind(path))
			else:
				var _err = thread.start(load_model.bind(path))
	else:
		if path.get_extension() == "save":
			load_pngplus_file(path)
		else:
			load_model(path)

func load_model(path : String):
	Global.delete_states.emit()
	Global.main.clear_sprites()
	
	Global.main.get_node("Timer").start()
	Global.delete_states.emit()
	await Global.main.get_node("Timer").timeout
	
	var file = FileAccess.open(path, FileAccess.READ)
	var load_dict = file.get_var(true)
	file.close()
	
	if !load_dict.has("sprites_array"):
		return
	
	var file_version := ""
	if "version" in load_dict:
		file_version = load_dict.version
	
	if file_version != Global.version:
		if not path.begins_with("res://"):
			save_backup(load_dict, path)
			await get_tree().process_frame
		
		load_dict = VersionConverter.convert_save(load_dict, file_version)
		await get_tree().process_frame
		
		if OS.has_feature("editor") or not path.begins_with("res://"):
			var new_file := FileAccess.open(path, FileAccess.WRITE)
			new_file.store_var(load_dict, true)
			new_file.close()
			await get_tree().process_frame
	
	Global.settings_dict.merge(load_dict.settings_dict, true)
	if Global.settings_dict.monitor != Monitor.ALL_SCREENS:
		if Global.settings_dict.monitor >= DisplayServer.get_screen_count():
			Global.settings_dict.monitor = Monitor.ALL_SCREENS
	
	Global.remake_states.emit(load_dict.settings_dict.states)
	
	if not path.begins_with("res://"):
		Global.save_path = path
	
	for sprite in load_dict.sprites_array:
		var sprite_obj
		if sprite.has("sprite_type"):
			if sprite.sprite_type == "Sprite2D":
				sprite_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
			elif sprite.sprite_type == "WiggleApp":
				sprite_obj = preload("res://Misc/AppendageObject/Appendage_object.tscn").instantiate()
				
		else:
			sprite_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
			
		var cleaned_array = []
		
		for st in sprite.states:
			if !st.is_empty():
				cleaned_array.append(st)
				
		for st in cleaned_array:
			var new_dict = sprite_obj.sprite_data.duplicate()
			new_dict.merge(st, true)
			st = new_dict
			
		sprite_obj.states.clear()
		sprite_obj.states = cleaned_array
		sprite_obj.layer_color = sprite.get("layer_color", Color.BLACK)
		
		
		if sprite.has("is_asset"):
			sprite_obj.is_asset = sprite.is_asset
			sprite_obj.saved_event = sprite.saved_event
			sprite_obj.should_disappear = sprite.should_disappear
			if sprite.has("show_only"):
				sprite_obj.show_only = sprite.show_only
			sprite_obj.get_node("%Drag").visible = sprite.was_active_before
			sprite_obj.was_active_before = sprite.was_active_before
			sprite_obj.saved_keys = sprite.saved_keys
			if !InputMap.has_action(str(sprite.sprite_id)):
				InputMap.add_action(str(sprite.sprite_id))
				if sprite_obj.saved_event != null:
					InputMap.action_add_event(str(sprite.sprite_id), sprite_obj.saved_event)
				
		if sprite.has("is_apng"):
			load_apng(sprite_obj, sprite)
		else:
			if sprite.has("img_animated"):
				if sprite.img_animated:
					load_gif(sprite_obj, sprite)
				else:
					load_sprite(sprite_obj, sprite)
			else:
				
				
				load_sprite(sprite_obj, sprite)

		if sprite.has("image_data"):
			sprite_obj.image_data = sprite.image_data 
			sprite_obj.normal_data = sprite.normal_data 
			
		sprite_obj.sprite_id = sprite.sprite_id
		if sprite.parent_id != null:
			sprite_obj.parent_id = sprite.parent_id
		sprite_obj.sprite_name = sprite.sprite_name
		if sprite.has("is_collapsed"):
			sprite_obj.is_collapsed = sprite.is_collapsed
		Global.sprite_container.add_child(sprite_obj)
		sprite_obj.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT

	if !load_dict.input_array.is_empty():
		for input in len(load_dict.input_array):
			if load_dict.input_array[input] is Dictionary:
				get_tree().get_nodes_in_group("StateButtons")[input].saved_event = load_dict.input_array[input].hot_key
				get_tree().get_nodes_in_group("StateButtons")[input].state_name = load_dict.input_array[input].state_name
				get_tree().get_nodes_in_group("StateButtons")[input].text = load_dict.input_array[input].state_name
				if (load_dict.input_array[input].get("midi_enabled") != null): # backwards compat
					get_tree().get_nodes_in_group("StateButtons")[input].midi_enabled = load_dict.input_array[input].midi_enabled
					get_tree().get_nodes_in_group("StateButtons")[input].midi_channel_enabled = load_dict.input_array[input].midi_channel_enabled
					get_tree().get_nodes_in_group("StateButtons")[input].midi_note_enabled = load_dict.input_array[input].midi_note_enabled
					get_tree().get_nodes_in_group("StateButtons")[input].midi_velocity_enabled = load_dict.input_array[input].midi_velocity_enabled
					get_tree().get_nodes_in_group("StateButtons")[input].midi_onoff_state_enabled = load_dict.input_array[input].midi_onoff_state_enabled
					
					get_tree().get_nodes_in_group("StateButtons")[input].midi_channel = load_dict.input_array[input].midi_channel
					get_tree().get_nodes_in_group("StateButtons")[input].midi_note = load_dict.input_array[input].midi_note
					get_tree().get_nodes_in_group("StateButtons")[input].midi_velocity = load_dict.input_array[input].midi_velocity
					get_tree().get_nodes_in_group("StateButtons")[input].midi_onoff_state = load_dict.input_array[input].midi_onoff_state
				get_tree().get_nodes_in_group("StateButtons")[input].update_stuff()
			else:
				get_tree().get_nodes_in_group("StateButtons")[input].saved_event = load_dict.input_array[input]
				get_tree().get_nodes_in_group("StateButtons")[input].update_stuff()
				

	var state_count = get_tree().get_nodes_in_group("StateButtons").size()
	for i in get_tree().get_nodes_in_group("Sprites"):
		if i.states.size() != state_count:
			for l in abs(i.states.size() - state_count):
				i.states.append({})
	Global.load_sprite_states(0)
	Global.remake_layers.emit()
	Global.reparent_objects.emit(get_tree().get_nodes_in_group("Sprites"))
	Global.slider_values.emit(Global.settings_dict)
	Global.load_sprite_states(0)
	if Global.main.has_node("%Control"):
		Global.reinfoanim.emit()
	Settings.save()
	
	if Global.settings_dict.anti_alias:
		Global.sprite_container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	else:
		Global.sprite_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	
	if Global.settings_dict.auto_save:
		Settings.save_timer.wait_time = Global.settings_dict.auto_save_timer * 60
		Settings.save_timer.start()
	else:
		Settings.save_timer.stop()

	Global.main.get_node("%Marker").current_screen = Global.settings_dict.monitor
	Global.load_model.emit()
	if Settings.theme_settings.use_threading:
		thread.call_deferred("wait_to_finish")

func save_backup(data: Dictionary, previous_path: String) -> void:
	var base_path := previous_path.get_basename()
	var extension := "." + previous_path.get_extension()
	base_path += "_backup"
	
	var counter: int = 1
	var path := base_path + extension
	while FileAccess.file_exists(path):
		counter += 1
		path = base_path + str(counter) + extension
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_var(data, true)

func load_sprite(sprite_obj, sprite):
	var img_data
	var img = Image.new()

	if sprite.img is not PackedByteArray:
		img_data = Marshalls.base64_to_raw(sprite.img)
		img.load_png_from_buffer(img_data)
	else:
		img.load_png_from_buffer(sprite.img)
		
	if sprite.has("is_premultiplied") == false:
		img.fix_alpha_edges()
	var img_tex = ImageTexture.new()
	img_tex.set_image(img)
	var img_can = CanvasTexture.new()
	img_can.diffuse_texture = img_tex
	if sprite.has("normal"):
		var normalBytes = sprite.normal
		if normalBytes != null:
			var nimg = Image.new()
			if sprite.normal is not PackedByteArray:
				var img_normal = Marshalls.base64_to_raw(sprite.normal)
				nimg.load_png_from_buffer(img_normal)
			else:
				nimg.load_png_from_buffer(sprite.normal)
			nimg.fix_alpha_edges()
			var nimg_tex = ImageTexture.new()
			nimg_tex.set_image(nimg)
			img_can.normal_texture = nimg_tex
	sprite_obj.get_node("%Sprite2D").texture = img_can

func load_trimmed_sprite(sprite_obj, sprite):
	var img_data
	

	if sprite.img is not PackedByteArray:
		img_data = Marshalls.base64_to_raw(sprite.img)
	else:
		img_data = sprite.img
	
	Global.main.get_node("%FileImporter").trim = true
	var img_can = Global.main.get_node("%FileImporter").import_png_from_buffer(img_data, "", sprite_obj)

	# Adjust position to keep image visually stable
	#sprite_obj.sprite_data.offset += Vector2(center_shift_x, center_shift_y)
#	sprite_obj.get_node("%Sprite2D").position += Vector2(center_shift_x, center_shift_y)
#	for i in sprite_obj.states:
	#	i.offset += Vector2(center_shift_x, center_shift_y)
	sprite_obj.get_node("%Sprite2D").texture = img_can

func load_apng(sprite_obj, sprite):
	var img = AImgIOAPNGImporter.load_from_buffer(sprite.img)
	var tex = img[1] as Array[AImgIOFrame]
	sprite_obj.frames = tex
	
	for n in sprite_obj.frames:
		if sprite.has("is_premultiplied") == false:
			n.content.fix_alpha_edges()
	
	var cframe: AImgIOFrame = sprite_obj.frames[0]
	
	var text = ImageTexture.create_from_image(cframe.content)
	var img_can = CanvasTexture.new()
	img_can.diffuse_texture = text
	if sprite.normal:
		var norm = AImgIOAPNGImporter.load_from_buffer(sprite.normal)
		var texn = norm[1] as Array[AImgIOFrame]
		sprite_obj.frames2 = texn
		for n in sprite_obj.frames2:
			n.content.fix_alpha_edges()
		#	n.content.premultiply_alpha()
		
		var cframe2: AImgIOFrame = sprite_obj.frames2[0]
		var text2 = ImageTexture.create_from_image(cframe2.content)
		img_can.normal_texture = text2
		
	for i in sprite_obj.frames:
		var new_frame : AnimatedFrame = AnimatedFrame.new()
		new_frame.texture = ImageTexture.create_from_image(i.content)
		new_frame.duration = i.duration
		sprite_obj.get_node("%AnimatedSpriteTexture").frames.append(new_frame)
	for i in sprite_obj.frames2:
		var new_frame : AnimatedFrame = AnimatedFrame.new()
		new_frame.texture = ImageTexture.create_from_image(i.content)
		new_frame.duration = i.duration
		sprite_obj.get_node("%AnimatedSpriteTexture").frames2.append(new_frame)

	sprite_obj.get_node("%Sprite2D").texture = img_can
	sprite_obj.is_apng = true
	sprite_obj.get_node("%Sprite2D").texture = img_can

func load_gif(sprite_obj, sprite):
	var gif_tex : SpriteFrames = GifManager.sprite_frames_from_buffer(sprite.img)
	var img_can = CanvasTexture.new()
	for n in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
		gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], n).get_image().fix_alpha_edges()
		
	var text = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], 0).get_image())
	img_can.diffuse_texture = text
	sprite_obj.get_node("%AnimatedSpriteTexture").frames.clear()
	for i in gif_tex.get_frame_count(gif_tex.get_animation_names()[0]):
		var new_frame : AnimatedFrame = AnimatedFrame.new()
		new_frame.texture = ImageTexture.create_from_image(gif_tex.get_frame_texture(gif_tex.get_animation_names()[0], i).get_image())
		new_frame.duration = gif_tex.get_frame_duration(gif_tex.get_animation_names()[0], i)/24
		sprite_obj.get_node("%AnimatedSpriteTexture").frames.append(new_frame)
	sprite_obj.anim_texture = sprite.img
	sprite_obj.img_animated = true
	sprite_obj.is_apng = false
	
	
	if sprite.has("normal"):
		var gif_normal : SpriteFrames = GifManager.sprite_frames_from_buffer(sprite.normal)
		
		for n in gif_normal.get_frame_count(gif_normal.get_animation_names()[0]):
			gif_normal.get_frame_texture(gif_normal.get_animation_names()[0], n).get_image().fix_alpha_edges()
		
		sprite_obj.anim_texture_normal = sprite.normal
		var text_normal = ImageTexture.create_from_image(gif_normal.get_frame_texture(gif_normal.get_animation_names()[0], 0).get_image())
		img_can.normal_texture = text_normal
		sprite_obj.get_node("%AnimatedSpriteTexture").frames2.clear()
		for i in gif_normal.get_frame_count(gif_normal.get_animation_names()[0]):
			var new_frame : AnimatedFrame = AnimatedFrame.new()
			new_frame.texture = ImageTexture.create_from_image(gif_normal.get_frame_texture(gif_normal.get_animation_names()[0], i).get_image())
			new_frame.duration = gif_normal.get_frame_duration(gif_normal.get_animation_names()[0], i)/24
			sprite_obj.get_node("%AnimatedSpriteTexture").frames2.append(new_frame)
			
	sprite_obj.get_node("%Sprite2D").texture = img_can

func load_pngplus_file(path):
	Global.delete_states.emit()
	Global.main.clear_sprites()
	
	Global.main.get_node("Timer").start()
	await Global.main.get_node("Timer").timeout
	
	
	
	var file = FileAccess.open(path, FileAccess.READ)
	var load_dict = JSON.parse_string(file.get_as_text())
	
	file.close()
	file = null
	
	
	if load_dict.size() < 1:
		return
	if !load_dict["0"].has("identification"):
		print("Failed")
		return
		
	for i in load_dict:
		var sprite_obj = preload("res://Misc/SpriteObject/sprite_object.tscn").instantiate()
		var img_data = Marshalls.base64_to_raw(load_dict[i]["imageData"])
		if (load_dict[i]["frames"] > 1): #If animated, we don't want to trim the sprite
			var img = Image.new()
			img.load_png_from_buffer(img_data)
			var img_tex = ImageTexture.new()
			img_tex.set_image(img)
			var img_can = CanvasTexture.new()
			img_can.diffuse_texture = img_tex
			sprite_obj.get_node("%Sprite2D").texture = img_can
		else:
			var img_can = Global.main.get_node("%FileImporter").import_png_from_buffer(img_data, sprite_obj)
			sprite_obj.get_node("%Sprite2D").texture = img_can
		
	#	'''
	
		sprite_obj.is_plus_first_import = true
		sprite_obj.sprite_id = load_dict[i]["identification"]
		var id = load_dict[i].get("parentId", 0)
		if id == null:
			id = 0
		
		sprite_obj.parent_id = id
		sprite_obj.sprite_name = load_dict[i]["path"].get_file().trim_suffix(".png")
		
		sprite_obj.sprite_data.xFrq = load_dict[i]["xFrq"]
		sprite_obj.sprite_data.xAmp = float(load_dict[i]["xAmp"])
		sprite_obj.sprite_data.yFrq = load_dict[i]["yFrq"]
		sprite_obj.sprite_data.yAmp = float(load_dict[i]["yAmp"])
		sprite_obj.sprite_data.dragSpeed = load_dict[i]["drag"]
		sprite_obj.sprite_data.rdragStr = load_dict[i]["rotDrag"]
		sprite_obj.sprite_data.stretchAmount = load_dict[i]["stretchAmount"]
		sprite_obj.sprite_data.ignore_bounce = load_dict[i]["ignoreBounce"]
		sprite_obj.sprite_data.hframes = load_dict[i]["frames"]

		# convert PLUS animSpeed into Remix animation_speed (animation fps)
		# This assumes PLUS was set to thhe default Engine.max_fps of 60.
		var animSpeed = load_dict[i]["animSpeed"]
		if (animSpeed != 0.0) :
			sprite_obj.sprite_data.animation_speed = 60 / int(360.0 / float(animSpeed))
		
		if load_dict[i]["clipped"]:
			sprite_obj.sprite_data.clip = 2
		else:
			sprite_obj.sprite_data.clip = 0
		
		sprite_obj.sprite_data.rLimitMin = load_dict[i]["rLimitMin"]
		sprite_obj.sprite_data.rLimitMax = load_dict[i]["rLimitMax"]
		sprite_obj.sprite_data.z_index = load_dict[i]["zindex"]
		sprite_obj.sprite_data.position = str_to_var(load_dict[i]["pos"])
		sprite_obj.sprite_data.offset += str_to_var(load_dict[i]["offset"])

		var test = load_dict[i]["showBlink"]
		var test2 = load_dict[i]["showTalk"]
		
		if test == 0:
			sprite_obj.sprite_data.should_blink = false
			sprite_obj.sprite_data.open_eyes = false
		elif test == 1:
			sprite_obj.sprite_data.should_blink = true
			sprite_obj.sprite_data.open_eyes = true
		elif test == 2:
			sprite_obj.sprite_data.should_blink = true
			sprite_obj.sprite_data.open_eyes = false
		
		if test2 == 0:
			sprite_obj.sprite_data.should_talk = false
			sprite_obj.sprite_data.open_mouth = false
		elif test2 == 1:
			sprite_obj.sprite_data.should_talk = true
			sprite_obj.sprite_data.open_mouth = false
		elif test2 == 2:
			sprite_obj.sprite_data.should_talk = true
			sprite_obj.sprite_data.open_mouth = true
			
		
		sprite_obj.states = [{}]
		sprite_obj.states[0].merge(sprite_obj.sprite_data, true)
		
		var costume = str_to_var(load_dict[i]["costumeLayers"])
	#	print(costume)
		
		sprite_obj.states.resize(10)
		for l in costume.size():
			var ndict = sprite_obj.sprite_data.duplicate()
			if costume[l] == 0:
				ndict.visible = false
			else:
				ndict.visible = true
			sprite_obj.states[int(l)] = ndict
		Global.sprite_container.add_child(sprite_obj)
		sprite_obj.get_node("%Sprite2D/Grab").anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
		
	Global.remake_for_plus.emit()

	
	Global.load_sprite_states(0)
	Global.remake_layers.emit()
	Global.slider_values.emit(Global.settings_dict)
	Global.reparent_objects.emit(get_tree().get_nodes_in_group("Sprites"))
	for i in get_tree().get_nodes_in_group("Sprites"):
		i.zazaza(get_tree().get_nodes_in_group("Sprites"))
	
	Global.settings_dict.should_delta = false
	Global.load_sprite_states(0)
	Global.reinfoanim.emit()
	Global.main.get_node("%Marker").current_screen = Monitor.ALL_SCREENS
	Global.load_model.emit()
	if Settings.theme_settings.use_threading:
		thread.call_deferred("wait_to_finish")
