extends Node


var grid = []
var size: int
var moves = []
func getSolution(board):
	size = sqrt(board.size())
	grid = board
	assert(isSolvable())
	moves.clear()
	solve()
	assert(isSolved())
	return moves

func isSolved() -> bool:
	if grid[size * size - 1] != 0: return false
	for i in range(size * size - 1):
		if grid[i] != i + 1: return false
	return true

func printGrid():
	if size == 4:
		for i in range(4):
			var row = ""
			for j in range(4):
				var number = str(grid[i*4+j])
				if len(number) == 1:
					number = " " + number
				row += number + " "
			print(row)
	else:
		for i in range(3):
			print(str(grid[i*3]) + str(grid[i*3+1]) + str(grid[i*3+2]) + "\n")
	print("\n")

func isSolvable() -> bool:
	var inversions: int = 0
	var rowIndex: int
	for i in range(size * size):
		if grid[i] == 0: 
			rowIndex = size - int(i / size)
			continue
		for j in range(i + 1, size * size):
			if grid[i] > grid[j] && grid[j] != 0:
				inversions += 1
	if size % 2 == 0: return (rowIndex % 2 == 0) != (inversions % 2 == 0)
	else: return inversions % 2 == 0

#-----------------------------------------------------------------------------
var sectionSize: int
var offset: int
var POSSIBLE_MOVES
func solve():
	POSSIBLE_MOVES = [-1, 1, size, -size]
	sectionSize = size
	offset = 0
	if size == 3: solveThree()
	else:
		moveTileTo(1, 0)
		moveTileTo(2, 1, [0])
		moveTileTo(3, 2, [0, 1])
		if grid[3] == 0 && grid[7] == 4:
			grid[3] = 4
			grid[7] = 0
			moves.append("down")
		elif grid[3] != 4:
			moveTileTo(4, 6, [0, 1, 2])
			moveBlankTo(grid.find(0), 4, [0, 1, 2, 6])
			grid[6] = 0
			swap(6, 7)
			swap(3, 7)
			grid[3] = 4
			grid[4] = 0
			moves += ["up", "right", "right", "down", "right", "up", "left", "left", "left", "down"]
		moveTileTo(5, 4, [0, 1, 2, 3])
		moveTileTo(9, 8, [0, 1, 2, 3, 4])
		if grid[12] == 0 && grid[13] == 13:
			grid[12] = 13
			grid[13] = 0
			moves.append("right")
		elif grid[12] != 13:
			moveTileTo(13, 9, [0, 1, 2, 3, 4, 8])
			moveBlankTo(grid.find(0), 5, [0, 1, 2, 3, 4, 8, 9])
			grid[8] = 13
			grid[9] = 0
			swap(9, 13)
			swap(12, 13)
			grid[12] = 13
			grid[8] = 9
			grid[4] = 5
			grid[5] = 0
			moves += ["left", "down", "right", "down", "left", "up", "up", "right"]
		
		sectionSize = 3
		offset = 5
		solveThree()

func solveThree():
	var ZERO: int = offset
	var ONE: int = offset + 1
	var TWO: int = offset + 2
	
	var FOUR: int = 4 if offset == 0 else offset + 5
	var FIVE: int = 5 if offset == 0 else offset + 6
	
	var SEVEN: int = 7 if offset == 0 else offset + 9
	var EIGHT: int = 8 if offset == 0 else offset + 10
	
	var THREE: int = offset + 3
	var SIX: int = 6 if offset == 0 else offset + 7
	var THREE_INDEX: int = 3 if offset == 0 else offset + 4
	var SIX_INDEX: int = 6 if offset == 0 else offset + 8
	
	#first row
	moveTileTo(ONE, ZERO)
	moveTileTo(TWO, ONE, [ZERO])
	if grid[TWO] == 0 && grid[FIVE] == THREE:
		grid[TWO] = THREE
		grid[FIVE] = 0
		moves.append("down")
	elif grid[TWO] != THREE: 
		moveTileTo(THREE, FOUR, [ZERO, ONE])
		moveBlankTo(grid.find(0), THREE_INDEX, [ZERO, ONE, FOUR])
		grid[THREE_INDEX] = ONE
		grid[ZERO] = TWO
		grid[ONE] = THREE
		grid[FOUR] = 0
		swap(FOUR, FIVE)
		swap(TWO, FIVE)
		grid[ZERO] = ONE
		grid[ONE] = TWO
		grid[TWO] = THREE
		grid[THREE_INDEX] = 0
		moves += ["up", "right", "down", "right", "up", "left", "left", "down"]
	#first column
	moveTileTo(SEVEN, THREE_INDEX, [ZERO, ONE, TWO])
	#last 2x2
	if grid[SIX_INDEX] == FOUR || (grid[SIX_INDEX] == 0 && grid[SEVEN] == FOUR):
		moveBlankTo(grid.find(0), FOUR, [ZERO, ONE, TWO])
		grid[FOUR] = SEVEN
		grid[THREE_INDEX] = FOUR
		grid[SIX_INDEX] = 0
		swap(SIX_INDEX, SEVEN)
		grid[FOUR] = 0
		grid[SEVEN] = SEVEN
		swap(FOUR, FIVE)
		swap(FIVE, EIGHT)
		grid[EIGHT] = SEVEN
		grid[SEVEN] = 0
		swap(SIX_INDEX, SEVEN)
		grid[SIX_INDEX] = FOUR
		grid[THREE_INDEX] = 0
		swap(THREE_INDEX, FOUR)
		swap(FOUR, SEVEN)
		grid[SEVEN] = SEVEN
		grid[EIGHT] = 0
		swap(FIVE, EIGHT)
		swap(FOUR, FIVE)
		swap(THREE_INDEX, FOUR)
		grid[THREE_INDEX] = FOUR
		grid[SIX_INDEX] = SEVEN
		grid[SEVEN] = 0
		moves += ["left", "down", "right", "up", "right", "down", "left", "left", "up", 
		"right", "down", "right", "up", "left", "left", "down", "right"]
	else:
		moveTileTo(FOUR, FOUR, [ZERO, ONE, TWO, THREE])
		moveBlankTo(grid.find(0), SIX_INDEX, [ZERO, ONE, TWO, THREE, FOUR])
		grid[SIX_INDEX] = SEVEN
		grid[THREE_INDEX] = FOUR
		grid[FOUR] = 0
		moves += ["up", "right"]
	moveTileTo(FIVE, FOUR, [ZERO, ONE, TWO, THREE, SIX_INDEX])
	if grid[FIVE] == SIX && grid[EIGHT] == EIGHT: 
		swap(SEVEN, EIGHT)
		moves.append("right")
	elif grid[FIVE] != SIX: 
		swap(FIVE, EIGHT)
		moves.append("down")

