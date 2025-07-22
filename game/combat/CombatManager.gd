extends Node
class_name CombatManager

## GESTIONNAIRE CENTRAL DU SYSTÈME DE COMBAT DOFUS-LIKE
## ====================================================
## Orchestrateur central adapté pour le nouveau système synchronisé avec serveur.
## Gère l'état de combat, les interactions client-serveur et l'interface utilisateur.

# ================================
# RÉFÉRENCES AUX SYSTÈMES
# ================================

## Système de grille de combat (adapté)
var combat_grid: CombatGrid = null

## Interface utilisateur (adaptée)
var combat_ui: CombatUI = null

## Système d'effets visuels pour sorts et effets temporaires
var visual_effects_manager: VisualEffectsManager = null

## Référence au GameManager principal
var game_manager: Node = null

## Référence au WebSocketManager pour communication serveur
var websocket_manager: Node = null

# ================================
# VARIABLES DE COMBAT SYNCHRONISÉES
# ================================

## État actuel du combat (synchronisé avec serveur)
var current_combat_state: CombatState = null

## Indique si un combat est en cours côté client
var is_combat_active: bool = false

## ID du combat actuel sur le serveur
var current_combat_id: String = ""

## Map actuelle où se déroule le combat
var current_map_id: String = ""

## Actions en attente d'envoi au serveur
var pending_actions: Array[Dictionary] = []

# ================================
# SIGNAUX
# ================================

## Émis quand le combat commence
signal combat_started(combat_state: CombatState)

## Émis quand le combat se termine
signal combat_ended(result: Dictionary)

## Émis quand l'état de combat est mis à jour
signal combat_state_updated(combat_state: CombatState)

## Émis quand une action est validée côté client
signal action_validated(action_data: Dictionary)

## Émis quand une action est rejetée
signal action_rejected(reason: String)

# ================================
# INITIALISATION
# ================================

func _ready():
	print("\n[CombatManager] === INITIALISATION ===")
	
	# Chercher GameManager
	game_manager = get_node_or_null("/root/GameManager")
	
	# Chercher WebSocketManager dans la scène principale
	var main_scene = get_tree().current_scene
	if main_scene:
		websocket_manager = main_scene.get_node_or_null("WebSocketManager")
		if not websocket_manager:
			# Fallback: chercher dans GameManager
			if game_manager and game_manager.has_method("get_websocket_manager"):
				websocket_manager = game_manager.get_websocket_manager()
	
	# Initialiser les effets visuels
	_initialize_visual_effects()
	
	# Logger l'état
	if game_manager:
		print("[CombatManager] ✅ GameManager trouvé")
	else:
		print("[CombatManager] ⚠️ GameManager non trouvé")
	
	if websocket_manager:
		print("[CombatManager] ✅ WebSocketManager trouvé")
		# Connecter aux signaux réseau pour recevoir les mises à jour de combat
		_connect_network_signals()
	else:
		print("[CombatManager] ⚠️ WebSocketManager non trouvé")

## Initialise le système d'effets visuels
func _initialize_visual_effects():
	# Créer le gestionnaire d'effets visuels
	visual_effects_manager = VisualEffectsManager.new()
	add_child(visual_effects_manager)
	
	# Connecter aux signaux d'effets
	visual_effects_manager.animation_completed.connect(_on_visual_effect_completed)
	visual_effects_manager.visual_effect_started.connect(_on_visual_effect_started)
	
	print("[CombatManager] 🎨 Système d'effets visuels initialisé")

## Callback quand un effet visuel se termine
func _on_visual_effect_completed(effect_type: String):
	print("[CombatManager] ✨ Effet visuel terminé: %s" % effect_type)

## Callback quand un effet visuel commence
func _on_visual_effect_started(position: Vector2, type: String):
	print("[CombatManager] 🎆 Effet visuel démarré: %s à %s" % [type, position])

## Connecte les signaux réseau pour la synchronisation
func _connect_network_signals():
	if not websocket_manager:
		print("[CombatManager] ❌ Impossible de connecter les signaux réseau - WebSocketManager manquant")
		return
		
	# Connecter aux signaux WebSocket pour les mises à jour de combat
	if websocket_manager.has_signal("combat_update"):
		websocket_manager.connect("combat_update", _on_combat_update_from_server)
		print("[CombatManager] ✅ Signal combat_update connecté")
		
	if websocket_manager.has_signal("combat_action_response"):
		websocket_manager.connect("combat_action_response", _on_combat_action_response)
		print("[CombatManager] ✅ Signal combat_action_response connecté")
		
	if websocket_manager.has_signal("combat_ended"):
		websocket_manager.connect("combat_ended", _on_combat_ended_from_server)
		print("[CombatManager] ✅ Signal combat_ended connecté")

## Initialise tous les systèmes de combat
func initialize_combat_systems():
	print("[CombatManager] 🔧 Initialisation des systèmes de combat...")
	
	# Créer les systèmes de combat
	_create_combat_grid()
	_create_combat_ui()
	
	# Connecter les systèmes entre eux
	_connect_systems()
	
	print("[CombatManager] ✅ Tous les systèmes de combat initialisés")

