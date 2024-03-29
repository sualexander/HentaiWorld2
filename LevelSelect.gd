extends Node2D


const FOOTER_HEIGHT: int = 100
const NAME_SIZE: int = 18
const MARGIN: int = 120
const BUTTON_SIZE: float = 0.2
const BUTTON_TILT: float = 10
const ICON_SIZE: float = 1
const ICON_TEXTURE := preload("res://Textures/HeartIcon.png")
const LOCK_TEXTURE := preload("res://Textures/icon.svg")

var save: Dictionary
var levelKeys = []
func _ready():
	levelKeys = SaveSystem.levelData.keys()
	save = SaveSystem.saveData["Slots"][SaveSystem.currentSlot]
	var saveKeys := save.keys()
	#assert(levelKeys == saveKeys)
	
	initializeUI()

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
	footer = ColorRect.new()
	footer.size = Vector2(resolution.x, FOOTER_HEIGHT)
	footer.position = Vector2(0, resolution.y - FOOTER_HEIGHT)
	background.add_child(footer)
	
	nameIcon = TextureRect.new()
	nameIcon.texture = ICON_TEXTURE
	nameIcon.position = Vector2(50, 40)
	var factor = (NAME_SIZE / nameIcon.size.y) * 1.5
	nameIcon.scale = Vector2(factor, factor)
	nameLabel = Label.new()
	nameLabel.add_theme_font_size_override("font_size", NAME_SIZE)
	nameLabel.position = nameIcon.position + Vector2(NAME_SIZE + 15, 0)
	nameLabel.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	nameLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	nameLabel.text = "Nanami"
	background.add_child(nameIcon)
	background.add_child(nameLabel)
	
	var pos = footer.position + Vector2(50, -120)
	backButton = createButton("res://Textures/Next.png", pos, onBackClicked)
	backButton.disabled = true
	backButton.modulate = Color.DIM_GRAY
	background.add_child(backButton)
	nextButton = createButton("res://Textures/Next.png", backButton.position + Vector2(800, 0), onNextClicked)
	background.add_child(nextButton)
	
	makeLevels()
	loadSaveData()
	
	add_child(background)
	showPage()

func loadSaveData():
	assert(levelButtons.size() == levelKeys.size())
	for i in levelButtons.size():
		var numSolved: int #= save[levelKeys[i]]
		if numSolved == 0: continue
		levelButtons[i].get_node("LockIcon").queue_free()
		var icons = levelButtons[i].get_children()
		print(icons)

var levelButtons = []
func makeLevels():
	var resolution := get_tree().root.content_scale_size
	var buttonWidth := resolution.x * BUTTON_SIZE
	var buttonHeight := resolution.y * BUTTON_SIZE
	var horizontal := (resolution.x - (2 * MARGIN) - (3 * buttonWidth)) / 2
	var vertical := (resolution.y - FOOTER_HEIGHT - (2 * MARGIN) - (2 * buttonHeight))
	for i in range(levelKeys.size()):
		var x: float = MARGIN + ((i % 6) % 3) * (buttonWidth + horizontal)
		var y: float = MARGIN + ((i % 6) / 3) * (buttonHeight + vertical)
		var button = createButton(SaveSystem.levelData[levelKeys[i]][0]["texture"], Vector2(x,y), onLevelClicked)
		levelButtons.append(button)
		button.light_mask = i
		
		button.scale = Vector2(BUTTON_SIZE, BUTTON_SIZE)
		#rotation anchor
		button.rotation_degrees = randf_range(-BUTTON_TILT, BUTTON_TILT)
		button.modulate = Color.DARK_GRAY
		button.visible = false
		
		button.disabled = true
		var lock = TextureRect.new()
		lock.name = "LockIcon"
		lock.texture = LOCK_TEXTURE
		button.add_child(lock)
		
		var numPuzzles = getNumPuzzles(levelKeys[i])
		for n in range(numPuzzles):
			var icon = TextureRect.new()
			icon.texture = ICON_TEXTURE
			icon.modulate = Color.DIM_GRAY
			icon.scale = Vector2(ICON_SIZE, ICON_SIZE)
			icon.position = Vector2(button.size.x - 32 - (128 * (n + 1)), button.size.y - 150) #child size does not make sense just hardcode
			icon.visible = false
			button.add_child(icon)
		
		background.add_child(button)

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
	button.connect("mouse_entered", onButtonEntered.bind(button))
	button.connect("mouse_exited", onButtonExited.bind(button))
	button.connect("pressed", onClicked.bind(button))
	return button

func onButtonEntered(button: TextureButton):
	if !button.disabled: button.modulate = Color.DARK_GRAY

func onButtonExited(button: TextureButton):
	if !button.disabled: button.modulate = Color.WHITE

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

func onLevelClicked(button: TextureButton):
	var puzzleScene = load("res://Puzzle.tscn").instantiate()
	var tween = get_tree().create_tween()
	tween.tween_property(background, "modulate", Color.BLACK, 1)
	clickAnimation(button)
	await tween.finished
	var oldScene = get_tree().root.get_node("LevelSelect")
	oldScene.call_deferred("free")
	get_tree().root.add_child(puzzleScene)
	puzzleScene.startLevel(levelKeys[button.light_mask])

func _input(event):
	if Input.is_action_just_pressed("escape"):
		var newScene = load("res://MainMenu.tscn").instantiate()
		var tween = get_tree().create_tween()
		tween.tween_property(background, "modulate", Color.BLACK, 1)
		await tween.finished
		var oldScene = get_tree().root.get_node("LevelSelect")
		oldScene.call_deferred("free")
		get_tree().root.add_child(newScene)

func clickAnimation(button: TextureButton):
	var tween = get_tree().create_tween()
	var color = Color.DARK_GRAY if button.is_hovered() else Color.WHITE
	if button.disabled: color = Color.DIM_GRAY
	tween.tween_property(button, "modulate", Color.BLACK, 0.1)
	tween.chain().tween_property(button, "modulate", color, 0.1)
	await tween.finished

var pageIndex: int = 0
func showPage():
	for button in levelButtons: button.visible = false
	var start: int = pageIndex * 6
	var end: int = min(start + 6, levelButtons.size())
	for i in range(start, end):
		levelButtons[i].visible = true
