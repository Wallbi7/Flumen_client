extends Control

# Références aux nœuds UI
@onready var character_slots: HBoxContainer = $VBoxContainer/CharacterSlots
@onready var character_info_panel: Panel = $VBoxContainer/CharacterInfoPanel
@onready var character_name_label: Label = $VBoxContainer/CharacterInfoPanel/VBoxContainer/CharacterName
@onready var character_class_label: Label = $VBoxContainer/CharacterInfoPanel/VBoxContainer/CharacterClass
@onready var character_level_label: Label = $VBoxContainer/CharacterInfoPanel/VBoxContainer/CharacterLevel
@onready var character_stats_label: Label = $VBoxContainer/CharacterInfoPanel/VBoxContainer/CharacterStats
@onready var play_button: Button = $VBoxContainer/ButtonContainer/PlayButton
@onready var create_button: Button = $VBoxContainer/ButtonContainer/CreateButton
@onready var delete_button: Button = $VBoxContainer/ButtonContainer/DeleteButton

# Panneau de création de personnage
@onready var create_panel: Panel = $CreateCharacterPanel
@onready var create_name_input: LineEdit = $CreateCharacterPanel/VBoxContainer/NameInput
@onready var class_buttons: HBoxContainer = $CreateCharacterPanel/VBoxContainer/ClassButtons
@onready var create_confirm_button: Button = $CreateCharacterPanel/VBoxContainer/ButtonContainer/CreateConfirmButton
@onready var create_cancel_button: Button = $CreateCharacterPanel/VBoxContainer/ButtonContainer/CreateCancelButton

# Données
var characters: Array = []
var selected_character: Dictionary = {}
var selected_class: String = ""
var character_classes: Array = []

# Préfab pour les slots de personnages
const CHARACTER_SLOT_SCENE = preload("res://game/ui/CharacterSlot.tscn")

func _ready():
	# Connecter les signaux des boutons
	play_button.pressed.connect(_on_play_button_pressed)
	create_button.pressed.connect(_on_create_button_pressed)
	delete_button.pressed.connect(_on_delete_button_pressed)
	create_confirm_button.pressed.connect(_on_create_confirm_button_pressed)
	create_cancel_button.pressed.connect(_on_create_cancel_button_pressed)
	create_name_input.text_changed.connect(_on_create_name_input_text_changed)
	
	# Connecter les signaux du GameManager
	GameManager.characters_and_classes_loaded.connect(_on_characters_received)
	GameManager.character_selected.connect(_on_character_selected_confirmed)
	GameManager.character_created.connect(_on_character_created)
	GameManager.character_deleted.connect(_on_character_deleted)
	GameManager.character_error.connect(show_error)
	
	# Initialiser l'interface
	character_info_panel.visible = false
	create_panel.visible = false
	play_button.disabled = true
	delete_button.disabled = true
	
	# Demander la liste des personnages
	request_characters()

func request_characters():
	"""Demande la liste des personnages au serveur"""
	print("[CharacterSelection] Demande de liste des personnages")
	GameManager.request_characters()

func _on_characters_received(data: Dictionary):
	"""Appelé quand on reçoit la liste des personnages"""
	print("[CharacterSelection DEBUG] Données reçues du GameManager: ", data)
	if data.has("success") and data.success:
		characters = data.get("characters", [])
		character_classes = data.get("classes", [])
		print("[CharacterSelection DEBUG] Classes extraites: ", character_classes)
		update_character_slots()
		setup_class_buttons()
	else:
		show_error("Erreur lors du chargement des personnages: " + data.get("error", "Erreur inconnue"))

func update_character_slots():
	"""Met à jour l'affichage des slots de personnages"""
	# Nettoyer les slots existants
	for child in character_slots.get_children():
		child.queue_free()
	
	# Créer 5 slots (limite Dofus)
	for i in range(5):
		var slot = CHARACTER_SLOT_SCENE.instantiate()
		character_slots.add_child(slot)
		
		if i < characters.size():
			# Slot occupé
			var character = characters[i]
			slot.setup_character(character)
			slot.character_selected.connect(_on_character_selected)
		else:
			# Slot vide
			slot.setup_empty()
			slot.empty_slot_clicked.connect(_on_empty_slot_clicked)