## Crée et configure le système de grille
func _create_combat_grid():
	if not is_instance_valid(combat_grid):
		print("[CombatManager] 🔧 Création de la grille de combat...")
		
		# Charger la scène CombatGrid
		var grid_scene = preload("res://game/combat/CombatGrid.tscn")
		if grid_scene:
			combat_grid = grid_scene.instantiate()
		else:
			print("[CombatManager] ❌ Impossible de charger CombatGrid.tscn")
			return
		
		# Trouver la scène principale pour ajouter la grille
		var main_scene = get_tree().current_scene
		if main_scene:
			main_scene.add_child(combat_grid)
			print("[CombatManager] ✅ Grille ajoutée à la scène principale")
		else:
			add_child(combat_grid)
			print("[CombatManager] ✅ Grille ajoutée au CombatManager")
		
		combat_grid.name = "CombatGrid"
		combat_grid.z_index = 1000
		combat_grid.z_as_relative = false
		
		# Configurer la référence de grille pour les effets visuels
		if visual_effects_manager:
			visual_effects_manager.setup_grid_reference(combat_grid)
			print("[CombatManager] 🎨 Référence grille configurée pour effets visuels")
	else:
		print("[CombatManager] ♻️ Grille de combat déjà existante")
		# S'assurer que la référence est configurée même pour une grille existante
		if visual_effects_manager and combat_grid:
			visual_effects_manager.setup_grid_reference(combat_grid)

## Crée et configure l'interface utilisateur
func _create_combat_ui():
	if not combat_ui:
		print("[CombatManager] 🔧 Création de l'interface de combat...")
		
		# Charger la scène UI
		var ui_scene = preload("res://game/combat/CombatUI.tscn")
		if ui_scene:
			combat_ui = ui_scene.instantiate()
			
			# Trouver le CanvasLayer principal pour l'UI
			var main_scene = get_tree().current_scene
			if main_scene:
				main_scene.add_child(combat_ui)
				print("[CombatManager] ✅ Interface ajoutée à la scène principale")
			else:
				add_child(combat_ui)
				print("[CombatManager] ✅ Interface ajoutée au CombatManager")
		else:
			print("[CombatManager] ❌ Impossible de charger CombatUI.tscn")
	else:
		print("[CombatManager] ♻️ Interface de combat déjà existante")

## Connecte les systèmes entre eux
func _connect_systems():
	if combat_grid:
		combat_grid.cell_clicked.connect(_on_grid_cell_clicked)
		combat_grid.invalid_action.connect(_on_grid_invalid_action)
		print("[CombatManager] 🔗 Grille connectée")
	
	if combat_ui:
		combat_ui.action_requested.connect(_on_ui_action_requested)
		print("[CombatManager] 🔗 Interface connectée")

# ================================
# GESTION DU COMBAT PRINCIPAL
# ================================

## Démarre un nouveau combat depuis les données serveur
func start_combat_from_server(combat_data: Dictionary):
	print("[CombatManager] 🚀 Démarrage combat depuis serveur...")
	
	# Créer l'état de combat depuis les données serveur
	current_combat_state = CombatState.from_server_data(combat_data)
	current_combat_id = current_combat_state.id
	is_combat_active = true
	
	# Initialiser les systèmes si nécessaire
	if not combat_grid or not combat_ui:
		initialize_combat_systems()
	
	# TRANSITION STYLE DOFUS : Démarrer en phase de placement
	_start_placement_phase()
	
	combat_started.emit(current_combat_state)
	print("[CombatManager] ✅ Combat démarré - ID: ", current_combat_id)

## Crée un état de combat minimal pour la phase de placement
func _create_minimal_combat_state_for_placement():
	"""Crée un état de combat minimal quand pas de données serveur"""
	print("[CombatManager] 🔧 Création état de combat minimal pour placement")
	
	current_combat_state = CombatState.new()
	current_combat_state.id = "local_combat_" + str(Time.get_unix_time_from_system())
	current_combat_state.status = CombatState.CombatStatus.PLACEMENT
	current_combat_state.grid_width = combat_grid.grid_width if combat_grid else 17
	current_combat_state.grid_height = combat_grid.grid_height if combat_grid else 15
	current_combat_state.turn_duration = 30.0  # 30 secondes par défaut
	current_combat_state.turn_start_time = Time.get_unix_time_from_system()
	
	# Créer un combattant minimal pour le joueur
	if game_manager and game_manager.current_player:
		var player_combatant = CombatState.Combatant.new()
		player_combatant.character_id = "local_player"
		player_combatant.name = "Joueur"
		player_combatant.is_player = true
		player_combatant.team_id = 0
		player_combatant.max_health = 100
		player_combatant.current_health = 100
		player_combatant.base_action_points = 6
		player_combatant.remaining_action_points = 6
		player_combatant.base_movement_points = 3
		player_combatant.remaining_movement_points = 3
		current_combat_state.combatants.append(player_combatant)
	
	current_combat_id = current_combat_state.id
	is_combat_active = true
	
	# Mettre à jour l'interface avec cet état
	if combat_ui:
		combat_ui.update_from_combat_state(current_combat_state)
	
	print("[CombatManager] ✅ État de combat minimal créé")

## Démarre la phase de placement style Dofus
func _start_placement_phase():
	"""Démarre la phase de placement où les joueurs choisissent leurs positions"""
	print("[CombatManager] 🎯 === PHASE DE PLACEMENT DOFUS ===")
	
	# 1. Créer l'effet de transition
	_create_transition_effect()
	
	# 2. Masquer temporairement la carte du monde
	_hide_world_map()
	
	# 3. Centrer la caméra sur la zone de combat
	_center_camera_on_combat()
	
	# 4. Afficher la grille avec les zones de placement
	_show_placement_grid()
	
	# 5. Afficher l'interface de placement
	_show_placement_interface()
	
	# 6. Positionner les monstres (mais pas le joueur)
	_place_monsters_only()
	
	print("[CombatManager] ✅ Phase de placement initiée - Joueur peut choisir sa position")