func swap(p1: int, p2: int):
	var temp = grid[p1]
	grid[p1] = grid[p2]
	grid[p2] = temp

func moveTileTo(tile: int, destination: int, exclude = []):
	var currentIndex = grid.find(tile)
	var blankIndex = grid.find(0)
	
	while currentIndex != destination:
		var distance: int = dist(currentIndex, destination)
		var blankTarget: int
		for move in POSSIBLE_MOVES:
			var temp: int = currentIndex + move
			if temp < offset || temp > (size * size) - 1: continue
			if exclude.has(temp): continue
			if (move == -1 && currentIndex % size == offset % size) || (move == 1 && currentIndex % size == sectionSize - 1) ||\
			(move == -size && currentIndex < offset + sectionSize) || (move == size && currentIndex > (size * size) - (size + 1)): continue
			if dist(currentIndex + move, destination) < distance:
				blankTarget = currentIndex + move
				break
		
		moveBlankTo(blankIndex, blankTarget, exclude, currentIndex)
		
		moves.append(getDirection(blankTarget, currentIndex))
		blankIndex = currentIndex
		currentIndex = blankTarget
		grid[blankIndex] = 0
		grid[currentIndex] = tile

func moveBlankTo(blankIndex: int, blankTarget: int, exclude = [], currentIndex = -1):
	var lastIndex: int = -1
	var pastLocations = []
	while blankIndex != blankTarget:
		var distance = dist(blankIndex, blankTarget)
		if !pastLocations.has(blankIndex): pastLocations.append(blankIndex)
		
		var nextIndex: int = -1
		for move in POSSIBLE_MOVES:
			var temp: int = blankIndex + move
			if temp == currentIndex || temp == lastIndex || pastLocations.has(temp): continue
			if temp < offset || temp > (size * size) - 1: continue
			if (move == -1 && blankIndex % size == offset % size) || (move == 1 && blankIndex % size == size - 1) ||\
			(move == -size && blankIndex < offset + sectionSize) || (move == size && blankIndex > (size * size) - (size + 1)): continue
			if exclude.has(temp): continue
			if nextIndex != -1 && dist(temp, blankTarget) >= dist(nextIndex, blankTarget): continue
			nextIndex = temp
			if temp == blankTarget || dist(temp, blankTarget) < distance: break
		if nextIndex == -1: #backtrack
			moves.append(getDirection(blankIndex, lastIndex))
			grid[blankIndex] = grid[lastIndex]
			grid[lastIndex] = 0
			var tempIndex: int = blankIndex
			blankIndex = lastIndex
			lastIndex = tempIndex
			
			
			for move in POSSIBLE_MOVES:
				var temp: int = blankIndex + move
				if temp == currentIndex || temp == lastIndex || pastLocations.has(temp): continue
				if temp < offset || temp > (size * size) - 1: continue
				if (move == -1 && blankIndex % size == offset % size) || (move == 1 && blankIndex % size == sectionSize - 1) ||\
				(move == -size && blankIndex < offset + sectionSize) || (move == size && blankIndex > (size * size) - (size + 1)): continue
				if exclude.has(temp): continue
				nextIndex = temp
				break
			
			if nextIndex == -1: 
				pastLocations.clear()
				continue
		
		moves.append(getDirection(blankIndex, nextIndex))
		lastIndex = blankIndex
		grid[blankIndex] = grid[nextIndex]
		blankIndex = nextIndex
		grid[blankIndex] = 0

func dist(p1, p2) -> int:
	return abs((p1 % size) - (p2 % size)) + abs((p1 / size) - (p2 / size))

func getDirection(from: int, to: int) -> String:
	if to == from - 1: return "left"
	if to == from + 1: return "right"
	if to < from: return "up"
	return "down"
