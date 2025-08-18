extends Button
class_name RemapButton

@export var action: String 
var state_button : Node


func _init():
	toggle_mode = true
	theme_type_variation = "RemapButton"
	
	
func _ready():
	set_process_unhandled_input(false)
	update_key_text()


func _toggled(_button_pressed):
	set_process_unhandled_input(_button_pressed)
	if _button_pressed:
		text = "... Awaiting Input ..."
		release_focus()
	else:
		update_key_text()
		grab_focus()
		

func _unhandled_input(event):
	if not event is InputEventMouseMotion:
		if event.is_released():
			if StateButton.selected_state != null && is_instance_valid(StateButton.selected_state):
				InputMap.action_erase_events(StateButton.selected_state.input_key)
				InputMap.action_add_event(StateButton.selected_state.input_key, event)
				StateButton.selected_state.saved_event = event
				
			button_pressed = false
	

func update_key_text():
	if StateButton.selected_state != null && is_instance_valid(StateButton.selected_state):
		if InputMap.action_get_events(StateButton.selected_state.input_key).size() != 0:
			text = "%s" % InputMap.action_get_events(StateButton.selected_state.input_key)[0].as_text()
		else:
			text = "Null"

func update_stuff():
	if StateButton.selected_state != null && is_instance_valid(StateButton.selected_state):
		InputMap.action_erase_events(StateButton.selected_state.input_key)
		InputMap.action_add_event(StateButton.selected_state.input_key, state_button.saved_event)
	update_key_text()

func _on_remove_pressed():
	if StateButton.selected_state != null && is_instance_valid(StateButton.selected_state):
		if InputMap.action_get_events(StateButton.selected_state.input_key).size() != 0:
			InputMap.action_erase_events(StateButton.selected_state.input_key)
			update_key_text()

func _on_midi_enabled_toggled(toggled_on: bool) -> void:
	if StateButton.selected_state != null && is_instance_valid(StateButton.selected_state):
		StateButton.selected_state.midi_enabled = toggled_on

func _on_midi_channel_enabled_toggled(toggled_on: bool) -> void:
	if StateButton.selected_state != null && is_instance_valid(StateButton.selected_state):
		StateButton.selected_state.midi_channel_enabled = toggled_on

func _on_midi_note_enabled_toggled(toggled_on: bool) -> void:
	if StateButton.selected_state != null && is_instance_valid(StateButton.selected_state):
		StateButton.selected_state.midi_note_enabled = toggled_on

func _on_midi_velocity_enabled_toggled(toggled_on: bool) -> void:
	if StateButton.selected_state != null && is_instance_valid(StateButton.selected_state):
		StateButton.selected_state.midi_velocity_enabled = toggled_on

func _on_midi_onoff_enabled_toggled(toggled_on: bool) -> void:
	if StateButton.selected_state != null && is_instance_valid(StateButton.selected_state):
		StateButton.selected_state.midi_onoff_state_enabled = toggled_on

func _on_midi_channel_value_changed(value: float) -> void:
	if StateButton.selected_state != null && is_instance_valid(StateButton.selected_state):
		StateButton.selected_state.midi_channel = value

func _on_midi_note_value_changed(value: float) -> void:
	if StateButton.selected_state != null && is_instance_valid(StateButton.selected_state):
		StateButton.selected_state.midi_note = value

func _on_midi_velocity_value_changed(value: float) -> void:
	if StateButton.selected_state != null && is_instance_valid(StateButton.selected_state):
		StateButton.selected_state.midi_velocity = value

func _on_midi_on_off_toggled(toggled_on: bool) -> void:
	if StateButton.selected_state != null && is_instance_valid(StateButton.selected_state):
		StateButton.selected_state.midi_onoff_state = toggled_on