## Affiche la grille avec les zones de placement visibles
func _show_placement_grid():
	"""Affiche la grille de combat avec les zones de placement bleues et rouges"""
	if combat_grid:
		combat_grid.show_grid()
		# Forcer l'affichage des zones de placement APRÈS que la grille soit visible
		print("[CombatManager] 🎯 Affichage grille et création zones de placement...")
		combat_grid._create_default_dofus_placement_zones()
		
		# DOUBLE VÉRIFICATION: Re-forcer l'affichage si nécessaire
		await get_tree().process_frame  # Attendre une frame pour que les nodes soient prêts
		combat_grid._generate_visual_grid()  # Régénérer encore une fois pour être sûr
		
		# TRIPLE VÉRIFICATION: Marquer que les zones ne doivent pas être écrasées
		combat_grid._preserve_local_placement_zones()
		
		print("[CombatManager] ✅ Grille de placement affichée avec zones bleu/rouge FORCÉES et PROTÉGÉES")

## Affiche l'interface spécifique à la phase de placement
func _show_placement_interface():
	"""Affiche l'interface de placement avec le bouton Prêt"""
	if combat_ui:
		combat_ui.show_combat_ui()
		# Mettre en mode placement
		combat_ui.set_placement_mode(true)
		
		# Forcer le démarrage du timer avec état de placement
		if current_combat_state:
			current_combat_state.status = CombatState.CombatStatus.PLACEMENT
			combat_ui.update_from_combat_state(current_combat_state)
		else:
			# Créer un état minimal pour le timer
			_create_minimal_combat_state_for_placement()
		
		print("[CombatManager] ✅ Interface de placement affichée avec timer")

## Place uniquement les monstres, pas le joueur
func _place_monsters_only():
	"""Place les monstres selon les données du serveur (combattants)"""
	print("[CombatManager] 🐲 === PLACEMENT DES MONSTRES ===")
	
	if not combat_grid:
		print("[CombatManager] ❌ Grille de combat non disponible")
		return
		
	if not current_combat_state:
		print("[CombatManager] ❌ État de combat non disponible")
		return
		
	var grid_width = combat_grid.grid_width
	var grid_height = combat_grid.grid_height
	print("[CombatManager] 📏 Dimensions grille: %dx%d" % [grid_width, grid_height])
	
	# Utiliser les combattants du serveur au lieu des monstres locaux
	var monster_combatants = []
	for combatant in current_combat_state.combatants:
		if not combatant.is_player:
			monster_combatants.append(combatant)
	
	print("[CombatManager] 🎯 %d monstres combattants trouvés dans l'état de combat" % monster_combatants.size())
	
	if monster_combatants.is_empty():
		print("[CombatManager] ⚠️ Aucun monstre combattant dans l'état de combat")
		return
	
	# NOUVEAU: Utiliser UNIQUEMENT les zones ennemies du serveur (JSON config ou default)
	var available_enemy_positions: Array[Vector2i] = []
	
	# Utiliser les zones ennemies définies par le serveur (JSON config ou default)
	if current_combat_state and current_combat_state.enemy_placement_cells:
		for pos in current_combat_state.enemy_placement_cells:
			if combat_grid.is_valid_grid_position(pos):
				# Ajouter toutes les positions disponibles (pas de filtre libre)
				available_enemy_positions.append(pos)
	else:
		print("[CombatManager] ⚠️ Aucune zone ennemie définie par le serveur, utilisation fallback")
		# Fallback: utiliser les zones bleues par défaut (gauche)
		for y in range(grid_height):
			for x in range(4):  # 4 colonnes à gauche
				available_enemy_positions.append(Vector2i(x, y))
	
	print("[CombatManager] 🎯 %d positions ennemies disponibles (serveur)" % available_enemy_positions.size())
	
	# Mélanger les positions pour un placement aléatoire
	available_enemy_positions.shuffle()
	
	# SUPPRESSION LIMITE 3 MONSTRES: Placer TOUS les monstres du combat
	for i in range(monster_combatants.size()):
		var combatant = monster_combatants[i]
		
		# Choisir position aléatoire dans les zones ennemies
		var grid_pos: Vector2i
		if available_enemy_positions.size() > 0:
			grid_pos = available_enemy_positions[i % available_enemy_positions.size()]
		else:
			# Fallback si aucune position
			grid_pos = Vector2i(i % 4, 5 + (i / 4))
		
		print("[CombatManager] 🔵 Placement monstre %s aléatoirement en zone ennemie: %s" % [combatant.name, grid_pos])
		
		# Créer ou récupérer la représentation visuelle du monstre
		var monster_visual = _create_monster_visual_from_combatant(combatant)
		if not monster_visual:
			print("[CombatManager] ❌ Impossible de créer la représentation visuelle pour %s" % combatant.name)
			continue
			
		# Calculer position monde
		var world_pos = combat_grid.grid_to_screen(grid_pos) + combat_grid.global_position
		monster_visual.global_position = world_pos
		
		# S'assurer que le monstre est visible et au premier plan
		monster_visual.visible = true
		monster_visual.z_index = 1000  # Premier plan absolu (même niveau que joueur)
		
		print("[CombatManager] 🎭 Monstre placé au premier plan - z_index: 1000")
		
		# Marquer la cellule comme occupée
		combat_grid.set_cell_occupied(grid_pos, str(combatant.character_id))
		combat_grid.set_cell_state(grid_pos, combat_grid.CellState.OCCUPIED_ENEMY)
		
		print("[CombatManager] ✅ Monstre '%s' placé: Grille%s -> Monde%s" % [combatant.name, grid_pos, world_pos])
	
	print("[CombatManager] ✅ Placement terminé: %d monstres placés (SANS LIMITE)" % monster_combatants.size())

