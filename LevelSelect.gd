extends Node2D


const FOOTER_HEIGHT: int = 160
const NAME_SIZE: int = 32
const MARGIN: int = 120
const BUTTON_SIZE: float = 0.25
const BUTTON_TILT := Vector2(2, 2.5)
const ICON_SIZE: float = 1.5
const ICON_TEXTURE := preload("res://Textures/HeartIcon.png")
const LOCK_TEXTURE := preload("res://Textures/LockIcon.png")

var save: Dictionary
var levelKeys = []
func _ready():
	save = SaveSystem.saveData["Slots"][SaveSystem.currentSlot]
	levelKeys = SaveSystem.levelData.keys()
	assert(levelKeys == save.keys())
	initializeUI()

var backgroundTween: Tween
var background: ColorRect
var footer: ColorRect
var nameLabel: Label
var nameIcon: TextureRect
var backButton: TextureButton
var nextButton: TextureButton
func initializeUI():
	var resolution = get_tree().root.content_scale_size
	
	background = ColorRect.new()
	background.size = resolution
	background.color = Color.HOT_PINK
	background.material = load("res://Dressing/RepeatingBackground.tres")
	background.material.set_shader_parameter("color1", Color(1, .4, .63, 1))
	background.material.set_shader_parameter("color2", Color(1, .51, .7, 1))
	background.material.set_shader_parameter("speed", Vector2(0.1, .025))
	background.material.set_shader_parameter("checkerSize", 130)
	footer = ColorRect.new()
	footer.color = Color(0.05, 0.05, 0.1, .85)
	footer.size = Vector2(resolution.x, FOOTER_HEIGHT)
	footer.position = Vector2(0, resolution.y - FOOTER_HEIGHT)
	background.add_child(footer)
	
	nameIcon = TextureRect.new()
	nameIcon.texture = ICON_TEXTURE
	nameIcon.position = Vector2(MARGIN / 2, MARGIN / 2.5)
	nameIcon.scale = Vector2.ONE * ((NAME_SIZE / nameIcon.size.y) * 1.5)
	nameLabel = Label.new()
	nameLabel.add_theme_font_size_override("font_size", NAME_SIZE)
	nameLabel.add_theme_font_override("font", load("res://Dressing/LibreBodoni-Bold.otf"))
	nameLabel.position = nameIcon.position + Vector2(NAME_SIZE * 2, 4)
	nameLabel.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	nameLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	nameLabel.text = "Choose Your Love"
	background.add_child(nameIcon)
	background.add_child(nameLabel)
	
	backButton = createButton("res://Textures/Back.png", Vector2(MARGIN, 16), onBackClicked)
	backButton.scale = Vector2.ONE * 0.3
	backButton.disabled = true
	backButton.modulate = Color.DIM_GRAY
	footer.add_child(backButton)
	nextButton = createButton("res://Textures/Next.png", Vector2(1490, 16), onNextClicked)
	nextButton.scale = backButton.scale
	footer.add_child(nextButton)
	
	makeLevels()
	loadSaveData()
	showPage()
	
	background.modulate = Color.BLACK
	add_child(background)
	backgroundTween = get_tree().create_tween()
	backgroundTween.tween_property(background, "modulate", Color.WHITE, Globals.SCENE_FADE_TIME)
	await backgroundTween.finished

func loadSaveData():
	assert(levelButtons.size() == levelKeys.size())
	unlockLevel(0)
	unlockLevel(2)
	for i in range(0, levelButtons.size()):
		var numSolved: int = save[levelKeys[i]]
		if numSolved == 0: continue
		var icons = levelButtons[i].get_children()
		var counter: int = 0
		var numIcons = icons.size() - 1
		for n in range(numIcons, -1, -1):
			if icons[n].name == "LockIcon": icons[n].queue_free()
			elif counter < numSolved:
				counter += 1
				icons[n].modulate = Color.DEEP_PINK
		if numSolved == numIcons: unlockLevel(i + 1)

var levelButtons = []
func makeLevels():
	var resolution := get_tree().root.content_scale_size
	var buttonWidth := resolution.x * BUTTON_SIZE
	var buttonHeight := resolution.y * BUTTON_SIZE
	var horizontal := (resolution.x - (2 * MARGIN) - (3 * buttonWidth)) / 2
	var vertical := (resolution.y - FOOTER_HEIGHT - (2 * MARGIN) - (2 * buttonHeight))
	for i in range(levelKeys.size()):
		var x: float = MARGIN + ((i % 6) % 3) * (buttonWidth + horizontal)
		var y: float = (MARGIN * 1.2) + ((i % 6) / 3) * (buttonHeight + vertical)
		
		var path
		var level = SaveSystem.levelData[levelKeys[i]]
		var numSolved: int = save[levelKeys[i]]
		var counter: int = 0
		for puzzle in level:
			if puzzle.has("texture"): path = puzzle["texture"]
			if counter == numSolved: break
			if puzzle.has("size"): counter += 1
		var button = createButton(path, Vector2(x,y), onLevelClicked)
		levelButtons.append(button)
		button.light_mask = i
		button.z_index = 2
		
		button.scale = Vector2.ONE * (buttonWidth / button.size.x)
		button.self_modulate = Color(0.4, 0.4, 0.425, 1)
		button.visible = false
		button.disabled = true
		
		var lock := TextureRect.new()
		lock.name = "LockIcon"
		lock.texture = LOCK_TEXTURE
		lock.modulate = Color(0.8, 1, 0.8, 0.75)
		lock.scale = Vector2.ONE * 0.2
		lock.position = Vector2.ONE * 6
		button.add_child(lock)
		
		var numPuzzles = getNumPuzzles(levelKeys[i])
		for n in range(numPuzzles):
			var icon = TextureRect.new()
			icon.texture = ICON_TEXTURE
			icon.scale = Vector2.ONE * ICON_SIZE
			icon.position = Vector2(button.size.x - 30 - (170 * (n + 1)), button.size.y - 200) #child size does not make sense just hardcode
			icon.visible = false
			button.add_child(icon)

		background.add_child(button)

