extends Node
class_name CombatTurnManager

## GESTIONNAIRE DE TOURS POUR LE COMBAT TACTIQUE
## ==============================================
## Cette classe gère le système de tours, l'initiative, les actions des combattants,
## et la progression du combat. Elle coordonne les phases de combat et les ressources.
##
## FONCTIONNALITÉS:
## - Système d'initiative avec calcul automatique
## - Gestion des Points d'Action (PA) et Points de Mouvement (PM)
## - Phases de combat (placement, combat, victoire/défaite)
## - Timer de tour avec auto-pass
## - Gestion des équipes et des combattants

# ================================
# ÉNUMÉRATIONS
# ================================

## Phases du combat
enum CombatPhase {
	PLACEMENT,    # Phase de placement initial
	COMBAT,       # Phase de combat active
	VICTORY,      # Victoire d'une équipe
	DEFEAT        # Défaite (abandon/fuite)
}

## Types d'équipes
enum Team {
	ALLY,    # Équipe alliée (joueurs)
	ENEMY    # Équipe ennemie (monstres/PvP)
}

## Types d'actions disponibles
enum ActionType {
	MOVE,      # Déplacement
	ATTACK,    # Attaque de base
	SPELL,     # Sort/compétence
	ITEM,      # Utilisation d'objet
	PASS,      # Passer son tour
	END_TURN   # Finir le tour
}

# ================================
# CLASSE COMBATTANT
# ================================

## Classe représentant un combattant dans le système de combat
class CombatFighter:
	var fighter_id: String          # Identifiant unique
	var fighter_name: String        # Nom du combattant
	var team: Team                  # Équipe (ALLY/ENEMY)
	var grid_position: Vector2i     # Position sur la grille
	var is_alive: bool = true       # Statut vivant/mort
	
	# Stats de base
	var max_health: int = 100
	var current_health: int = 100
	var base_initiative: int = 10
	var base_action_points: int = 6
	var base_movement_points: int = 3
	
	# Stats actuelles du tour
	var current_action_points: int = 0
	var current_movement_points: int = 0
	var initiative_roll: int = 0
	var final_initiative: int = 0
	
	# Référence au nœud dans la scène (Player, Monster, etc.)
	var scene_node: Node2D = null
	
	func _init(id: String, name: String, team_type: Team):
		fighter_id = id
		fighter_name = name
		team = team_type
		current_health = max_health
	
	## Calcule l'initiative pour ce tour
	func calculate_initiative():
		initiative_roll = randi() % 20 + 1  # Dé de 1 à 20
		final_initiative = base_initiative + initiative_roll
	
	## Réinitialise les points pour un nouveau tour
	func reset_turn_resources():
		current_action_points = base_action_points
		current_movement_points = base_movement_points
	
	## Vérifie si le combattant peut effectuer une action
	func can_perform_action(action_type: ActionType) -> bool:
		if not is_alive:
			return false
		
		match action_type:
			ActionType.MOVE:
				return current_movement_points > 0
			ActionType.ATTACK:
				return current_action_points >= 3
			ActionType.SPELL:
				return current_action_points >= 2
			ActionType.ITEM:
				return current_action_points >= 1
			ActionType.PASS, ActionType.END_TURN:
				return true
			_:
				return false
	
	## Consomme les ressources pour une action
	func consume_action_cost(action_type: ActionType) -> bool:
		if not can_perform_action(action_type):
			return false
		
		match action_type:
			ActionType.ATTACK:
				current_action_points -= 3
			ActionType.SPELL:
				current_action_points -= 2
			ActionType.ITEM:
				current_action_points -= 1
			ActionType.MOVE:
				current_movement_points -= 1
			ActionType.PASS, ActionType.END_TURN:
				pass  # Pas de coût
		
		return true
	
	## Applique des dégâts au combattant
	func take_damage(damage: int):
		current_health = max(0, current_health - damage)
		if current_health <= 0:
			is_alive = false
	
	## Soigne le combattant
	func heal(amount: int):
		current_health = min(max_health, current_health + amount)
		if current_health > 0:
			is_alive = true

# ================================
# VARIABLES PRINCIPALES
# ================================

## Phase actuelle du combat
var current_phase: CombatPhase = CombatPhase.PLACEMENT

## Liste de tous les combattants
var all_fighters: Array[CombatFighter] = []

## Ordre des tours (trié par initiative)
var turn_order: Array[CombatFighter] = []

## Index du combattant actuel dans l'ordre des tours
var current_fighter_index: int = 0

