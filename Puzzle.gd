extends Node2D


const gridSize: int = 800
const lineThickness: int = 4
const shuffleSpeed: float = 0.1
const fontColor = Color.DEEP_PINK
const fontSize: int = 24
const textMargin: float = fontSize * 1.5
const borderThickness: float = 6
const dialogueFadeTime: float = 0.25

#from json
var data = []
var textures = []
var dialogues = []
var dialoguePositions: PackedVector2Array
var widths: PackedInt32Array

#persistent objects
var background: TextureRect
var border: ColorRect
var bubble: Polygon2D
var bubbleOutline: Polygon2D
var dialogue: Label

signal swapQueueFinished
enum State {Dialogue, Shuffling, Playing}
var state: State = State.Shuffling
var puzzleIndex: int = 0
var levelName: String
var saveIndex: int

func startLevel(name: String):
	levelName = name
	data = SaveSystem.levelData[levelName]
	for puzzle in data:
		if puzzle.has("size"): widths.append(puzzle["size"])
		else: widths.append(0)
		if puzzle.has("texture"): textures.append(load(puzzle["texture"]))
		else: textures.append(null)
		dialogues.append(puzzle["dialogue"])
		if puzzle.has("dialoguePosition"):
			var positionArray = puzzle["dialoguePosition"]
			dialoguePositions.append(Vector2(positionArray[0], positionArray[1]))
		else: dialoguePositions.append(Vector2.ZERO)
	assert(widths.size() == textures.size() && widths.size() == dialogues.size() && widths.size() == dialoguePositions.size())
	
	var counter: int = 0
	var numPuzzles: int = 0
	var lastPuzzleIndex: int
	var numSolved: int = SaveSystem.saveData["Slots"][SaveSystem.currentSlot][levelName]
	saveIndex = numSolved
	if numSolved != 0:
		for i in range(widths.size()):
			if widths[i] != 0:
				numPuzzles += 1
				lastPuzzleIndex = i
				if counter <= numSolved: 
					counter += 1
					puzzleIndex = i
		if puzzleIndex > lastPuzzleIndex: 
			puzzleIndex = lastPuzzleIndex
		if saveIndex == numPuzzles: saveIndex -= 1
	
	background = TextureRect.new()
	add_child(background)
	
	var index: int = puzzleIndex
	if !textures[puzzleIndex]:
		for i in range(puzzleIndex - 1, -1, -1):
			if textures[i]:
				index = i
				break
	background.texture = textures[index]
	background.modulate = Color.BLACK
	var tween = get_tree().create_tween()
	tween.tween_property(background, "modulate", Color.WHITE, Globals.SCENE_FADE_TIME)
	await tween.finished
	connect("swapQueueFinished", onSwapQueueFinished)
	initializeDialogue()

func initializeDialogue():
	dialogue = Label.new()
	dialogue.position = Vector2(float(textMargin) / 2, float(textMargin) / 2)
	dialogue.add_theme_font_size_override("font_size", fontSize)
	dialogue.add_theme_color_override("font_color", fontColor)
	
	bubbleOutline = Polygon2D.new()
	bubbleOutline.color = Color.HOT_PINK
	bubbleOutline.antialiased = true
	bubble = Polygon2D.new()
	bubble.antialiased = true
	
	bubbleOutline.modulate = Color(1, 1, 1, 0)
	background.add_child(bubbleOutline)
	bubbleOutline.add_child(bubble) 
	bubble.add_child(dialogue)
	
	advanceDialogue()