## Crée une représentation visuelle d'un monstre à partir des données combattant
func _create_monster_visual_from_combatant(combatant) -> Node2D:
	"""Crée un nœud visuel pour un monstre combattant"""
	
	# D'abord essayer de trouver le monstre existant par nom/type
	if game_manager and game_manager.monsters:
		for monster_id in game_manager.monsters.keys():
			var existing_monster = game_manager.monsters[monster_id]
			if existing_monster and existing_monster.monster_name == combatant.name:
				print("[CombatManager] 🔄 Réutilisation du monstre existant: %s" % combatant.name)
				
				# SYSTÈME RE-PARENTAGE: Si le monstre existe déjà sur la map, le re-parenter
				var combat_parent = combat_grid.get_parent()
				if combat_parent and existing_monster.get_parent() != combat_parent:
					# Détacher du parent actuel (la map masquée)
					var old_parent = existing_monster.get_parent()
					if old_parent:
						old_parent.remove_child(existing_monster)
						print("[CombatManager] 🔄 Monstre détaché de: %s" % old_parent.name)
					
					# Rattacher au parent de combat visible
					combat_parent.add_child(existing_monster)
					existing_monster.visible = true
					print("[CombatManager] ✅ Monstre re-parenté vers la scène de combat visible")
				
				return existing_monster
	
	# Créer un nouveau nœud monstre simple si nécessaire
	print("[CombatManager] 🆕 Création d'un nouveau monstre visuel: %s" % combatant.name)
	
	# Essayer de charger le template Monster
	var monster_scene = preload("res://game/monsters/Monster.tscn")
	if not monster_scene:
		print("[CombatManager] ❌ Scene Monster.tscn introuvable")
		return null
		
	var monster_node = monster_scene.instantiate()
	if not monster_node:
		print("[CombatManager] ❌ Impossible d'instancier Monster.tscn")
		return null
	
	# Configurer le monstre
	monster_node.monster_name = combatant.name
	monster_node.monster_id = str(combatant.character_id)
	
	# L'ajouter à la scène de combat
	var combat_parent = combat_grid.get_parent()
	if combat_parent:
		combat_parent.add_child(monster_node)
		print("[CombatManager] ✅ Monstre ajouté à la scène de combat")
	else:
		print("[CombatManager] ❌ Parent de combat_grid introuvable")
		monster_node.queue_free()
		return null
	
	return monster_node

## Confirme le placement et démarre le combat
func confirm_placement():
	"""Appelé quand le joueur appuie sur le bouton Prêt"""
	print("[CombatManager] ✅ Placement confirmé - Démarrage du combat")
	
	# Vérifier que le joueur est bien placé
	if not _is_player_placed_correctly():
		print("[CombatManager] ❌ Joueur mal placé - doit être dans la zone rouge")
		return
	
	# NOUVEAU: Notifier le serveur que le placement est terminé
	_send_placement_done_to_server()
	
	# Cacher les zones de placement
	if combat_grid:
		combat_grid.clear_placement_zones()
	
	# Mettre l'interface en mode combat
	if combat_ui:
		combat_ui.set_placement_mode(false)
	
	# Démarrer le vrai combat
	_start_actual_combat()

## Vérifie que le joueur est correctement placé
func _is_player_placed_correctly() -> bool:
	"""Vérifie que le joueur est placé dans la zone rouge"""
	if not combat_grid or not game_manager or not game_manager.current_player:
		return false
	
	# Chercher la position du joueur sur la grille
	for y in range(combat_grid.grid_height):
		for x in range(combat_grid.grid_width):
			var pos = Vector2i(x, y)
			var cell_data = combat_grid.get_cell_data(pos)
			if cell_data["occupied_by"] == "player":
				# Vérifier si c'est dans la zone rouge (côté droit)
				if x >= combat_grid.grid_width - 4:
					print("[CombatManager] ✅ Joueur correctement placé dans la zone rouge")
					return true
				else:
					print("[CombatManager] ❌ Joueur dans la mauvaise zone")
					return false
	
	print("[CombatManager] ❌ Joueur non trouvé sur la grille")
	return false

## Démarre le combat après la phase de placement
func _start_actual_combat():
	"""Démarre le combat après que tous les joueurs soient placés"""
	# Mettre à jour l'état si on a un état de combat
	if current_combat_state:
		current_combat_state.status = CombatState.CombatStatus.IN_PROGRESS
	
	# Afficher les portées d'action selon le tour
	if combat_grid:
		combat_grid._update_action_ranges()

func _start_combat_transition():
	"""Démarre la transition style Dofus vers le mode combat"""
	# Transition vers le mode combat
	
	# 1. Créer l'effet de transition (fondu)
	_create_transition_effect()
	
	# 2. Masquer temporairement la carte du monde
	_hide_world_map()
	
	# 3. Centrer la caméra sur la zone de combat
	_center_camera_on_combat()
	
	# 4. Téléporter les entités sur la grille
	_teleport_entities_to_grid()
	
	# 5. Afficher l'interface de combat
	_show_combat_interface()
	
	# 6. Terminer la transition
	_finish_transition()

func _create_transition_effect():
	"""Crée l'effet de transition visuel"""
	print("[CombatManager] ✨ Création effet de transition...")
	
	# Créer un overlay noir pour la transition
	var transition_overlay = ColorRect.new()
	transition_overlay.color = Color(0, 0, 0, 0)  # Noir transparent
	transition_overlay.size = get_viewport().size
	transition_overlay.name = "CombatTransition"
	
	# Ajouter à la scène
	get_tree().current_scene.add_child(transition_overlay)
	
	# Animation de fondu entrant
	var tween = create_tween()
	tween.tween_property(transition_overlay, "color:a", 1.0, 0.3)  # Fondu vers noir
	tween.tween_callback(_on_transition_mid_point)
	tween.tween_property(transition_overlay, "color:a", 0.0, 0.3)  # Fondu depuis noir
	tween.tween_callback(_on_transition_complete.bind(transition_overlay))