## Combattant dont c'est le tour
var current_fighter: CombatFighter = null

## Numéro du tour actuel
var current_turn_number: int = 1

## Timer pour les tours (en secondes)
var turn_timer: float = 30.0
var max_turn_time: float = 30.0
var timer_active: bool = false

# ================================
# SIGNAUX
# ================================

## Émis quand une nouvelle phase commence
signal phase_changed(new_phase: CombatPhase)

## Émis quand c'est le tour d'un nouveau combattant
signal fighter_turn_started(fighter: CombatFighter)

## Émis quand un combattant finit son tour
signal fighter_turn_ended(fighter: CombatFighter)

## Émis quand un nouveau round commence
signal new_round_started(round_number: int)

## Émis quand le timer du tour change
signal turn_timer_updated(remaining_time: float)

## Émis quand le combat se termine
signal combat_ended(winning_team: Team)

## Émis quand un combattant effectue une action
signal action_performed(fighter: CombatFighter, action: ActionType)

# ================================
# INITIALISATION
# ================================

func _ready():
	print("[CombatTurnManager] === INITIALISATION DU GESTIONNAIRE DE TOURS ===")

func _process(delta):
	if timer_active and current_phase == CombatPhase.COMBAT:
		turn_timer -= delta
		turn_timer_updated.emit(turn_timer)
		
		if turn_timer <= 0:
			print("[CombatTurnManager] ⏰ Temps écoulé pour ", current_fighter.fighter_name)
			auto_pass_turn()

# ================================
# GESTION DES COMBATTANTS
# ================================

## Ajoute un combattant au combat
func add_fighter(fighter_id: String, fighter_name: String, team: Team, scene_node: Node2D = null) -> CombatFighter:
	var fighter = CombatFighter.new(fighter_id, fighter_name, team)
	fighter.scene_node = scene_node
	
	all_fighters.append(fighter)
	print("[CombatTurnManager] ➕ Combattant ajouté: ", fighter_name, " (", Team.keys()[team], ")")
	
	return fighter

## Retire un combattant du combat
func remove_fighter(fighter_id: String):
	for i in range(all_fighters.size()):
		if all_fighters[i].fighter_id == fighter_id:
			var fighter = all_fighters[i]
			print("[CombatTurnManager] ➖ Combattant retiré: ", fighter.fighter_name)
			all_fighters.remove_at(i)
			
			# Retirer aussi de l'ordre des tours
			turn_order.erase(fighter)
			break

## Trouve un combattant par son ID
func get_fighter_by_id(fighter_id: String) -> CombatFighter:
	for fighter in all_fighters:
		if fighter.fighter_id == fighter_id:
			return fighter
	return null

## Obtient tous les combattants d'une équipe
func get_fighters_by_team(team: Team) -> Array[CombatFighter]:
	var team_fighters: Array[CombatFighter] = []
	for fighter in all_fighters:
		if fighter.team == team:
			team_fighters.append(fighter)
	return team_fighters

## Obtient tous les combattants vivants
func get_alive_fighters() -> Array[CombatFighter]:
	var alive_fighters: Array[CombatFighter] = []
	for fighter in all_fighters:
		if fighter.is_alive:
			alive_fighters.append(fighter)
	return alive_fighters

## Réinitialise complètement l'état du combat pour un nouveau départ
func reset_combat():
	print("[CombatTurnManager] 🔄 Réinitialisation complète du système de combat.")
	
	current_phase = CombatPhase.PLACEMENT
	all_fighters.clear()
	turn_order.clear()
	current_fighter_index = 0
	current_fighter = null
	current_turn_number = 1
	timer_active = false
	turn_timer = max_turn_time
	
	phase_changed.emit(current_phase)


# ================================
# GESTION DES PHASES
# ================================

## Change la phase du combat
func change_phase(new_phase: CombatPhase):
	if current_phase == new_phase:
		return
	
	print("[CombatTurnManager] 🔄 Changement de phase: ", CombatPhase.keys()[current_phase], " → ", CombatPhase.keys()[new_phase])
	current_phase = new_phase
	phase_changed.emit(new_phase)
	
	match new_phase:
		CombatPhase.PLACEMENT:
			_handle_placement_phase()
		CombatPhase.COMBAT:
			_handle_combat_phase()
		CombatPhase.VICTORY, CombatPhase.DEFEAT:
			_handle_end_phase()

## Gère la phase de placement
func _handle_placement_phase():
	print("[CombatTurnManager] 📍 Phase de placement activée")
	timer_active = false

