extends Node2D


const gridSize: int = 512
const lineThickness: int = 4
const shuffleSpeed: float = 0.1
const fontColor = Color.DEEP_PINK
const fontSize: int = 16
const textMargin: float = fontSize * 1.5
const borderThickness: float = 4
const dialogueFadeTime: float = 0.5

#from json
var data = []
var textures = []
var dialogues = []
var dialoguePositions: PackedVector2Array
var widths: PackedInt32Array

#persistent objects
var background: TextureRect
var bubble: Polygon2D
var bubbleOutline: Polygon2D
var dialogue: Label

signal swapQueueFinished
enum State {Dialogue, Shuffling, Playing}
var state: State = State.Dialogue
var puzzleIndex: int = 0

func startLevel(levelName: String):
	data = SaveSystem.levelData[levelName]
	for puzzle in data:
		if puzzle.has("size"): widths.append(puzzle["size"])
		else: widths.append(0)
		dialogues.append(puzzle["dialogue"])
		if puzzle.has("texture"): textures.append(load(puzzle["texture"]))
		else: textures.append(null)
		if puzzle.has("dialoguePosition"):
			var positionArray = puzzle["dialoguePosition"]
			dialoguePositions.append(Vector2(positionArray[0], positionArray[1]))
		else: dialoguePositions.append(Vector2.ZERO)
	assert(widths.size() == textures.size() && widths.size() == dialogues.size() && widths.size() == dialoguePositions.size())
	
	background = TextureRect.new()
	add_child(background)
	background.texture = textures[0]
	background.modulate = Color.BLACK
	var tween = get_tree().create_tween()
	tween.tween_property(background, "modulate", Color.WHITE, 1)
	
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
	bubble.color = Color.WHITE
	bubble.antialiased = true
	
	bubbleOutline.modulate = Color(1, 1, 1, 0)
	add_child(bubbleOutline)
	bubbleOutline.add_child(bubble) 
	bubble.add_child(dialogue)
	
	advanceDialogue()

var dialogueIndex: int = 0
var currentDialogue: PackedStringArray
var dialoguePosition: Vector2
func advanceDialogue():
	if textTween && textTween.is_running(): return
	
	state = State.Dialogue
	if dialogueIndex == 0: 
		currentDialogue = dialogues[puzzleIndex]
		if dialoguePositions[puzzleIndex] != Vector2.ZERO: dialoguePosition = dialoguePositions[puzzleIndex]
	if dialogueIndex == currentDialogue.size(): 
		dialogueIndex = 0
		textTween = get_tree().create_tween()
		textTween.tween_property(bubbleOutline, "modulate", Color(1, 1, 1, 0), dialogueFadeTime)
		await textTween.finished
		if widths[puzzleIndex] != 0: createPuzzle()
		else:
			if puzzleIndex + 1 == data.size(): endLevel()
			else:
				puzzleIndex += 1
				advanceDialogue()
	else: 
		renderDialogue(currentDialogue[dialogueIndex], dialoguePosition)
		dialogueIndex += 1

func onSwapQueueFinished():
	if state == State.Shuffling:
		if isPuzzleSolved(): shuffle(5)
		else: state = State.Playing
	elif state == State.Playing:
		if isPuzzleSolved(): 
			print(puzzleIndex)
			if puzzleIndex + 1 == data.size(): endLevel()
			else:
				destroyPuzzle()
				puzzleIndex += 1
				advanceDialogue()

func endLevel():
	state = State.Shuffling
	destroyPuzzle()
	print("the end")

var backgroundTexture
var gridOffset: Vector2
var tileSize: float
func createPuzzle():
	state = State.Shuffling
	if textures[puzzleIndex]: 
		backgroundTexture = textures[puzzleIndex]
		background.texture = backgroundTexture
	
	tileSize = float(gridSize) / widths[puzzleIndex]
	var resolution = get_tree().root.content_scale_size
	gridOffset = Vector2((resolution.x - gridSize + tileSize) / 2, (resolution.y - gridSize + tileSize) / 2)
	
	var border := ColorRect.new()
	add_child(border)
	border.color = Color.WHITE
	border.position = gridOffset - Vector2(tileSize / 2, tileSize / 2)
	border.size = Vector2(gridSize, gridSize)
	
	var overlay := ColorRect.new()
	add_child(overlay)
	overlay.z_index = 10
	overlay.color = Color(0.2, 0.2, 0.4, 0.25)
	overlay.position = gridOffset - Vector2(tileSize / 2, tileSize / 2)
	overlay.size = Vector2(gridSize, gridSize)
	
	createGrid()
	shuffle(1)

