extends Node
class_name AnimatedSpriteTexture

@export var actor : Node
@export var sprite_node : Node
@export var frames : Array[AnimatedFrame]
@export var frames2 : Array[AnimatedFrame]
var index : int = 0
var dt : float = 0
var played_once : bool = false

func _physics_process(delta):
	var cframe2
	if actor.is_apng or actor.img_animated:
		if !played_once:
			if len(frames) == 0:
				return
			if index >= len(frames):
				if actor.get_value("one_shot"):
					played_once = true
					return
				index = 0
			dt += delta
			var cframe = frames[index]
			if sprite_node.texture.normal_texture:
				if index in range(frames2.size()):
					cframe2 = frames2[index]
			if dt >= cframe.duration:
				dt -= cframe.duration
				index += 1
			# yes this does this every _process, oh well
			sprite_node.texture.diffuse_texture = cframe.texture
			if sprite_node.texture.normal_texture:
				if frames2.size() != frames.size():
					frames2.resize(frames.size())
				if cframe2 != null:
					sprite_node.texture.normal_texture = cframe2.texture


func proper_apng_one_shot():
	dt = 0
	var cframe = frames[0]
	sprite_node.texture.diffuse_texture = cframe.texture
	if sprite_node.texture.normal_texture:
		var cframe2 = frames2[0]
		sprite_node.texture.normal_texture = cframe2.texture
