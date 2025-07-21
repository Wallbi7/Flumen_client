extends Resource
class_name CombatState

## ÉTAT DE COMBAT CÔTÉ CLIENT (Synchronisé avec serveur)
## ====================================================
## Cette classe représente l'état complet d'un combat, 
## synchronisé avec le modèle serveur Dofus-like.

# ================================
# ÉNUMÉRATIONS (Synchronisées avec serveur)
# ================================

enum CombatStatus {
	STARTING,
	PLACEMENT,
	IN_PROGRESS, 
	FINISHED
}

enum ActionType {
	MOVE,
	CAST_SPELL,
	PASS_TURN,
	USE_ITEM,
	SURRENDER,
	READY_FOR_COMBAT
}

enum EffectType {
	POISON,
	BOOST_PA,
	BOOST_PM,
	BOOST_DAMAGE,
	REDUCE_PA,
	REDUCE_PM
}

# ================================
# CLASSE EFFET TEMPORAIRE
# ================================

class TemporaryEffect:
	var id: String
	var type: EffectType
	var value: int              # Ex: +2 PA, -50 HP/tour
	var duration: int           # Tours restants
	var caster_id: String       # Qui a lancé cet effet
	var description: String     # "Poison (3 tours restants)"
	
	func _init(effect_data: Dictionary = {}):
		if effect_data.has("id"):
			id = effect_data.id
		if effect_data.has("type"):
			type = _string_to_effect_type(effect_data.type)
		if effect_data.has("value"):
			value = effect_data.value
		if effect_data.has("duration"):
			duration = effect_data.duration
		if effect_data.has("caster_id"):
			caster_id = effect_data.caster_id
		if effect_data.has("description"):
			description = effect_data.description
	
	func _string_to_effect_type(type_str: String) -> EffectType:
		match type_str:
			"POISON": return EffectType.POISON
			"BOOST_PA": return EffectType.BOOST_PA
			"BOOST_PM": return EffectType.BOOST_PM
			"BOOST_DAMAGE": return EffectType.BOOST_DAMAGE
			"REDUCE_PA": return EffectType.REDUCE_PA
			"REDUCE_PM": return EffectType.REDUCE_PM
			_: return EffectType.POISON

# ================================
# CLASSE COMBATTANT
# ================================

class Combatant:
	var character_id: String
	var name: String
	var level: int
	var is_player: bool
	var team_id: int              # 0 = alliés, 1 = ennemis
	
	# === STATS SYSTÈME DOFUS ===
	
	# Stats de base (personnage + équipement + buffs)
	var base_health: int          # HP max total
	var base_action_points: int   # PA max par tour (6 de base)
	var base_movement_points: int # PM max par tour (3 de base)
	var base_initiative: int      # Pour calcul ordre de tour
	
	# Stats du tour actuel (reset chaque tour)
	var current_health: int             # HP restants
	var remaining_action_points: int    # PA restants ce tour
	var remaining_movement_points: int  # PM restants ce tour
	
	# Position sur la grille de combat
	var pos_x: int
	var pos_y: int
	
	# État de combat
	var initiative: int           # Initiative calculée pour ce combat
	var is_dead: bool            # Mort = retiré du combat
	var has_played: bool         # Pour l'ordre de tour
	
	# Effets actifs sur ce combattant
	var active_effects: Array[TemporaryEffect] = []
	
	func _init(combatant_data: Dictionary = {}):
		if combatant_data.has("character_id"):
			character_id = combatant_data.character_id
		if combatant_data.has("name"):
			name = combatant_data.name
		if combatant_data.has("level"):
			level = combatant_data.level
		if combatant_data.has("is_player"):
			is_player = combatant_data.is_player
		if combatant_data.has("team_id"):
			team_id = combatant_data.team_id
			
		# Stats de base
		if combatant_data.has("base_health"):
			base_health = combatant_data.base_health
		if combatant_data.has("base_action_points"):
			base_action_points = combatant_data.base_action_points
		if combatant_data.has("base_movement_points"):
			base_movement_points = combatant_data.base_movement_points
		if combatant_data.has("base_initiative"):
			base_initiative = combatant_data.base_initiative
			
		# Stats actuelles
		if combatant_data.has("current_health"):
			current_health = combatant_data.current_health
		if combatant_data.has("remaining_action_points"):
			remaining_action_points = combatant_data.remaining_action_points
		if combatant_data.has("remaining_movement_points"):
			remaining_movement_points = combatant_data.remaining_movement_points
			
		# Position
		if combatant_data.has("pos_x"):
			pos_x = combatant_data.pos_x
		if combatant_data.has("pos_y"):
			pos_y = combatant_data.pos_y
			
		# État
		if combatant_data.has("initiative"):
			initiative = combatant_data.initiative
		if combatant_data.has("is_dead"):
			is_dead = combatant_data.is_dead
		if combatant_data.has("has_played"):
			has_played = combatant_data.has_played
			
		# Effets actifs
		if combatant_data.has("active_effects"):
			active_effects = []
			for effect_data in combatant_data.active_effects:
				active_effects.append(TemporaryEffect.new(effect_data))
	
	## Obtient la position sur la grille comme Vector2i
	func get_grid_position() -> Vector2i:
		return Vector2i(pos_x, pos_y)
	
	## Définit la position sur la grille depuis un Vector2i
	func set_grid_position(pos: Vector2i):
		pos_x = pos.x
		pos_y = pos.y
	
	## Vérifie si le combattant peut bouger
	func can_move() -> bool:
		return not is_dead and remaining_movement_points > 0
	
	## Vérifie si le combattant peut lancer un sort
	func can_cast_spell(ap_cost: int) -> bool:
		return not is_dead and remaining_action_points >= ap_cost
	
	## Consomme des PA
	func consume_action_points(amount: int):
		remaining_action_points = max(0, remaining_action_points - amount)
	
	## Consomme des PM
	func consume_movement_points(amount: int):
		remaining_movement_points = max(0, remaining_movement_points - amount)