var dialogueIndex: int = 0
var currentDialogue: PackedStringArray
var dialoguePosition: Vector2
var backgroundTexture
func advanceDialogue():
	if textTween && textTween.is_running(): return
	
	state = State.Dialogue
	if dialogueIndex == 0: 
		currentDialogue = dialogues[puzzleIndex]
		if dialoguePositions[puzzleIndex] != Vector2.ZERO: dialoguePosition = dialoguePositions[puzzleIndex]
		if dialoguePosition == Vector2.ZERO:
			for i in range(puzzleIndex - 1, -1, -1):
				if dialoguePositions[i] != Vector2.ZERO:
					dialoguePosition = dialoguePositions[i]
					break
		assert(dialoguePosition != Vector2.ZERO)
	if textures[puzzleIndex]: backgroundTexture = textures[puzzleIndex]
	if !backgroundTexture:
		for i in range(puzzleIndex - 1, -1, -1):
			if textures[i]:
				backgroundTexture = textures[i]
				break
	background.texture = backgroundTexture
	
	if dialogueIndex == currentDialogue.size(): 
		dialogueIndex = 0
		textTween = get_tree().create_tween()
		textTween.tween_property(bubbleOutline, "modulate", Color(1, 1, 1, 0), dialogueFadeTime)
		await textTween.finished
		if widths[puzzleIndex] != 0: createPuzzle()
		else:
			if puzzleIndex + 1 == data.size(): 
				await destroyPuzzle()
				exitLevel()
			else:
				puzzleIndex += 1
				advanceDialogue()
	else: 
		renderDialogue(currentDialogue[dialogueIndex], dialoguePosition)
		dialogueIndex += 1

func onSwapQueueFinished():
	if state == State.Shuffling:
		if isPuzzleSolved(): shuffle(5)
		else:
			state = State.Playing
			toggleBlur(false)
	elif state == State.Playing:
		if isPuzzleSolved():
			state = State.Shuffling
			if isCheating:
				isCheating = false
				for tile in tiles: if tile: tile.modulate = Color(0.9, 0.9, 1, 1)
			SaveSystem.updateSave("", levelName, saveIndex)
			await destroyPuzzle()
			if puzzleIndex + 1 == data.size(): 
				#ending animation
				exitLevel()
			else:
				puzzleIndex += 1
				advanceDialogue()

var gridOffset: Vector2
func createPuzzle():
	saveIndex += 1
	state = State.Shuffling
	
	var resolution = get_tree().root.content_scale_size
	gridOffset = Vector2((resolution.x - gridSize) / 2, (resolution.y - gridSize) / 2)
	
	border = ColorRect.new()
	background.add_child(border)
	border.position = gridOffset - (Vector2.ONE * lineThickness)
	border.size = Vector2.ONE * (gridSize + 2 * lineThickness)
	border.color = Color.WHITE
	
	createGrid()
	toggleBlur(true)
	var shuffle = data[puzzleIndex]["shuffle"]
	if shuffle is float: shuffle(shuffle)
	else: for dir in shuffle: swap(dir)

func destroyPuzzle():
	var tween = get_tree().create_tween()
	tween.tween_property(border, "modulate", Color(1, 1, 1, 0), 0.5)
	await tween.finished
	for tile in tiles: if tile: tile.queue_free()
	tiles.clear()

func _input(event):
	if Input.is_action_just_pressed("escape"):
		exitLevel()
	else:
		if state == State.Dialogue:
			if Input.is_action_just_pressed("enter") || Input.is_action_just_pressed("right") ||\
			Input.is_action_just_pressed("up"): 
				advanceDialogue()
		elif state == State.Playing && !isCheating:
			if Input.is_action_just_pressed("left"): swap("right")
			elif Input.is_action_just_pressed("right"): swap("left")
			elif Input.is_action_just_pressed("up"): swap("down")
			elif Input.is_action_just_pressed("down"): swap("up")
			
			elif event is InputEventKey && event.pressed && event.keycode == KEY_C:
				solvePuzzle()
			elif event is InputEventKey && event.pressed && event.keycode == KEY_F:
				shuffle(20)
	if event is InputEventKey && event.pressed && event.keycode == KEY_G:
		await destroyPuzzle()
		if puzzleIndex + 1 == data.size(): exitLevel()
		else:
			puzzleIndex += 1
			advanceDialogue()

func exitLevel():
	var newScene = load("res://LevelSelect.tscn").instantiate()
	var tween = get_tree().create_tween()
	tween.tween_property(background, "modulate", Color.BLACK, Globals.SCENE_FADE_TIME)
	await tween.finished
	var oldScene = get_tree().root.get_node("Puzzle")
	oldScene.call_deferred("free")
	get_tree().root.add_child(newScene)

