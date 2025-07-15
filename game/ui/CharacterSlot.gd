extends Control

# Signaux
signal character_selected(character: Dictionary)
signal empty_slot_clicked()

# Références aux nœuds UI
@onready var background: Panel = $Background
@onready var character_portrait: TextureRect = $VBoxContainer/CharacterPortrait
@onready var character_name: Label = $VBoxContainer/CharacterName
@onready var character_info: Label = $VBoxContainer/CharacterInfo
@onready var empty_label: Label = $VBoxContainer/EmptyLabel
@onready var button: Button = $Button

# Données
var character_data: Dictionary = {}
var is_empty: bool = true

func _ready():
	button.pressed.connect(_on_button_pressed)

func setup_character(character: Dictionary):
	"""Configure le slot avec un personnage"""
	character_data = character
	is_empty = false
	
	# Afficher les informations du personnage
	character_name.text = character.name
	character_info.text = "Niv. " + str(character.level) + " " + get_class_name(character.class)
	
	# Masquer le label vide
	empty_label.visible = false
	
	# Afficher le portrait (pour l'instant, utiliser une texture par défaut)
	character_portrait.texture = load("res://game/players/player_red_86x96.png")
	character_portrait.visible = true
	
	# Changer l'apparence du background
	background.modulate = Color.WHITE

func setup_empty():
	"""Configure le slot comme vide"""
	character_data = {}
	is_empty = true
	
	# Masquer les informations du personnage
	character_name.text = ""
	character_info.text = ""
	character_portrait.visible = false
	
	# Afficher le label vide
	empty_label.visible = true
	empty_label.text = "Créer un\npersonnage"
	
	# Changer l'apparence du background
	background.modulate = Color(0.5, 0.5, 0.5, 0.8)

func _on_button_pressed():
	"""Appelé quand le bouton est pressé"""
	if is_empty:
		empty_slot_clicked.emit()
	else:
		character_selected.emit(character_data)

func get_class_name(class_id: String) -> String:
	"""Retourne le nom de la classe en français"""
	match class_id:
		"warrior":
			return "Guerrier"
		"archer":
			return "Archer"
		_:
			return class_id.capitalize()

func set_selected(selected: bool):
	"""Met en surbrillance le slot sélectionné"""
	if selected:
		background.modulate = Color.YELLOW if not is_empty else Color(0.8, 0.8, 0.3, 0.8)
	else:
		background.modulate = Color.WHITE if not is_empty else Color(0.5, 0.5, 0.5, 0.8) 