func setup_class_buttons():
	"""Configure les boutons de sélection de classe"""
	# Nettoyer les boutons existants
	for child in class_buttons.get_children():
		child.queue_free()
	
	# Créer un bouton pour chaque classe
	for class_info in character_classes:
		var button = Button.new()
		button.text = class_info.name
		button.custom_minimum_size = Vector2(150, 80)
		button.pressed.connect(_on_class_selected.bind(class_info.id))
		class_buttons.add_child(button)

func _on_character_selected(character: Dictionary):
	"""Appelé quand un personnage est sélectionné"""
	selected_character = character
	update_character_info()
	
	play_button.disabled = false
	delete_button.disabled = false

func _on_empty_slot_clicked():
	"""Appelé quand on clique sur un slot vide"""
	_on_create_button_pressed()

func update_character_info():
	"""Met à jour le panneau d'informations du personnage"""
	if selected_character.is_empty():
		character_info_panel.visible = false
		return
	
	character_info_panel.visible = true
	
	# DEBUG: Afficher la structure complète du personnage
	print("[CharacterSelection DEBUG] Structure du personnage sélectionné:")
	print(JSON.stringify(selected_character, "\t"))
	
	# Trouver les informations de la classe
	var class_info = null
	for cls in character_classes:
		if cls.id == selected_character.class:
			class_info = cls
			break
	
	# Mettre à jour les labels
	character_name_label.text = selected_character.name
	character_class_label.text = class_info.name if class_info else selected_character.class
	character_level_label.text = "Niveau " + str(selected_character.level)
	
	# Afficher les stats avec gestion d'erreur
	var stats_text = "Classe: " + str(selected_character.class) + "\n"
	stats_text += "Niveau: " + str(selected_character.level) + "\n"
	
	# Vérifier si le champ stats existe
	if selected_character.has("stats"):
		print("[CharacterSelection DEBUG] Champ 'stats' trouvé")
		stats_text += "Vitalité: " + str(selected_character.stats.vitality) + "\n"
		stats_text += "Sagesse: " + str(selected_character.stats.wisdom) + "\n"
		stats_text += "Force: " + str(selected_character.stats.strength) + "\n"
		stats_text += "Intelligence: " + str(selected_character.stats.intelligence) + "\n"
		stats_text += "Agilité: " + str(selected_character.stats.agility) + "\n"
		stats_text += "\nPV: " + str(selected_character.stats.health) + " / " + str(selected_character.stats.max_health)
	elif selected_character.has("base_stats"):
		print("[CharacterSelection DEBUG] Champ 'base_stats' trouvé")
		stats_text += "Vitalité: " + str(selected_character.base_stats.vitality) + "\n"
		stats_text += "Sagesse: " + str(selected_character.base_stats.wisdom) + "\n"
		stats_text += "Force: " + str(selected_character.base_stats.strength) + "\n"
		stats_text += "Intelligence: " + str(selected_character.base_stats.intelligence) + "\n"
		stats_text += "Agilité: " + str(selected_character.base_stats.agility) + "\n"
		stats_text += "\nPV: " + str(selected_character.base_stats.health) + " / " + str(selected_character.base_stats.max_health)
	else:
		print("[CharacterSelection DEBUG] Ni 'stats' ni 'base_stats' trouvés, utilisation des champs directs")
		# Fallback: utiliser les champs directs
		stats_text += "Vitalité: " + str(selected_character.get("vitality", "N/A")) + "\n"
		stats_text += "Sagesse: " + str(selected_character.get("wisdom", "N/A")) + "\n"
		stats_text += "Force: " + str(selected_character.get("strength", "N/A")) + "\n"
		stats_text += "Intelligence: " + str(selected_character.get("intelligence", "N/A")) + "\n"
		stats_text += "Agilité: " + str(selected_character.get("agility", "N/A")) + "\n"
		stats_text += "\nPV: " + str(selected_character.get("health", "N/A")) + " / " + str(selected_character.get("max_health", "N/A"))
	
	character_stats_label.text = stats_text

func _on_play_button_pressed():
	"""Bouton Jouer pressé"""
	if selected_character.is_empty():
		return
	
	# Envoyer la sélection au serveur via GameManager
	GameManager.select_character(selected_character.id)