## Gère la phase de combat
func _handle_combat_phase():
	print("[CombatTurnManager] ⚔️ Phase de combat activée")
	_calculate_initiative_order()
	_start_first_turn()

## Gère la fin du combat
func _handle_end_phase():
	print("[CombatTurnManager] 🏁 Combat terminé")
	timer_active = false

# ================================
# SYSTÈME D'INITIATIVE
# ================================

## Calcule l'ordre d'initiative pour tous les combattants
func _calculate_initiative_order():
	print("[CombatTurnManager] 🎲 Calcul de l'initiative...")
	
	# Calculer l'initiative pour chaque combattant vivant
	var alive_fighters = get_alive_fighters()
	for fighter in alive_fighters:
		fighter.calculate_initiative()
		print("  - ", fighter.fighter_name, ": ", fighter.base_initiative, " + ", fighter.initiative_roll, " = ", fighter.final_initiative)
	
	# Trier par initiative décroissante
	turn_order = alive_fighters.duplicate()
	turn_order.sort_custom(func(a, b): 
		# En cas d'égalité, les joueurs (ALLY) passent en premier
		if a.final_initiative == b.final_initiative:
			return a.team == Team.ALLY and b.team == Team.ENEMY
		return a.final_initiative > b.final_initiative
	)
	
	print("[CombatTurnManager] ✅ Ordre d'initiative établi:")
	for i in range(turn_order.size()):
		var fighter = turn_order[i]
		print("  ", i + 1, ". ", fighter.fighter_name, " (", fighter.final_initiative, ")")

# ================================
# GESTION DES TOURS
# ================================

## Démarre le premier tour
func _start_first_turn():
	current_fighter_index = 0
	current_turn_number = 1
	new_round_started.emit(current_turn_number)
	_start_fighter_turn()

## Démarre le tour d'un combattant
func _start_fighter_turn():
	if turn_order.is_empty():
		print("[CombatTurnManager] ❌ Aucun combattant dans l'ordre des tours")
		return
	
	current_fighter = turn_order[current_fighter_index]
	
	# Vérifier si le combattant est encore vivant
	if not current_fighter.is_alive:
		print("[CombatTurnManager] ⚰️ Combattant mort, passage au suivant")
		next_turn()
		return
	
	# Réinitialiser les ressources du tour
	current_fighter.reset_turn_resources()
	
	# Démarrer le timer
	turn_timer = max_turn_time
	timer_active = true
	
	print("[CombatTurnManager] 🎯 Tour de: ", current_fighter.fighter_name)
	print("  - PA: ", current_fighter.current_action_points)
	print("  - PM: ", current_fighter.current_movement_points)
	
	fighter_turn_started.emit(current_fighter)

## Passe au tour suivant
func next_turn():
	if current_fighter:
		print("[CombatTurnManager] ✅ Fin du tour de: ", current_fighter.fighter_name)
		fighter_turn_ended.emit(current_fighter)
	
	timer_active = false
	current_fighter_index += 1
	
	# Vérifier si on a fini le round
	if current_fighter_index >= turn_order.size():
		current_fighter_index = 0
		current_turn_number += 1
		print("[CombatTurnManager] 🔄 Nouveau round: ", current_turn_number)
		new_round_started.emit(current_turn_number)
		
		# Vérifier les conditions de victoire
		if _check_victory_conditions():
			return
	
	_start_fighter_turn()

## Passe automatiquement le tour (timer expiré)
func auto_pass_turn():
	print("[CombatTurnManager] ⏭️ Tour passé automatiquement")
	perform_action(ActionType.PASS)

## Force la fin du tour actuel
func end_current_turn():
	if current_fighter and current_fighter.can_perform_action(ActionType.END_TURN):
		perform_action(ActionType.END_TURN)

# ================================
# SYSTÈME D'ACTIONS
# ================================

## Exécute une action pour le combattant actuel
func perform_action(action_type: ActionType) -> bool:
	if not current_fighter:
		print("[CombatTurnManager] ❌ Aucun combattant actuel")
		return false
	
	if not current_fighter.can_perform_action(action_type):
		print("[CombatTurnManager] ❌ Action impossible: ", ActionType.keys()[action_type])
		return false
	
	# Consommer les ressources
	current_fighter.consume_action_cost(action_type)
	
	print("[CombatTurnManager] ⚡ Action: ", ActionType.keys()[action_type], " par ", current_fighter.fighter_name)
	print("  - PA restants: ", current_fighter.current_action_points)
	print("  - PM restants: ", current_fighter.current_movement_points)
	
	action_performed.emit(current_fighter, action_type)
	
	# Vérifier si le tour doit se terminer
	if action_type == ActionType.END_TURN or action_type == ActionType.PASS:
		next_turn()
	elif not _fighter_can_act():
		print("[CombatTurnManager] 🚫 Plus d'actions possibles, fin de tour automatique")
		next_turn()
	
	return true

