extends Button
class_name StateButton

@export var state : int 
@export var input_key : String = str(randi())
var saved_event : InputEvent
var state_name : String 

var midi_enabled : bool 

var midi_channel_enabled : bool
var midi_note_enabled : bool
var midi_velocity_enabled : bool
var midi_onoff_state_enabled : bool

var midi_channel : int
var midi_note : int
var midi_velocity : int
var midi_onoff_state : bool

static var selected_state : StateButton = null
static var other_states : Array[StateButton] = []

func _ready():
	if state_name.is_empty():
		state_name = str(state+1)
	text = state_name
	if state == 0:
		select_state()
	Global.key_pressed.connect(bg_key_pressed)

func _on_pressed():
	if Input.is_action_pressed("ctrl"):
		if selected_state == null && self not in other_states:
			select_state()
			Global.get_sprite_states(state)
			return
		elif selected_state != self && self not in other_states:
			other_states.append(self)
			%Selected.show()
			return
		elif selected_state == self && other_states.size() > 0:
			%Selected.hide()
			var placeholder = other_states[0]
			other_states.erase(placeholder)
			placeholder.get_node("%Selected").show()
			selected_state = placeholder
			Global.get_sprite_states(placeholder.state)
			return
		elif self in other_states:
			other_states.erase(self)
			%Selected.hide()
			return

	else:
		for i in other_states:
			i.get_node("%Selected").hide()
			
		other_states.clear()
		select_state()
		Global.get_sprite_states(state)

func initial_update():
	Global.get_sprite_states(state)

func select_state():
	if selected_state != null && is_instance_valid(selected_state):
		selected_state.get_node("%Selected").hide()
	selected_state = self
	%Selected.show()

func _input(event):
	if input_key != "Null" or input_key != "":
		if InputMap.has_action(input_key):
			if event.is_action_pressed(input_key):
				select_state()
				Global.get_sprite_states(state)
	if event is InputEventMIDI and midi_enabled:
		print_debug(event)
		handle_midi(event)

func handle_midi(event: InputEventMIDI) -> void:
	var message = event.message
	
	# hacky fix
	var clamped_channel = clamp(midi_channel, 1, 16)
	var clamped_note = clamp(midi_note, 1, 127)
	var clamped_velocity = clamp(midi_velocity, 1, 127)
	
	# bitwise flags for MIDIMessage enum
	var note_on_flags = MIDI_MESSAGE_NOTE_ON
	var note_off_flags = MIDI_MESSAGE_NOTE_OFF
	
	# if the message isnt none
	var isValidMessage = event.message != MIDI_MESSAGE_NONE
	
	var event_channel = event.channel + 1 # usually 0-15, make it 1-16 for consistency
	var event_note = event.pitch
	var event_velocity = event.velocity
	var event_state = (isValidMessage) && ((message & note_on_flags) == note_on_flags)
	
	print(state_name)
	
	if (midi_channel_enabled && clamped_channel != event_channel):
		print("failed channel")
		return
	if (midi_note_enabled && clamped_note != event_note):
		print("failed note")
		return
	if (midi_velocity_enabled && clamped_velocity != event_velocity):
		print("failed velocity")
		return
	# this one sucks -- basically if the message is ON and we want an OFF state, OR if the message is OFF and we want an ON state we should return
	if (midi_onoff_state_enabled && midi_onoff_state):
		if (midi_onoff_state != event_state):
			print("failed on " + str(midi_onoff_state) + " " + str(event_state))
			return
	if (midi_onoff_state_enabled && !midi_onoff_state):
		if (midi_onoff_state != event_state):
			print("failed off " + str(midi_onoff_state) + " " + str(event_state))
			return
	
	select_state()
	Global.get_sprite_states(state)

func bg_key_pressed(key):
	if InputMap.action_get_events(input_key).size() > 0:
		var inputs = InputMap.action_get_events(input_key)[0]
		if key == inputs.as_text():
			select_state()
			Global.get_sprite_states(state)

func update_stuff():
	if saved_event != null:
		InputMap.action_erase_events(input_key)
		InputMap.action_add_event(input_key, saved_event)

static func multi_edit(value, value_name, obj : SpriteObject, states : Array, should_change : bool = false, type : String = "x"):
	if other_states.size() > 0:
		for i in other_states:
			if i == null or !is_instance_valid(i):
				other_states.erase(i)
				continue
			if i.state in range(states.size()):
				if should_change:
					if type == "x":
						states[i.state][value_name].x = value
					else:
						states[i.state][value_name].y = value
				else:
					states[i.state][value_name] = value
			
			print(value_name)
	else:
		return
