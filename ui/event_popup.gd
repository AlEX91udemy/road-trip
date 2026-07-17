class_name EventPopup
extends CanvasLayer
## Pure presentation for roadside events, like Hud and GameOverScreen: it
## only knows how to show an EventData and report when the player is done
## with it. It builds one button per EventData.choices entry at runtime, so
## events with any number of choices work without touching this script.
##
## A choice with a non-empty message is shown as one extra beat (replace
## the description, wait for a single continue click) before closing —
## e.g. picking up the hitchhiker shows "Спасибо." A choice with no message
## closes immediately.

## The player is done with the current event (whatever they picked).
signal resolved

@export var title_label: Label
@export var description_label: Label
@export var choices_container: VBoxContainer

func _ready() -> void:
	visible = false


func open(event: EventData) -> void:
	title_label.text = event.title
	description_label.text = event.description
	_set_choice_buttons(event.choices)
	visible = true


func _set_choice_buttons(choices: Array[EventChoiceData]) -> void:
	# remove_child() first (immediate) then queue_free() (deferred): this
	# runs from inside a button's own `pressed` callback, so the button
	# being replaced can't be freed synchronously — but it must stop being
	# a child of choices_container right away, or a caller that inspects
	# the container in the same frame (e.g. immediately after picking a
	# choice) would still see it.
	for child in choices_container.get_children():
		choices_container.remove_child(child)
		child.queue_free()
	for choice in choices:
		_add_button(choice.label, _on_choice_pressed.bind(choice))


func _add_button(label: String, on_pressed: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.pressed.connect(on_pressed)
	choices_container.add_child(button)


func _on_choice_pressed(choice: EventChoiceData) -> void:
	if choice.message.is_empty():
		close()
		return
	description_label.text = choice.message
	_set_choice_buttons([])
	_add_button("...", close)


func close() -> void:
	visible = false
	_set_choice_buttons([])
	resolved.emit()