func unlockLevel(index: int):
	levelButtons[index].disabled = false
	levelButtons[index].self_modulate = Color.WHITE
	var icons = levelButtons[index].get_children()
	for icon in icons:
		if icon.name == "LockIcon": icon.queue_free()
		icon.visible = true

func getNumPuzzles(key: String) -> int:
	var puzzles = SaveSystem.levelData[key]
	var counter: int = 0
	for puzzle: Dictionary in puzzles:
		if puzzle.has("size"): counter += 1
	return counter

func createButton(texturePath: String, pos: Vector2, onClicked: Callable) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = load(texturePath)
	button.position = pos
	button.mouse_entered.connect(onButtonEntered.bind(button))
	button.mouse_exited.connect(onButtonExited.bind(button))
	button.pressed.connect(onClicked.bind(button))
	return button

func onButtonEntered(button: TextureButton):
	if !button.disabled:
		button.modulate = Color.DARK_GRAY
		var index: int = levelButtons.find(button)
		if index != -1:
			var i = levelKeys[index].find("-")
			nameLabel.text = levelKeys[index].substr(0, i)

func onButtonExited(button: TextureButton):
	if !button.disabled:
		button.modulate = Color.WHITE
		if levelButtons.has(button): nameLabel.text = "Choose Your Love"

func onBackClicked(button: TextureButton):
	pageIndex -= 1
	nextButton.disabled = false
	nextButton.modulate = Color.WHITE
	if pageIndex == 0:
		backButton.disabled = true
		backButton.modulate = Color.DIM_GRAY
	clickAnimation(button)
	showPage()

func onNextClicked(button: TextureButton):
	pageIndex += 1
	backButton.disabled = false
	backButton.modulate = Color.WHITE
	if (pageIndex + 1) * 6 >= levelButtons.size():
		nextButton.disabled = true
		nextButton.modulate = Color.DIM_GRAY
	clickAnimation(button)
	showPage()

var pageIndex: int = 0
var borders = []
func showPage():
	for button in levelButtons: button.visible = false
	for border in borders: border.queue_free()
	borders.clear()
	
	var start: int = pageIndex * 6
	var end: int = min(start + 6, levelButtons.size())
	for i in range(start, end):
		var button = levelButtons[i]
		button.visible = true
		var tilt: float = randf_range(BUTTON_TILT.x, BUTTON_TILT.y)
		if randi() % 2 == 0: tilt *= -1
		button.rotation_degrees = tilt
		var border := ColorRect.new()
		borders.append(border)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border.color = Color.LIGHT_YELLOW
		border.size = button.size * button.scale + (Vector2(20, 60))
		border.position = button.position - ((border.size - (button.size * button.scale)) / 2) + Vector2(0, 20)
		border.rotation_degrees = tilt
		background.add_child(border)

func onLevelClicked(button: TextureButton):
	var puzzleScene = load("res://Puzzle.tscn").instantiate()
	backgroundTween = get_tree().create_tween()
	backgroundTween.tween_property(background, "modulate", Color.BLACK, Globals.SCENE_FADE_TIME)
	clickAnimation(button)
	await backgroundTween.finished
	var oldScene = get_tree().root.get_node("LevelSelect")
	oldScene.call_deferred("free")
	get_tree().root.add_child(puzzleScene)
	puzzleScene.startLevel(levelKeys[button.light_mask])

func _input(event):
	if Input.is_action_just_pressed("escape"):
		var newScene = load("res://MainMenu.tscn").instantiate()
		backgroundTween = get_tree().create_tween()
		backgroundTween.tween_property(background, "modulate", Color.BLACK, Globals.SCENE_FADE_TIME)
		await backgroundTween.finished
		var oldScene = get_tree().root.get_node("LevelSelect")
		oldScene.call_deferred("free")
		get_tree().root.add_child(newScene)

func clickAnimation(button: TextureButton):
	var tween = get_tree().create_tween()
	var color = Color.DARK_GRAY if button.is_hovered() else Color.WHITE
	if button.disabled: color = Color.DIM_GRAY
	tween.tween_property(button, "modulate", Color(0.3, 0.3, 0.3, 0.5), 0.1)
	tween.chain().tween_property(button, "modulate", color, 0.1)
	await tween.finished

func _process(_delta):
	if backgroundTween && backgroundTween.is_running():
		background.material.set_shader_parameter("modulate", background.modulate)