func _on_transition_mid_point():
	"""Appelé au milieu de la transition - moment de la téléportation"""
	print("[CombatManager] 🎯 Milieu de transition - Téléportation...")
	
	# Masquer la carte du monde
	_hide_world_map()
	
	# Centrer la caméra
	_center_camera_on_combat()
	
	# Téléporter les entités
	_teleport_entities_to_grid()

func _on_transition_complete(transition_overlay: ColorRect):
	"""Appelé à la fin de la transition"""
	print("[CombatManager] ✅ Transition terminée")
	
	# Supprimer l'overlay de transition
	if transition_overlay:
		transition_overlay.queue_free()
	
	# Afficher l'interface de combat
	_show_combat_interface()
	
	# Mettre à jour tous les systèmes
	_update_all_systems()

func _hide_world_map():
	"""Masque la carte du monde pendant le combat"""
	print("[CombatManager] 🗺️ Masquage de la carte du monde...")
	
	if game_manager and game_manager.current_map:
		game_manager.current_map.visible = false
		print("[CombatManager] ✅ Carte masquée")

func _center_camera_on_combat():
	"""Centre la caméra sur la zone de combat en conservant la position du joueur"""
	print("[CombatManager] 📷 Centrage caméra sur combat...")
	
	# CORRECTION: Ne pas forcer le centrage de la caméra pour conserver la position relative
	# La caméra doit suivre le joueur normalement
	
	# Obtenir la caméra principale
	var camera = get_viewport().get_camera_2d()
	if camera and game_manager and game_manager.current_player:
		# Centrer la caméra sur la position du joueur au lieu du centre de l'écran
		var player_pos = game_manager.current_player.global_position
		camera.global_position = player_pos
		print("[CombatManager] ✅ Caméra centrée sur le joueur à: ", player_pos)
	
	# CORRECTION: Ne pas forcer le centrage de la grille pour conserver les positions relatives
	# La grille doit rester à sa position naturelle par rapport à la carte
	if combat_grid:
		print("[CombatManager] ✅ Grille conserve sa position naturelle (pas de recentrage forcé)")

func _teleport_entities_to_grid():
	"""Téléporte le joueur et les monstres sur la grille de combat"""
	print("[CombatManager] 🌀 Téléportation des entités sur la grille...")
	
	if not combat_grid:
		print("[CombatManager] ⚠️ Grille de combat non disponible")
		return
	
	# Obtenir les dimensions adaptatives de la grille
	var screen_size = get_viewport().get_visible_rect().size
	var grid_center = screen_size / 2.0
	
	# Utiliser les dimensions de cellules de la grille
	var cell_width = combat_grid.CELL_WIDTH
	var cell_height = combat_grid.CELL_HEIGHT
	
	# Calculer les positions sur la grille (en coordonnées de grille)
	var grid_width = combat_grid.grid_width
	var grid_height = combat_grid.grid_height
	
	# CORRECTION: Ne pas téléporter le joueur automatiquement en phase de placement
	# Le joueur doit rester à sa position actuelle et pourra se placer manuellement
	if game_manager and game_manager.current_player:
		print("[CombatManager] 👤 Joueur conserve sa position actuelle pendant la phase de placement")
		print("[CombatManager] 📍 Position actuelle du joueur: ", game_manager.current_player.global_position)
		
		# Faire regarder le joueur vers les monstres (vers la gauche) mais sans le déplacer
		var player = game_manager.current_player
		if player.has_method("set_facing_direction"):
			player.set_facing_direction(-1)  # Face à gauche vers les monstres (zone bleue)
		elif player.sprite and player.sprite is Sprite2D:
			player.sprite.flip_h = true  # Miroir (face à gauche)
		
		print("[CombatManager] ✅ Orientation du joueur ajustée pour le combat")
	
	# Téléporter les monstres (zone BLEUE - position ennemie côté gauche)
	if game_manager and game_manager.monsters:
		var monster_base_pos = Vector2i(2, int(grid_height / 2))  # Zone bleue (3ème colonne depuis la gauche), milieu
		var monster_count = 0
		for monster_id in game_manager.monsters.keys():
			var monster = game_manager.monsters[monster_id]
			if monster and is_instance_valid(monster):
				# Positionner les monstres en ligne dans la zone bleue
				var adjusted_pos = Vector2i(monster_base_pos.x, monster_base_pos.y + monster_count - 1)
				var monster_world_pos = combat_grid.grid_to_screen(adjusted_pos) + combat_grid.global_position
				monster.global_position = monster_world_pos
				
				print("[CombatManager] 🔵 Monstre placé en zone BLEUE: ", adjusted_pos)
				
				# Faire regarder le monstre vers le joueur (vers la droite)
				if monster.has_method("set_facing_direction"):
					monster.set_facing_direction(1)  # Face à droite vers le joueur (zone rouge)
				else:
					# Essayer de trouver et retourner le sprite
					var sprite_node = monster.get_node_or_null("Sprite2D")
					if not sprite_node:
						sprite_node = monster.get_node_or_null("sprite")
					if sprite_node and sprite_node is Sprite2D:
						sprite_node.flip_h = false  # Normal (face à droite vers joueur)
				
				print("[CombatManager] ✅ Monstre téléporté à: ", monster_world_pos, " (grille: ", adjusted_pos, ") - Zone bleue Dofus")
				monster_count += 1
				# SUPPRESSION LIMITE 3 MONSTRES: Continuer avec tous les monstres

func _finish_transition():
	"""Finalise la transition"""
	print("[CombatManager] 🎉 Finalisation de la transition...")
	
	# Ici on peut ajouter des effets sonores, particles, etc.
	# Pour l'instant, juste un log
	print("[CombatManager] ✅ Transition combat style Dofus terminée !")