#--------------------------------------------------------------------------------------------------
var textTween: Tween
func renderDialogue(text: String, pos: Vector2):
	if bubbleOutline.modulate == Color.WHITE:
		textTween = get_tree().create_tween()
		textTween.tween_property(bubbleOutline, "modulate", Color(1, 1, 1, 0), dialogueFadeTime)
		await textTween.finished
	
	dialogue.text = text
	if data[puzzleIndex].has("flip"):
		bubbleOutline.scale = Vector2(-1, 1)
		dialogue.scale = Vector2(-1, 1)
		dialogue.position += Vector2(data[puzzleIndex]["flip"], 0)
	else:
		bubbleOutline.scale = Vector2.ONE
		dialogue.scale = Vector2.ONE
		dialogue.position = Vector2(float(textMargin) / 2, float(textMargin) / 2)
	#await get_tree().process_frame #idk if this is needed, doesn't seem like
	var dim := Vector2(dialogue.get_minimum_size().x + textMargin, dialogue.get_minimum_size().y + textMargin)
	var tailHeight: float = clamp(dim.y / 3, 15, 35)
	var tailWidth: float = clamp(tailHeight * 1.8, 20, 55)
	var radius: float = clamp(min(dim.x, dim.y) / 4, 6, 20)
	var tailY: float = dim.y * 0.8
	
	var bubblePoints: PackedVector2Array
	bubblePoints.append_array(makeArc(Vector2(radius, radius), PI, PI * 1.5, radius))
	bubblePoints.append_array(makeArc(Vector2(dim.x - radius, radius), -PI/2, 0, radius))
	bubblePoints.append(Vector2(dim.x, tailY - tailHeight))
	bubblePoints.append(Vector2(dim.x + tailWidth, tailY))
	bubblePoints.append(Vector2(dim.x, tailY))
	bubblePoints.append_array(makeArc(Vector2(dim.x - radius, dim.y - radius), 0, PI/2, radius))
	bubblePoints.append_array(makeArc(Vector2(radius, dim.y - radius), PI/2, PI, radius))
	bubble.polygon = bubblePoints
	
	radius += borderThickness / 2
	var offsetPoints: PackedVector2Array
	offsetPoints.append_array(makeArc(Vector2(radius - borderThickness, radius - borderThickness), PI, PI * 1.5, radius))
	offsetPoints.append_array(makeArc(Vector2(dim.x - radius + borderThickness, radius - borderThickness), -PI/2, 0, radius))
	offsetPoints.append(Vector2(dim.x + borderThickness, tailY - tailHeight - borderThickness / 2))
	offsetPoints.append(Vector2(dim.x + tailWidth + borderThickness * 3, tailY + borderThickness))
	offsetPoints.append(Vector2(dim.x + borderThickness, tailY + borderThickness))
	offsetPoints.append_array(makeArc(Vector2(dim.x - radius + borderThickness, dim.y - radius + borderThickness), 0, PI/2, radius))
	offsetPoints.append_array(makeArc(Vector2(radius - borderThickness, dim.y - radius + borderThickness), PI/2, PI, radius))
	bubbleOutline.polygon = offsetPoints
	bubbleOutline.position = Vector2(pos.x - (dim.x + tailWidth + borderThickness + textMargin), pos.y - (tailY + borderThickness))
	
	textTween = get_tree().create_tween()
	textTween.tween_property(bubbleOutline, "modulate", Color(1, 1, 1, 1), dialogueFadeTime)

func makeArc(origin: Vector2, start: float, end: float, radius: float, numSegments: int = 8) -> PackedVector2Array:
	var points: PackedVector2Array
	for i in range(numSegments + 1):
		var theta = start + (end - start) * i / numSegments
		points.append(origin + Vector2(cos(theta), sin(theta)) * radius)
	return points

