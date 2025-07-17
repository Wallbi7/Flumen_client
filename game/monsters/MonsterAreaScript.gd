extends Area2D

# Script attaché à l'Area2D des monstres pour améliorer la détection des clics

var monster_node: Node = null

func _ready():
	# Récupérer le nœud parent (Monster)
	monster_node = get_parent()
	print("[MonsterArea] Script attaché au monstre: ", monster_node.name if monster_node else "ERREUR")

func _gui_input(event: InputEvent):
	"""Détection alternative des clics avec _gui_input - plus fiable que input_event"""
	
	if not monster_node:
		return
		
	if event is InputEventMouseButton:
		print("[MonsterArea] 🖱️ _GUI_INPUT sur ", monster_node.name, " - Bouton: ", event.button_index, " Pressed: ", event.pressed)
		
		if event.pressed:
			print("[MonsterArea] ⚡ CLIC IMMÉDIAT détecté via _gui_input - Bouton: ", event.button_index)
			
			# Empêcher la propagation immédiatement (Godot 4)
			get_viewport().set_input_as_handled()
			
			if event.button_index == MOUSE_BUTTON_LEFT:
				print("[MonsterArea] 🔥 ÉMISSION monster_clicked via _gui_input")
				monster_node.monster_clicked.emit(monster_node)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				print("[MonsterArea] 🔥 ÉMISSION monster_right_clicked via _gui_input")
				monster_node.monster_right_clicked.emit(monster_node)

func _input_event(viewport: Node, event: InputEvent, shape_idx: int):
	"""Backup au cas où _gui_input ne fonctionne pas"""
	if event is InputEventMouseButton and event.pressed:
		print("[MonsterArea] 📡 Backup input_event - Bouton: ", event.button_index) 