## Met à jour l'état de combat depuis le serveur
func update_combat_state(new_combat_data: Dictionary):
	if not is_combat_active:
		print("[CombatManager] ⚠️ Pas de combat actif - Mise à jour ignorée")
		return
	
	# Mettre à jour l'état depuis les données serveur
	current_combat_state = CombatState.from_server_data(new_combat_data)
	
	# Mettre à jour tous les systèmes
	_update_all_systems()
	
	print("[CombatManager] 🔄 État de combat mis à jour depuis serveur")

## Callback pour les mises à jour de combat du serveur
func _on_combat_update_from_server(update_data: Dictionary):
	print("[CombatManager] 📡 Mise à jour de combat reçue du serveur")
	update_combat_state(update_data)

## Callback pour les réponses d'action de combat
func _on_combat_action_response(response_data: Dictionary):
	print("[CombatManager] 📡 Réponse d'action de combat reçue: ", response_data)
	# TODO: Traiter la réponse selon le type d'action

## Callback pour la fin de combat
func _on_combat_ended_from_server(end_data: Dictionary):
	print("[CombatManager] 📡 Fin de combat reçue du serveur")
	var result_data = {}
	if end_data.has("winner"):
		result_data["winner"] = end_data.winner
		result_data["victory"] = end_data.winner == "player"
	else:
		result_data["winner"] = "unknown"
		result_data["victory"] = false
	end_combat(result_data)

## Met à jour tous les systèmes avec l'état actuel
func _update_all_systems():
	if not current_combat_state:
		return
	
	# Mettre à jour la grille
	if combat_grid:
		combat_grid.update_from_combat_state(current_combat_state)
	
	# Mettre à jour l'interface
	if combat_ui:
		combat_ui.update_from_combat_state(current_combat_state)
	
	print("[CombatManager] 🔄 Tous les systèmes mis à jour")

## Affiche l'interface de combat
func _show_combat_interface():
	if combat_ui:
		combat_ui.show_combat_ui()
		print("[CombatManager] 👁️ Interface de combat affichée")

	if combat_grid:
		combat_grid.show_grid()
		print("[CombatManager] 🗺️ Grille de combat affichée")

## Termine le combat (méthode publique pour tests)
func end_combat(result_data: Dictionary = {}):
	print("[CombatManager] 🏁 Fin du combat (demandée)")
	_end_combat_with_result(result_data)

## Termine le combat et nettoie les ressources
func _end_combat():
	_end_combat_with_result({})

## Implémentation interne de fin de combat avec résultat personnalisé
func _end_combat_with_result(result_data: Dictionary):
	print("[CombatManager] 🏁 Fin du combat")
	
	is_combat_active = false
	var status_str = "UNKNOWN"
	if current_combat_state != null and is_instance_valid(current_combat_state):
		status_str = str(current_combat_state.status)
		
	var result = {
		"combat_id": current_combat_id,
		"status": status_str
	}
	
	# Fusionner les données de résultat personnalisées
	for key in result_data:
		result[key] = result_data[key]
	
	# TRANSITION STYLE DOFUS : Retour au monde
	_start_exit_combat_transition()
	
	# Nettoyer l'état
	current_combat_state = null
	current_combat_id = ""
	pending_actions.clear()
	
	combat_ended.emit(result)

func _start_exit_combat_transition():
	"""Démarre la transition de sortie de combat style Dofus"""
	# Transition de sortie de combat
	
	# Créer l'effet de transition
	_create_exit_transition_effect()

func _create_exit_transition_effect():
	"""Crée l'effet de transition de sortie"""
	print("[CombatManager] ✨ Création effet de sortie...")
	
	# Créer un overlay noir pour la transition
	var transition_overlay = ColorRect.new()
	transition_overlay.color = Color(0, 0, 0, 0)  # Noir transparent
	transition_overlay.size = get_viewport().size
	transition_overlay.name = "CombatExitTransition"
	
	# Ajouter à la scène
	get_tree().current_scene.add_child(transition_overlay)
	
	# Animation de fondu
	var tween = create_tween()
	tween.tween_property(transition_overlay, "color:a", 1.0, 0.3)  # Fondu vers noir
	tween.tween_callback(_on_exit_transition_mid_point)
	tween.tween_property(transition_overlay, "color:a", 0.0, 0.3)  # Fondu depuis noir
	tween.tween_callback(_on_exit_transition_complete.bind(transition_overlay))

func _on_exit_transition_mid_point():
	"""Appelé au milieu de la transition de sortie"""
	print("[CombatManager] 🎯 Milieu transition sortie - Restauration monde...")
	
	# Masquer l'interface de combat
	if combat_ui:
		combat_ui.hide_combat_ui()
	
	if combat_grid:
		combat_grid.hide_grid()
	
	# Nettoyer les effets visuels
	clear_visual_effects()
	
	# Restaurer la carte du monde
	_restore_world_map()
	
	# Restaurer les positions des entités
	_restore_entities_positions()

func _on_exit_transition_complete(transition_overlay: ColorRect):
	"""Appelé à la fin de la transition de sortie"""
	print("[CombatManager] ✅ Transition sortie terminée")
	
	# Supprimer l'overlay de transition
	if transition_overlay:
		transition_overlay.queue_free()
	
	print("[CombatManager] 🌍 Retour au monde terminé")

func _restore_world_map():
	"""Restaure la visibilité de la carte du monde"""
	print("[CombatManager] 🗺️ Restauration de la carte du monde...")
	
	if game_manager and game_manager.current_map:
		game_manager.current_map.visible = true
		print("[CombatManager] ✅ Carte restaurée")

