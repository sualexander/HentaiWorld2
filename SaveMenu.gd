extends Node2D


const DOUBLE_CLICK_LENGTH: float = 0.3

var background: ColorRect
var confirmation
var buttons
var tween: Tween
var isLoad: bool
func start():
	background = get_node("Background")
	background.modulate = Color.BLACK
	background.material.set_shader_parameter("color1", Color(.35, 0, .18, 1))
	background.material.set_shader_parameter("color2", Color(.3, 0, .15, 1))
	background.material.set_shader_parameter("speed", Vector2(-0.5, -0.2))
	background.material.set_shader_parameter("rotationSpeed", 0.2)
	background.material.set_shader_parameter("center", Vector2(get_tree().root.content_scale_size / 2))
	
	var names: PackedStringArray = SaveSystem.saveData["Names"]
	buttons = background.get_node("VBoxContainer").get_children()
	for i in range(3):
		if names[i] == "": buttons[i].text = "Empty Slot"
		else: buttons[i].text = names[i]
		
		if isLoad && !SaveSystem.saveData["Slots"][i]:
			buttons[i].disabled = true
		else:
			buttons[i].light_mask = i
			buttons[i].pressed.connect(onClicked.bind(buttons[i]))
	
	confirmation = background.get_node("Panel")
	
	tween = get_tree().create_tween()
	tween.tween_property(background, "modulate", Color.WHITE, Globals.SCENE_FADE_TIME)
	await tween.finished

var clickTimer: Timer
var clickedButton: Button
func onClicked(button):
	if state == State.Default:
		if !isLoad: singleClick(button)
		elif !clickTimer || clickTimer.time_left == 0:
			clickTimer = Timer.new()
			add_child(clickTimer)
			clickTimer.start(DOUBLE_CLICK_LENGTH)
			clickTimer.timeout.connect(singleClick.bind(button))

func singleClick(button):
	if clickTimer: clickTimer.queue_free()
	clickedButton = button
	if isLoad:
		SaveSystem.currentSlot = button.light_mask
		levelSelect()
	else:
		if SaveSystem.saveData["Slots"][button.light_mask]:
			state = State.Confirming
			confirmation.visible = true
			for b: Button in buttons:
				b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			SaveSystem.newSave(button.light_mask)
			startEditing()

func onConfirm(cancel: bool):
	confirmation.visible = false
	for button in buttons:
		button.mouse_filter = Control.MOUSE_FILTER_STOP
	if cancel: state = State.Default
	else:
		SaveSystem.newSave(clickedButton.light_mask)
		startEditing()

func levelSelect():
	var newScene = load("res://LevelSelect.tscn").instantiate()
	tween = get_tree().create_tween()
	tween.tween_property(background, "modulate", Color.BLACK, Globals.SCENE_FADE_TIME)
	await tween.finished
	var oldScene = get_tree().root.get_node("SaveMenu")
	oldScene.call_deferred("free")
	get_tree().root.add_child(newScene)

enum State {Default, Confirming, Editing}
var state: State = State.Default
func _input(event):
	if state == State.Default:
		if isLoad && (event is InputEventMouseButton && event.double_click):
			for b in buttons:
				if !b.disabled && b.get_global_rect().has_point(event.position):
					if clickTimer: clickTimer.free()
					clickedButton = b
					startEditing()
					return
		elif Input.is_action_just_pressed("escape"):
			var newScene = load("res://MainMenu.tscn").instantiate()
			tween = get_tree().create_tween()
			tween.tween_property(background, "modulate", Color.BLACK, Globals.SCENE_FADE_TIME)
			await tween.finished
			var oldScene = get_tree().root.get_node("SaveMenu")
			oldScene.call_deferred("free")
			get_tree().root.add_child(newScene)
	elif state == State.Editing:
		if event is InputEventMouseButton && event.is_pressed():
			if !clickedButton.get_global_rect().has_point(event.position):
				finishEditing()
		elif event is InputEventKey:
			var key = event.keycode
			if event.pressed && (key == KEY_ESCAPE || key == KEY_ENTER):
				finishEditing()
			elif key == KEY_BACKSPACE:
				if clickedButton.text.length() > 0:
					clickedButton.text = clickedButton.text.substr(0, clickedButton.text.length() - 1)
			elif !event.echo && (event.unicode >= " ".unicode_at(0) && event.unicode <= "z".unicode_at(0)) &&\
			event.unicode != ":".unicode_at(0):
				clickedButton.text += char(event.unicode)
	else:
		if Input.is_action_just_pressed("escape"):
			onConfirm(true)

func startEditing():
	state = State.Editing
	clickedButton.modulate = Color.LIGHT_GRAY
	if isLoad:
		var index = clickedButton.text.rfind(":")
		if index:
			clickedButton.text = clickedButton.text.substr(0, index)
	else: clickedButton.text = "NewSave"
	for b in buttons:
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE

func finishEditing():
	SaveSystem.currentSlot = clickedButton.light_mask
	SaveSystem.updateSave(clickedButton.text)
	clickedButton.text = SaveSystem.saveData["Names"][SaveSystem.currentSlot]
	clickedButton.modulate = Color.WHITE
	if isLoad:
		for b in buttons:
			b.mouse_filter = Control.MOUSE_FILTER_STOP
		state = State.Default
	else:
		levelSelect()

func _process(delta):
	if tween && tween.is_running():
		background.material.set_shader_parameter("modulate", background.modulate)
