extends Node


var savePath := "res://saves.json"
var saveData: Dictionary
var currentSlot: int

var levelsPath := "res://levels.json"
var levelData: Dictionary

func _ready():
	saveData = JSON.parse_string(FileAccess.get_file_as_string(savePath))
	levelData = JSON.parse_string(FileAccess.get_file_as_string(levelsPath))
	saveData = {}
	if saveData == {}: 
		saveData["Slots"] = [null, null, null]
		saveData["Names"] = ["", "", ""]
	
	newSave(2)
	updateSave("", "Level2", 4)
	print(saveData["Names"][currentSlot])

func newSave(slot: int):
	var save: Dictionary
	var keys = levelData.keys()
	for key in keys:
		save[key] = 0
	saveData["Slots"][slot] = save
	saveData["Names"][slot] = "DefaultName"
	currentSlot = slot

func saveGame():
	var saveFile = FileAccess.open(savePath, FileAccess.WRITE)
	saveFile.store_string(JSON.stringify(saveData))

func updateSave(saveName: String = "", levelName: String = "", puzzleIndex: int = -1):
	var name: String = saveData["Names"][currentSlot]
	if saveName == "":
		saveData["Slots"][currentSlot][levelName] = puzzleIndex
		var index = name.rfind(":")
		name = name.substr(0, index)
	else: name = saveName
	var date = Time.get_date_string_from_system()
	saveData["Names"][currentSlot] = name + ": " + date
	saveGame()