func _restore_entities_positions():
	"""Restaure les positions des entités dans le monde"""
	print("[CombatManager] 🔄 Restauration positions entités...")
	
	# Restaurer la position du joueur (peut être configurée depuis le serveur)
	if game_manager and game_manager.current_player:
		# Pour l'instant, on garde la position actuelle
		# Dans le futur, on pourrait restaurer la position pré-combat
		print("[CombatManager] ✅ Position joueur maintenue")
	
	# Restaurer les monstres qui ont été re-parentés
	if game_manager and game_manager.monsters:
		for monster_id in game_manager.monsters.keys():
			var monster = game_manager.monsters[monster_id]
			if monster and is_instance_valid(monster):
				# Si l'entité monstre a été reparentée hors de la map, la replacer
				if monster.get_parent() != game_manager.current_map:
					var old_parent = monster.get_parent()
					if old_parent:
						old_parent.remove_child(monster)
					game_manager.current_map.add_child(monster)
					print("[CombatManager] 🔄 Monstre %s re-parenté vers la map" % monster.monster_name)
				
				# Si le monstre est mort en combat, le détruire
				if not monster.is_alive:
					game_manager.monsters.erase(monster_id)
					monster.queue_free()
					print("[CombatManager] 💀 Monstre %s détruit car mort en combat" % monster.monster_name)
				else:
					# Sinon, repositionner le monstre à sa position d'origine si possible
					if monster.monster_data.has("original_pos_x") and monster.monster_data.has("original_pos_y"):
						monster.global_position = Vector2(monster.monster_data.original_pos_x, monster.monster_data.original_pos_y)
						print("[CombatManager] 📍 Monstre %s repositionné à sa position d'origine" % monster.monster_name)
					monster.visible = true
	
	print("[CombatManager] ✅ Positions restaurées")

# ================================
# SYNCHRONISATION PLACEMENT SERVEUR
# ================================

## Envoie un message au serveur pour confirmer le placement terminé
func _send_placement_done_to_server():
	"""Notifie le serveur que le joueur a terminé son placement"""
	print("[CombatManager] 📤 Envoi confirmation placement au serveur...")
	
	if not websocket_manager:
		print("[CombatManager] ⚠️ WebSocketManager non disponible - Placement non synchronisé")
		return
	
	# Obtenir la position finale du joueur
	var player_pos = _get_player_grid_position()
	
	var placement_data = {
		"type": "placement_done",
		"data": {
			"combat_id": current_combat_id,
			"player_id": _get_local_player_id(),
			"player_position": {
				"x": player_pos.x,
				"y": player_pos.y
			}
		}
	}
	
	# Envoyer via WebSocket
	if websocket_manager.has_method("send_combat_message"):
		websocket_manager.send_combat_message(placement_data)
		print("[CombatManager] ✅ Confirmation placement envoyée: ", placement_data)
	elif websocket_manager.has_method("send_message"):
		websocket_manager.send_message(placement_data)
		print("[CombatManager] ✅ Confirmation placement envoyée (méthode générique): ", placement_data)
	else:
		print("[CombatManager] ⚠️ Méthode d'envoi WebSocket non trouvée")

## Obtient la position grille actuelle du joueur
func _get_player_grid_position() -> Vector2i:
	"""Retourne la position du joueur sur la grille"""
	if not combat_grid:
		return Vector2i(-1, -1)
	
	# Chercher la position du joueur sur la grille
	for y in range(combat_grid.grid_height):
		for x in range(combat_grid.grid_width):
			var pos = Vector2i(x, y)
			var cell_data = combat_grid.get_cell_data(pos)
			if cell_data.get("occupied_by", "") == "player":
				return pos
	
	return Vector2i(-1, -1)

## Obtient l'ID du joueur local pour les messages serveur
func _get_local_player_id() -> String:
	"""Retourne l'ID du joueur local"""
	if game_manager and game_manager.current_player:
		return game_manager.current_player.get("player_id", "local_player")
	return "local_player"

# ================================
# GESTION DES ACTIONS JOUEUR
# ================================

## Gestionnaire des clics sur la grille
func _on_grid_cell_clicked(grid_pos: Vector2i, action_type: CombatState.ActionType, action_data: Dictionary):
	print("[CombatManager] 🎯 Clic grille: ", grid_pos, " - Action: ", action_type)
	
	# Valider que c'est le tour du joueur
	if not _is_player_turn():
		action_rejected.emit("Ce n'est pas votre tour")
		return
	
	# Préparer les données d'action pour le serveur
	var server_action = {
		"combat_id": current_combat_id,
		"action_type": action_type,
		"grid_x": grid_pos.x,
		"grid_y": grid_pos.y
	}
	
	# Ajouter les données spécifiques à l'action
	for key in action_data:
		server_action[key] = action_data[key]
	
	# Envoyer au serveur
	_send_action_to_server(server_action)

## Gestionnaire des actions demandées par l'UI
func _on_ui_action_requested(action_type: CombatState.ActionType, action_data: Dictionary):
	print("[CombatManager] 🎛️ Action UI: ", action_type)
	
	# Mettre à jour l'action courante sur la grille
	if combat_grid:
		var spell_id = action_data.get("spell_id", "")
		combat_grid.set_current_action(action_type, spell_id)
	
	# Si c'est une action directe (passer le tour), l'envoyer immédiatement
	if action_type == CombatState.ActionType.PASS_TURN:
		var server_action = {
			"combat_id": current_combat_id,
			"action_type": action_type
		}
		_send_action_to_server(server_action)

## Gestionnaire des actions invalides sur la grille
func _on_grid_invalid_action(reason: String):
	print("[CombatManager] ❌ Action invalide: ", reason)
	action_rejected.emit(reason)

## Vérifie si c'est le tour du joueur local
func _is_player_turn() -> bool:
	if not current_combat_state:
		return false
	
	var current_combatant = current_combat_state.get_current_combatant()
	if not current_combatant:
		return false
	
	# TODO: Comparer avec l'ID du personnage du joueur local
	return current_combatant.is_player and current_combatant.team_id == 0

