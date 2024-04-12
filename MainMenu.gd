extends Node2D


var background: TextureRect
func _ready():
	background = get_node("Background")
	background.modulate = Color.BLACK
	var tween = get_tree().create_tween()
	tween.tween_property(background, "modulate", Color.WHITE, Globals.SCENE_FADE_TIME)

func onNewPressed():
	start(false)

func onLoadPressed():
	start(true)

func start(isLoad: bool):
	var newScene = load("res://SaveMenu.tscn").instantiate()
	var tween = get_tree().create_tween()
	tween.tween_property(background, "modulate", Color.BLACK, Globals.SCENE_FADE_TIME)
	await tween.finished
	var oldScene = get_tree().root.get_node("MainMenu")
	oldScene.call_deferred("free")
	get_tree().root.add_child(newScene)
	newScene.isLoad = isLoad
	newScene.start()

func onQuitPressed():
	var tween = get_tree().create_tween()
	tween.tween_property(background, "modulate", Color.BLACK, Globals.SCENE_FADE_TIME)
	await tween.finished
	get_tree().quit()