var tileSize: float
var tiles = []
var blank: int
func createGrid():
	var width := widths[puzzleIndex]
	tileSize = (gridSize - ((widths[puzzleIndex] - 1) * lineThickness)) / widths[puzzleIndex]
	for row in range(width):
		for col in range(width):
			if row == width - 1 and col == width - 1:
				tiles.append(null)
				continue
			
			var tile := Sprite2D.new()
			tiles.append(tile)
			border.add_child(tile)
			
			tile.light_mask = row * width + col #unused property to store original index 
			tile.texture = background.texture
			tile.position = (Vector2.ONE * ((tileSize / 2) + lineThickness)) + Vector2(col, row) * (tileSize + lineThickness)
			tile.region_enabled = true
			tile.region_rect = Rect2(tile.position.x - (tileSize / 2) + border.position.x, tile.position.y - (tileSize / 2) + border.position.y, 
			tileSize, tileSize)
			tile.modulate = Color(0.9, 0.9, 1, 1)
			tile.material = load("res://Dressing/Blur.tres")
	blank = width * width - 1

func toggleBlur(isOn: bool):
	for tile: Sprite2D in tiles:
		if tile: tile.material.set_shader_parameter("isOn", isOn)

var swapQueue = []
var tileTween: Tween
func swap(direction, animLength: float = 0.1):
	swapQueue.append({"direction": direction, "length": animLength})
	if !tileTween || (tileTween && !tileTween.is_running()):
		swapQueue.pop_front()
		swapInternal(direction, animLength)

func swapInternal(direction, animLength):
	var width := widths[puzzleIndex]
	var row: int = blank / width
	var col: int = blank % width
	var newRow: int = row
	var newCol: int = col
	
	match direction:
		"up": newRow -= 1
		"down": newRow += 1
		"left": newCol -= 1
		"right": newCol += 1
	
	if newCol >= 0 and newCol < width and newRow >= 0 and newRow < width:
		var newIndex: int = newRow * width + newCol
		var moveTile = tiles[newIndex]
		tiles[blank] = tiles[newIndex]
		blank = newIndex
		tiles[blank] = null
		
		tileTween = get_tree().create_tween()
		tileTween.tween_property(moveTile, "position", (Vector2.ONE * ((tileSize / 2) + lineThickness)) + Vector2(col, row) * (tileSize + lineThickness), animLength)
		tileTween.finished.connect(onSwapFinished)
	else: onSwapFinished()

func onSwapFinished():
	if tileTween && tileTween.finished.is_connected(onSwapFinished): tileTween.finished.disconnect(onSwapFinished)
	if swapQueue.size() > 0:
		var newSwap = swapQueue.pop_front()
		swapInternal(newSwap.direction, newSwap.length)
	else: emit_signal("swapQueueFinished")
	
func shuffle(numMoves : int):
	var width := widths[puzzleIndex]
	var lastDirection: String = ""
	var localBlank: int = blank
	for i in range(numMoves):
		var directions = ["up", "down", "left", "right"]
		var row: int = localBlank / width
		var col: int = localBlank % width
		
		if row == 0: directions.erase("up")
		elif row == width - 1: directions.erase("down")
		if col == 0: directions.erase("left")
		elif col == width - 1: directions.erase("right")
		
		if lastDirection == "up": directions.erase("down")
		elif lastDirection == "down": directions.erase("up")
		elif lastDirection == "left": directions.erase("right")
		elif lastDirection == "right": directions.erase("left")
		
		var move = directions[randi() % directions.size()]
		swap(move, shuffleSpeed)
		lastDirection = move
		
		match move:
			"up": localBlank -= width
			"down": localBlank += width
			"left": localBlank -= 1
			"right": localBlank += 1

func isPuzzleSolved() -> bool:
	if tiles[tiles.size() - 1] != null: return false
	for i in range(0, tiles.size() - 1):
		if tiles[i].light_mask != i: return false
	return true

var isCheating: bool = false
func solvePuzzle():
	isCheating = true
	for tile in tiles: if tile: tile.modulate = Color.INDIAN_RED
	var grid = []
	for tile in tiles:
		if tile: grid.append(tile.light_mask + 1)
		else: grid.append(0)
	var moves: PackedStringArray = Solver.getSolution(grid)
	for move in moves: swap(move, 0.1)