## Envoie une action au serveur
func _send_action_to_server(action_data: Dictionary):
	print("[CombatManager] 📤 Envoi action au serveur: ", action_data)
	
	# Ajouter à la liste des actions en attente
	pending_actions.append(action_data)
	
	# TODO: Envoyer via NetworkManager
	if websocket_manager and websocket_manager.has_method("send_combat_action"):
		websocket_manager.send_combat_action(action_data)
	else:
		print("[CombatManager] ⚠️ WebSocketManager non disponible - Action mise en attente")
	
	action_validated.emit(action_data)

# ================================
# MÉTHODES EFFETS VISUELS
# ================================

## Déclenche l'effet visuel d'un sort lancé
func trigger_spell_visual_effect(caster_id: String, target_pos: Vector2, spell_name: String):
	if not current_combat_state or not visual_effects_manager:
		return
	
	# Trouver le combattant qui lance le sort
	var caster = current_combat_state.get_combatant_by_id(caster_id)
	if not caster:
		print("[CombatManager] ⚠️ Lanceur de sort non trouvé: %s" % caster_id)
		return
	
	var caster_pos = Vector2(caster.pos_x, caster.pos_y)
	visual_effects_manager.play_spell_cast_effect(caster_pos, target_pos, spell_name)
	print("[CombatManager] ✨ Effet visuel sort lancé: %s" % spell_name)

## Affiche des dégâts/soins sur une position
func trigger_damage_visual_effect(position: Vector2, value: int, damage_type: String = "damage"):
	if not visual_effects_manager:
		return
	
	visual_effects_manager.show_damage_text(position, value, damage_type)
	print("[CombatManager] 💥 Effet visuel dégâts: %s" % value)

## Affiche un effet temporaire sur un combattant
func trigger_temporary_effect_visual(combatant_id: String, effect: CombatState.TemporaryEffect):
	if not current_combat_state or not visual_effects_manager:
		return
	
	# Trouver le combattant
	var combatant = current_combat_state.get_combatant_by_id(combatant_id)
	if not combatant:
		print("[CombatManager] ⚠️ Combattant non trouvé pour effet: %s" % combatant_id)
		return
	
	var combatant_pos = Vector2(combatant.pos_x, combatant.pos_y)
	visual_effects_manager.show_temporary_effect(combatant_pos, effect)
	print("[CombatManager] 🔮 Effet temporaire affiché: %s" % effect.type)

## Nettoie tous les effets visuels (fin de combat)
func clear_visual_effects():
	if visual_effects_manager:
		visual_effects_manager.clear_all_effects()
		print("[CombatManager] 🧹 Effets visuels nettoyés")

## Détecte les changements entre états et déclenche les effets visuels
func _detect_and_trigger_visual_effects(old_state: CombatState, new_state: CombatState):
	if not old_state or not new_state or not visual_effects_manager:
		return
	
	# Comparer les combattants pour détecter les changements
	for new_combatant in new_state.combatants:
		var old_combatant = null
		if old_state:
			old_combatant = old_state.get_combatant_by_id(new_combatant.character_id)
		
		# Combattant non trouvé dans l'ancien état = nouveau combattant
		if not old_combatant:
			continue
		
		# Détecter changements de santé (dégâts/soins)
		var health_change = new_combatant.current_health - old_combatant.current_health
		if health_change != 0:
			var damage_type = "damage" if health_change < 0 else "heal"
			var position = Vector2(new_combatant.pos_x, new_combatant.pos_y)
			trigger_damage_visual_effect(position, abs(health_change), damage_type)
		
		# Détecter nouveaux effets temporaires
		for new_effect in new_combatant.active_effects:
			var effect_existed = false
			for old_effect in old_combatant.active_effects:
				if old_effect.id == new_effect.id:
					effect_existed = true
					break
			
			# Nouvel effet détecté
			if not effect_existed:
				trigger_temporary_effect_visual(new_combatant.character_id, new_effect)
	
	print("[CombatManager] 🔍 Effets visuels détectés et déclenchés")

# ================================
# MÉTHODES DE TEST LOCAL (DEBUG)
# ================================

## Démarre un combat de test localement (pour debug sans serveur)
func start_test_combat():
	"""Démarre un combat de test localement"""
	print("[CombatManager] 🧪 === DÉMARRAGE COMBAT DE TEST ===")
	
	# Créer des données de combat fictives
	var test_combat_data = {
		"id": "test_combat_" + str(Time.get_unix_time_from_system()),
		"status": "PLACEMENT",
		"grid_width": 17,
		"grid_height": 15,
		"combatants": []
	}
	
	# Démarrer le combat avec ces données
	start_combat_from_server(test_combat_data)
	
	print("[CombatManager] 🧪 Combat de test démarré - Mode debug sans serveur")

# ================================
# MÉTHODES UTILITAIRES
# ================================

## Obtient l'état actuel du combat
func get_current_combat_state() -> CombatState:
	return current_combat_state

## Vérifie si un combat est en cours
func is_in_combat() -> bool:
	return is_combat_active

## Force la mise à jour de l'affichage
func refresh_display():
	_update_all_systems()

## Affiche les informations de debug
func debug_print_state():
	print("[CombatManager] === ÉTAT DU COMBAT ===")
	print("Combat actif: ", is_combat_active)
	print("Combat ID: ", current_combat_id)
	print("Map ID: ", current_map_id)
	
	if current_combat_state:
		print("Phase: ", current_combat_state.status)
		print("Combattants: ", current_combat_state.combatants.size())
		print("Tour actuel: ", current_combat_state.current_turn_index)
	
	print("Actions en attente: ", pending_actions.size())
	print("==============================") 