func _on_create_button_pressed():
	"""Bouton Créer pressé"""
	if characters.size() >= 5:
		show_error("Vous avez déjà atteint la limite de 5 personnages")
		return
	
	create_panel.visible = true
	create_name_input.text = ""
	selected_class = ""
	create_confirm_button.disabled = true

func _on_delete_button_pressed():
	"""Bouton Supprimer pressé"""
	if selected_character.is_empty():
		return
	
	# Confirmation
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Êtes-vous sûr de vouloir supprimer le personnage '" + selected_character.name + "' ?"
	dialog.add_cancel_button("Annuler")
	add_child(dialog)
	dialog.popup_centered()
	
	var result = await dialog.confirmed
	dialog.queue_free()
	
	if result:
		delete_character(selected_character.id)

func _on_class_selected(class_id: String):
	"""Appelé quand une classe est sélectionnée"""
	selected_class = class_id
	
	# Mettre à jour l'apparence des boutons
	for button in class_buttons.get_children():
		button.modulate = Color.WHITE
	
	# Mettre en surbrillance le bouton sélectionné
	var class_info = null
	for cls in character_classes:
		if cls.id == class_id:
			class_info = cls
			break
	
	if class_info:
		var button_index = character_classes.find(class_info)
		if button_index >= 0 and button_index < class_buttons.get_child_count():
			class_buttons.get_child(button_index).modulate = Color.YELLOW
	
	# Activer le bouton de création si nom et classe sont remplis
	update_create_button_state()

func _on_create_confirm_button_pressed():
	"""Bouton Créer Confirmer pressé"""
	var character_name = create_name_input.text.strip_edges()
	
	if character_name.length() < 3 or character_name.length() > 20:
		show_error("Le nom doit contenir entre 3 et 20 caractères")
		return
	
	if selected_class == "":
		show_error("Veuillez sélectionner une classe")
		return
	
	# Envoyer la création au serveur via GameManager
	GameManager.create_character(character_name, selected_class)

func _on_create_cancel_button_pressed():
	"""Bouton Annuler création pressé"""
	create_panel.visible = false

func update_create_button_state():
	"""Met à jour l'état du bouton de création"""
	var name_valid = create_name_input.text.strip_edges().length() >= 3
	var class_selected = selected_class != ""
	create_confirm_button.disabled = not (name_valid and class_selected)

func _on_create_name_input_text_changed(_new_text: String):
	"""Appelé quand le texte du nom change"""
	update_create_button_state()

func delete_character(character_id: int):
	"""Supprime un personnage"""
	GameManager.delete_character(character_id)

func _on_character_selected_confirmed(data: Dictionary):
	"""Appelé quand la sélection de personnage est confirmée"""
	if data.has("success") and data.success:
		# Stocker le personnage sélectionné
		GameManager.current_character = data.character
		
		# Passer à l'écran de jeu
		get_tree().change_scene_to_file("res://game/main.tscn")
	else:
		show_error("Erreur lors de la sélection: " + data.get("error", "Erreur inconnue"))

func _on_character_created(data: Dictionary):
	"""Appelé quand un personnage est créé"""
	if data.has("success") and data.success:
		create_panel.visible = false
		show_success("Personnage créé avec succès !")
		request_characters() # Recharger la liste
	else:
		show_error("Erreur lors de la création: " + data.get("error", "Erreur inconnue"))

func _on_character_deleted(data: Dictionary):
	"""Appelé quand un personnage est supprimé"""
	if data.has("success") and data.success:
		show_success("Personnage supprimé avec succès")
		selected_character = {}
		request_characters() # Recharger la liste
	else:
		show_error("Erreur lors de la suppression: " + data.get("error", "Erreur inconnue"))

func show_error(message: String):
	"""Affiche un message d'erreur"""
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Erreur"
	add_child(dialog)
	dialog.popup_centered()
	await dialog.confirmed
	dialog.queue_free()

func show_success(message: String):
	"""Affiche un message de succès"""
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Succès"
	add_child(dialog)
	dialog.popup_centered()
	await dialog.confirmed
	dialog.queue_free() 