func destroyPuzzle():
	tiles.clear()
	for child in get_children(): 
		if child is ColorRect || child is Line2D || child is Sprite2D:
			child.queue_free()

func _input(_event):
	if state == State.Dialogue:
		if Input.is_action_just_pressed("enter"): advanceDialogue()
	elif state == State.Playing:
		if Input.is_action_just_pressed("left"): swap("right")
		if Input.is_action_just_pressed("right"): swap("left")
		if Input.is_action_just_pressed("up"): swap("down")
		if Input.is_action_just_pressed("down"): swap("up")

#--------------------------------------------------------------------------------------------------
var textTween: Tween
func renderDialogue(text: String, pos: Vector2):
	if bubbleOutline.modulate == Color.WHITE:
		textTween = get_tree().create_tween()
		textTween.tween_property(bubbleOutline, "modulate", Color(1, 1, 1, 0), dialogueFadeTime)
		await textTween.finished
	
	dialogue.text = text
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
	bubbleOutline.position = pos
	
	textTween = get_tree().create_tween()
	textTween.tween_property(bubbleOutline, "modulate", Color(1, 1, 1, 1), dialogueFadeTime)

func makeArc(origin: Vector2, start: float, end: float, radius: float, numSegments: int = 8) -> PackedVector2Array:
	var points: PackedVector2Array
	for i in range(numSegments + 1):
		var theta = start + (end - start) * i / numSegments
		points.append(origin + Vector2(cos(theta), sin(theta)) * radius)
	return points

var tiles = []
func createGrid():
	var width := widths[puzzleIndex]
	for row in range(width):
		for col in range(width):
			if row == 0 and col == 0:
				tiles.append(null)
				continue
				
			var tile := Sprite2D.new()
			tiles.append(tile)
			add_child(tile)
			
			tile.light_mask = row * width + col #unused property to store original index 
			tile.texture = background.texture
			tile.position = gridOffset + Vector2(col * tileSize, row * tileSize)
			tile.region_enabled = true
			tile.region_rect = Rect2(tile.position.x - (tileSize / 2), tile.position.y - (tileSize / 2), 
			tileSize, tileSize)		
	drawLines()

func drawLines():
	var width := widths[puzzleIndex]
	var offset := gridOffset - Vector2(tileSize / 2, tileSize / 2)
	var nudge := float(lineThickness) / 2
	
	for i in range(width + 1):
		var horizontalLine := Line2D.new()
		var verticalLine := Line2D.new()
		add_child(horizontalLine)
		add_child(verticalLine)
		
		horizontalLine.default_color = Color.WHITE
		verticalLine.default_color = Color.WHITE
		horizontalLine.width = lineThickness
		verticalLine.width = lineThickness
	
		var hStart := offset + Vector2(-nudge, i * tileSize)
		var hEnd := hStart + Vector2(gridSize - (lineThickness * (width % 2 - 1)), 0)
		var vStart := offset + Vector2(i * (tileSize), -nudge)
		var vEnd := vStart + Vector2(0, gridSize - (lineThickness * (width % 2 - 1)))
		
		horizontalLine.points = [hStart, hEnd]
		verticalLine.points = [vStart, vEnd]

var swapQueue = []
var tileTween: Tween
func swap(direction, animLength: float = 0.2):
	swapQueue.append({"direction": direction, "length": animLength})
	if !tileTween || (tileTween && !tileTween.is_running()):
		swapQueue.pop_front()
		swapInternal(direction, animLength)

var blank: int = 0
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
		tileTween.tween_property(moveTile, "position", gridOffset + Vector2(col, row) * tileSize, animLength)
		tileTween.connect("finished", onSwapFinished)

func onSwapFinished():
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
	if tiles[0] != null: return false
	for i in range (1, tiles.size()):
		if tiles[i].light_mask != i: return false
	return true