## Vérifie si le combattant actuel peut encore agir
func _fighter_can_act() -> bool:
	if not current_fighter:
		return false
	
	# Vérifier chaque type d'action
	for action_type in ActionType.values():
		if action_type != ActionType.END_TURN and current_fighter.can_perform_action(action_type):
			return true
	
	return false

# ================================
# CONDITIONS DE VICTOIRE
# ================================

## Vérifie les conditions de victoire/défaite
func _check_victory_conditions() -> bool:
	var ally_fighters = get_fighters_by_team(Team.ALLY)
	var enemy_fighters = get_fighters_by_team(Team.ENEMY)
	
	var alive_allies = 0
	var alive_enemies = 0
	
	for fighter in ally_fighters:
		if fighter.is_alive:
			alive_allies += 1
	
	for fighter in enemy_fighters:
		if fighter.is_alive:
			alive_enemies += 1
	
	# Vérifier les conditions
	if alive_allies == 0:
		print("[CombatTurnManager] 💀 Défaite: Tous les alliés sont morts")
		change_phase(CombatPhase.DEFEAT)
		combat_ended.emit(Team.ENEMY)
		return true
	elif alive_enemies == 0:
		print("[CombatTurnManager] 🏆 Victoire: Tous les ennemis sont morts")
		change_phase(CombatPhase.VICTORY)
		combat_ended.emit(Team.ALLY)
		return true
	
	return false

# ================================
# UTILITAIRES PUBLICS
# ================================

## Démarre le combat (passe en phase de combat)
func start_combat():
	change_phase(CombatPhase.COMBAT)

## Termine le combat prématurément
func end_combat(winning_team: Team):
	if winning_team == Team.ALLY:
		change_phase(CombatPhase.VICTORY)
	else:
		change_phase(CombatPhase.DEFEAT)
	combat_ended.emit(winning_team)

## Remet à zéro le gestionnaire pour un nouveau combat
func reset_for_new_combat():
	print("[CombatTurnManager] 🔄 Réinitialisation pour nouveau combat")
	
	all_fighters.clear()
	turn_order.clear()
	current_fighter = null
	current_fighter_index = 0
	current_turn_number = 1
	timer_active = false
	change_phase(CombatPhase.PLACEMENT)

## Obtient des statistiques du combat actuel
func get_combat_stats() -> Dictionary:
	return {
		"phase": CombatPhase.keys()[current_phase],
		"turn_number": current_turn_number,
		"current_fighter": current_fighter.fighter_name if current_fighter else "Aucun",
		"remaining_time": turn_timer,
		"total_fighters": all_fighters.size(),
		"alive_fighters": get_alive_fighters().size(),
		"ally_count": get_fighters_by_team(Team.ALLY).size(),
		"enemy_count": get_fighters_by_team(Team.ENEMY).size()
	}

# ================================
# DEBUG ET DIAGNOSTICS
# ================================

## Affiche l'état actuel du combat
func debug_print_combat_state():
	print("[CombatTurnManager] === ÉTAT DU COMBAT ===")
	print("Phase: ", CombatPhase.keys()[current_phase])
	print("Tour: ", current_turn_number)
	print("Combattant actuel: ", current_fighter.fighter_name if current_fighter else "Aucun")
	print("Timer: ", "%.1f" % turn_timer, "s")
	print("Combattants vivants: ", get_alive_fighters().size(), "/", all_fighters.size())
	
	if current_fighter:
		print("Ressources actuelles:")
		print("  - PA: ", current_fighter.current_action_points, "/", current_fighter.base_action_points)
		print("  - PM: ", current_fighter.current_movement_points, "/", current_fighter.base_movement_points)
		print("  - Santé: ", current_fighter.current_health, "/", current_fighter.max_health)
	
	print("=====================================")

## Affiche l'ordre des tours
func debug_print_turn_order():
	print("[CombatTurnManager] === ORDRE DES TOURS ===")
	for i in range(turn_order.size()):
		var fighter = turn_order[i]
		var status = "💀" if not fighter.is_alive else ("👑" if fighter == current_fighter else "⏳")
		print("  ", i + 1, ". ", status, " ", fighter.fighter_name, " (Initiative: ", fighter.final_initiative, ")")
	print("========================================") 