# ================================
# CLASSE PRINCIPALE COMBAT STATE
# ================================

## Identifiant unique du combat
var id: String

## Statut actuel du combat
var status: CombatStatus

## === PARTICIPANTS ===
var combatants: Array = []  # Array[Combatant] - Compatible Resource
var ally_team: Array = []     # Team 0 - IDs des personnages (Array[String])
var enemy_team: Array = []    # Team 1 - IDs des personnages (Array[String])

## === GESTION DES TOURS ===
var turn_order: Array = []    # Ordre calculé par initiative (Array[String])
var current_turn_index: int = 0       # Index dans turn_order
var turn_start_time: float            # Timestamp début du tour actuel
var turn_time_limit: float = 30.0     # Limite de temps par tour (30s comme Dofus)

## === GRILLE DE COMBAT ===
var grid_width: int = 15
var grid_height: int = 17
var ally_placement_cells: Array[Vector2i] = []
var enemy_placement_cells: Array[Vector2i] = []

## === MÉTADONNÉES ===
var created_at: String
var updated_at: String

# ================================
# MÉTHODES PRINCIPALES
# ================================

func _init():
	status = CombatStatus.STARTING

## Crée un CombatState depuis les données JSON du serveur
static func from_server_data(data: Dictionary) -> CombatState:
	var combat_state = CombatState.new()
	
	if data.has("id"):
		combat_state.id = data.id
	if data.has("status"):
		combat_state.status = _string_to_combat_status(data.status)
	
	# Charger les combattants
	if data.has("combatants"):
		var temp_combatants: Array = []
		for combatant_data in data.combatants:
			temp_combatants.append(Combatant.new(combatant_data))
		combat_state.combatants = temp_combatants
	
	# Charger les équipes
	if data.has("ally_team"):
		combat_state.ally_team = data.ally_team.duplicate()
	if data.has("enemy_team"):
		combat_state.enemy_team = data.enemy_team.duplicate()
	
	# Gestion des tours
	if data.has("turn_order"):
		combat_state.turn_order = data.turn_order.duplicate()
	if data.has("current_turn_index"):
		combat_state.current_turn_index = data.current_turn_index
	if data.has("turn_start_time"):
		combat_state.turn_start_time = data.turn_start_time
	if data.has("turn_time_limit"):
		combat_state.turn_time_limit = data.turn_time_limit
	
	# Grille
	if data.has("grid_width"):
		combat_state.grid_width = data.grid_width
	if data.has("grid_height"):
		combat_state.grid_height = data.grid_height
	if data.has("ally_placement_cells"):
		combat_state.ally_placement_cells = []
		for cell_data in data.ally_placement_cells:
			combat_state.ally_placement_cells.append(Vector2i(cell_data.x, cell_data.y))
	if data.has("enemy_placement_cells"):
		combat_state.enemy_placement_cells = []
		for cell_data in data.enemy_placement_cells:
			combat_state.enemy_placement_cells.append(Vector2i(cell_data.x, cell_data.y))
	
	# Métadonnées
	if data.has("created_at"):
		combat_state.created_at = data.created_at
	if data.has("updated_at"):
		combat_state.updated_at = data.updated_at
	
	return combat_state

## Convertit une chaîne en CombatStatus
static func _string_to_combat_status(status_str: String) -> CombatStatus:
	match status_str:
		"STARTING": return CombatStatus.STARTING
		"PLACEMENT": return CombatStatus.PLACEMENT
		"IN_PROGRESS": return CombatStatus.IN_PROGRESS
		"FINISHED": return CombatStatus.FINISHED
		_: return CombatStatus.STARTING

## Obtient le combattant actuel
func get_current_combatant() -> Combatant:
	if turn_order.is_empty() or current_turn_index >= turn_order.size():
		return null
	
	var current_character_id = turn_order[current_turn_index]
	return get_combatant_by_id(current_character_id)

## Trouve un combattant par son ID
func get_combatant_by_id(character_id: String) -> Combatant:
	for combatant in combatants:
		if combatant.character_id == character_id:
			return combatant
	return null

## Obtient tous les combattants d'une équipe
func get_team_combatants(team_id: int) -> Array[Combatant]:
	var team_combatants: Array[Combatant] = []
	for combatant in combatants:
		if combatant.team_id == team_id:
			team_combatants.append(combatant)
	return team_combatants

## Calcule le temps restant pour le tour actuel
func get_remaining_turn_time() -> float:
	var elapsed = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second - turn_start_time
	return max(0.0, turn_time_limit - elapsed)

## Vérifie si le combat est terminé
func is_combat_finished() -> bool:
	return status == CombatStatus.FINISHED 
