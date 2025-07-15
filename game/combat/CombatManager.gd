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

## Référence au NetworkManager pour communication serveur
var network_manager: Node = null

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
	print("[CombatManager] === GESTIONNAIRE COMBAT DOFUS-LIKE INITIALISÉ ===")
	
	# Obtenir les références nécessaires
	game_manager = get_node_or_null("/root/GameManager")
	network_manager = get_node_or_null("/root/NetworkManager")
	
	# Initialiser le système d'effets visuels
	_initialize_visual_effects()
	
	if game_manager:
		print("[CombatManager] ✅ GameManager trouvé")
	else:
		print("[CombatManager] ⚠️ GameManager non trouvé")
	
	if network_manager:
		print("[CombatManager] ✅ NetworkManager trouvé")
		# Connecter aux signaux réseau pour recevoir les mises à jour de combat
		_connect_network_signals()
	else:
		print("[CombatManager] ⚠️ NetworkManager non trouvé")

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
	# TODO: Connecter aux signaux WebSocket du NetworkManager
	# network_manager.combat_state_received.connect(_on_combat_state_received)
	# network_manager.combat_action_response.connect(_on_combat_action_response)
	pass

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
		
		combat_grid = preload("res://game/combat/CombatGrid.gd").new()
		
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
	
	# Mettre à jour tous les systèmes avec le nouvel état
	_update_all_systems()
	
	# Afficher l'interface de combat
	_show_combat_interface()
	
	combat_started.emit(current_combat_state)
	print("[CombatManager] ✅ Combat démarré - ID: ", current_combat_id)

## Met à jour l'état de combat depuis le serveur
func update_combat_state(new_combat_data: Dictionary):
	if not is_combat_active:
		print("[CombatManager] ⚠️ Mise à jour reçue mais aucun combat actif")
		return
	
	print("[CombatManager] 🔄 Mise à jour état de combat...")
	
	# Sauvegarder l'ancien état pour comparaison
	var old_combat_state = current_combat_state
	
	# Mettre à jour l'état
	current_combat_state = CombatState.from_server_data(new_combat_data)
	
	# Détecter et déclencher les effets visuels basés sur les changements
	_detect_and_trigger_visual_effects(old_combat_state, current_combat_state)
	
	# Mettre à jour tous les systèmes
	_update_all_systems()
	
	# Vérifier si le combat est terminé
	if current_combat_state.is_combat_finished():
		_end_combat()
	
	combat_state_updated.emit(current_combat_state)

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
	var result = {
		"combat_id": current_combat_id,
		"status": current_combat_state.status if current_combat_state != null else "UNKNOWN"
	}
	
	# Fusionner les données de résultat personnalisées
	for key in result_data:
		result[key] = result_data[key]
	
	# Masquer l'interface
	if combat_ui:
		combat_ui.hide_combat_ui()
	
	if combat_grid:
		combat_grid.hide_grid()
	
	# Nettoyer les effets visuels
	clear_visual_effects()
	
	# Nettoyer l'état
	current_combat_state = null
	current_combat_id = ""
	pending_actions.clear()
	
	combat_ended.emit(result)

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
	if network_manager and network_manager.has_method("send_combat_action"):
		network_manager.send_combat_action(action_data)
	else:
		print("[CombatManager] ⚠️ NetworkManager non disponible - Action mise en attente")
	
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
