extends Node
class_name SpellSystem

## SYSTÈME DE SORTS CÔTÉ CLIENT (Synchronisé avec serveur)
## =======================================================
## Gère les sorts disponibles, leur affichage et leur utilisation
## selon les données reçues du serveur Dofus-like.

# Active ou désactive l'affichage des messages de debug
const DEBUG_LOGS := false

# Fonction de log conditionnel
func debug_log(...):
    if DEBUG_LOGS:
        print(...)

# ================================
# ÉNUMÉRATIONS
# ================================

enum SpellTargetType {
	SELF,        # Soi-même
	ALLY,        # Allié
	ENEMY,       # Ennemi
	EMPTY_CELL,  # Cellule vide
	ANY_CELL     # N'importe quelle cellule
}

enum SpellAreaType {
	SINGLE,      # Cellule unique
	CROSS,       # En croix (+ ou x)
	CIRCLE,      # Cercle autour du point
	LINE         # Ligne dans une direction
}

# ================================
# CLASSE SORT CLIENT
# ================================

class SpellTemplate:
	var id: String
	var name: String
	var description: String
	var icon_path: String
	
	# Coûts et restrictions
	var ap_cost: int = 2
	var min_range: int = 1
	var max_range: int = 3
	var max_uses_per_turn: int = -1  # -1 = illimité
	var max_uses_per_target: int = -1
	var cooldown_turns: int = 0
	
	# Ciblage
	var target_type: SpellTargetType = SpellTargetType.ENEMY
	var area_type: SpellAreaType = SpellAreaType.SINGLE
	var area_size: int = 1
	var needs_line_of_sight: bool = true
	
	# Effets (textuels pour affichage)
	var damage_min: int = 0
	var damage_max: int = 0
	var healing_min: int = 0
	var healing_max: int = 0
	var effects_description: String = ""
	
	func _init(spell_data: Dictionary = {}):
		if spell_data.has("id"):
			id = spell_data.id
		if spell_data.has("name"):
			name = spell_data.name
		if spell_data.has("description"):
			description = spell_data.description
		if spell_data.has("icon_path"):
			icon_path = spell_data.icon_path
			
		# Coûts
		if spell_data.has("ap_cost"):
			ap_cost = spell_data.ap_cost
		if spell_data.has("min_range"):
			min_range = spell_data.min_range
		if spell_data.has("max_range"):
			max_range = spell_data.max_range
		if spell_data.has("max_uses_per_turn"):
			max_uses_per_turn = spell_data.max_uses_per_turn
		if spell_data.has("max_uses_per_target"):
			max_uses_per_target = spell_data.max_uses_per_target
		if spell_data.has("cooldown_turns"):
			cooldown_turns = spell_data.cooldown_turns
			
		# Ciblage
		if spell_data.has("target_type"):
			target_type = _string_to_target_type(spell_data.target_type)
		if spell_data.has("area_type"):
			area_type = _string_to_area_type(spell_data.area_type)
		if spell_data.has("area_size"):
			area_size = spell_data.area_size
		if spell_data.has("needs_line_of_sight"):
			needs_line_of_sight = spell_data.needs_line_of_sight
			
		# Effets
		if spell_data.has("damage_min"):
			damage_min = spell_data.damage_min
		if spell_data.has("damage_max"):
			damage_max = spell_data.damage_max
		if spell_data.has("healing_min"):
			healing_min = spell_data.healing_min
		if spell_data.has("healing_max"):
			healing_max = spell_data.healing_max
		if spell_data.has("effects_description"):
			effects_description = spell_data.effects_description
	
	func _string_to_target_type(type_str: String) -> SpellTargetType:
		match type_str:
			"SELF": return SpellTargetType.SELF
			"ALLY": return SpellTargetType.ALLY
			"ENEMY": return SpellTargetType.ENEMY
			"EMPTY_CELL": return SpellTargetType.EMPTY_CELL
			"ANY_CELL": return SpellTargetType.ANY_CELL
			_: return SpellTargetType.ENEMY
	
	func _string_to_area_type(type_str: String) -> SpellAreaType:
		match type_str:
			"SINGLE": return SpellAreaType.SINGLE
			"CROSS": return SpellAreaType.CROSS
			"CIRCLE": return SpellAreaType.CIRCLE
			"LINE": return SpellAreaType.LINE
			_: return SpellAreaType.SINGLE
	
	## Obtient la description complète du sort pour l'interface
	func get_full_description() -> String:
		var desc = name + "\n"
		desc += "Coût: " + str(ap_cost) + " PA\n"
		desc += "Portée: " + str(min_range) + "-" + str(max_range) + "\n"
		
		if damage_min > 0 or damage_max > 0:
			desc += "Dégâts: " + str(damage_min) + "-" + str(damage_max) + "\n"
		if healing_min > 0 or healing_max > 0:
			desc += "Soins: " + str(healing_min) + "-" + str(healing_max) + "\n"
		
		if effects_description != "":
			desc += effects_description + "\n"
		
		desc += "\n" + description
		return desc

# ================================
# CLASSE PRINCIPALE SYSTÈME SORTS
# ================================

## Sorts disponibles par ID
var available_spells: Dictionary = {}

## Sorts du personnage joueur
var player_spells: Array[String] = []

## Sort actuellement sélectionné
var selected_spell: SpellTemplate = null

## Interface de sorts (référence)
var spell_ui: Control = null

## Référence à la grille de combat
var combat_grid: CombatGrid = null

# ================================
# SIGNAUX
# ================================

## Émis quand un sort est sélectionné
signal spell_selected(spell: SpellTemplate)

## Émis quand la sélection de sort est annulée
signal spell_deselected()

## Émis quand un sort est utilisé
signal spell_cast(spell_id: String, target_pos: Vector2i)

# ================================
# INITIALISATION
# ================================

func _ready():
	debug_log("[SpellSystem] Système de sorts initialisé")
	_load_default_spells()

## Charge les sorts par défaut (sera remplacé par les données serveur)
func _load_default_spells():
	# Sort de base - Attaque
	var basic_attack = SpellTemplate.new({
		"id": "basic_attack",
		"name": "Attaque de base",
		"description": "Une attaque simple au corps à corps",
		"ap_cost": 3,
		"min_range": 1,
		"max_range": 1,
		"target_type": "ENEMY",
		"area_type": "SINGLE",
		"damage_min": 8,
		"damage_max": 12,
		"needs_line_of_sight": true
	})
	available_spells["basic_attack"] = basic_attack
	
	# Sort de guerrier - Coup d'épée
	var sword_strike = SpellTemplate.new({
		"id": "sword_strike",
		"name": "Coup d'épée",
		"description": "Frappe puissante à l'épée",
		"ap_cost": 4,
		"min_range": 1,
		"max_range": 1,
		"target_type": "ENEMY",
		"area_type": "SINGLE",
		"damage_min": 15,
		"damage_max": 20,
		"needs_line_of_sight": true
	})
	available_spells["sword_strike"] = sword_strike
	
	# Sort de soin
	var heal = SpellTemplate.new({
		"id": "heal",
		"name": "Soin",
		"description": "Soigne un allié ou soi-même",
		"ap_cost": 3,
		"min_range": 0,
		"max_range": 3,
		"target_type": "ALLY",
		"area_type": "SINGLE",
		"healing_min": 20,
		"healing_max": 30,
		"needs_line_of_sight": false
	})
	available_spells["heal"] = heal
	
	debug_log("[SpellSystem] ", available_spells.size(), " sorts par défaut chargés")

# ================================
# SYNCHRONISATION SERVEUR
# ================================

## Met à jour les sorts depuis les données serveur
func update_spells_from_server(spells_data: Array):
	debug_log("[SpellSystem] Mise à jour sorts depuis serveur...")
	
	available_spells.clear()
	
	for spell_data in spells_data:
		var spell = SpellTemplate.new(spell_data)
		available_spells[spell.id] = spell
	
	debug_log("[SpellSystem] ", available_spells.size(), " sorts mis à jour")

## Met à jour les sorts du joueur depuis le serveur
func update_player_spells(character_spells: Array):
	debug_log("[SpellSystem] Mise à jour sorts du joueur...")
	
	player_spells.clear()
	
	for spell_id in character_spells:
		if available_spells.has(spell_id):
			player_spells.append(spell_id)
		else:
			debug_log("[SpellSystem] ⚠️ Sort inconnu: ", spell_id)
	
	debug_log("[SpellSystem] ", player_spells.size(), " sorts du joueur disponibles")

# ================================
# SÉLECTION ET UTILISATION
# ================================

## Sélectionne un sort
func select_spell(spell_id: String):
	if not available_spells.has(spell_id):
		debug_log("[SpellSystem] ❌ Sort non trouvé: ", spell_id)
		return
	
	if not spell_id in player_spells:
		debug_log("[SpellSystem] ❌ Sort non disponible pour le joueur: ", spell_id)
		return
	
	selected_spell = available_spells[spell_id]
	
	# Mettre à jour la grille pour afficher la portée
	if combat_grid:
		combat_grid.set_current_action(CombatState.ActionType.CAST_SPELL, spell_id)
	
	spell_selected.emit(selected_spell)
	debug_log("[SpellSystem] ✨ Sort sélectionné: ", selected_spell.name)

## Désélectionne le sort actuel
func deselect_spell():
	if selected_spell:
		selected_spell = null
		
		# Remettre la grille en mode mouvement
		if combat_grid:
			combat_grid.set_current_action(CombatState.ActionType.MOVE)
		
		spell_deselected.emit()
		debug_log("[SpellSystem] 🚫 Sort désélectionné")

## Utilise le sort sélectionné sur une cible
func cast_spell(target_pos: Vector2i) -> bool:
	if not selected_spell:
		debug_log("[SpellSystem] ❌ Aucun sort sélectionné")
		return false
	
	# Valider la portée et la cible
	if not _validate_spell_target(selected_spell, target_pos):
		return false
	
	# Émettre le signal pour que le CombatManager envoie au serveur
	spell_cast.emit(selected_spell.id, target_pos)
	
	debug_log("[SpellSystem] 🎯 Sort lancé: ", selected_spell.name, " vers ", target_pos)
	return true

## Valide une cible pour un sort donné
func _validate_spell_target(spell: SpellTemplate, target_pos: Vector2i) -> bool:
	if not combat_grid:
		return false
	
	# TODO: Obtenir la position du joueur depuis le CombatState
	var player_pos = Vector2i(7, 8)  # Position par défaut
	var distance = _calculate_distance(player_pos, target_pos)
	
	# Vérifier la portée
	if distance < spell.min_range or distance > spell.max_range:
		debug_log("[SpellSystem] ❌ Hors de portée: ", distance, " (", spell.min_range, "-", spell.max_range, ")")
		return false
	
	# Vérifier le type de cible
	var cell_data = combat_grid.get_cell_data(target_pos)
	if cell_data.is_empty():
		return false
	
	var is_occupied = cell_data.get("occupied_by", "") != ""
	
	match spell.target_type:
		SpellTargetType.EMPTY_CELL:
			if is_occupied:
				debug_log("[SpellSystem] ❌ Cellule occupée")
				return false
		SpellTargetType.ENEMY, SpellTargetType.ALLY:
			if not is_occupied:
				debug_log("[SpellSystem] ❌ Aucun combattant à cibler")
				return false
			# TODO: Vérifier si c'est un allié ou ennemi
	
	return true

## Calcule la distance entre deux positions
func _calculate_distance(pos1: Vector2i, pos2: Vector2i) -> int:
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)

# ================================
# INTERFACE ET AFFICHAGE
# ================================

## Définit la référence à l'interface de sorts
func set_spell_ui(ui: Control):
	spell_ui = ui
	_update_spell_ui()

## Définit la référence à la grille de combat
func set_combat_grid(grid: CombatGrid):
	combat_grid = grid

## Met à jour l'interface utilisateur des sorts
func _update_spell_ui():
	if not spell_ui:
		return
	
	# TODO: Mettre à jour les boutons de sorts dans l'interface
	# Sera implémenté quand l'interface sera créée

## Obtient tous les sorts du joueur
func get_player_spells() -> Array[SpellTemplate]:
	var spells: Array[SpellTemplate] = []
	for spell_id in player_spells:
		if available_spells.has(spell_id):
			spells.append(available_spells[spell_id])
	return spells

## Obtient le sort actuellement sélectionné
func get_selected_spell() -> SpellTemplate:
	return selected_spell

## Vérifie si un sort peut être utilisé
func can_cast_spell(spell_id: String, ap_available: int) -> bool:
	if not available_spells.has(spell_id):
		return false
	
	var spell = available_spells[spell_id]
	return ap_available >= spell.ap_cost

# ================================
# MÉTHODES UTILITAIRES
# ================================

## Affiche les informations de debug
func debug_print_spells():
	debug_log("[SpellSystem] === SORTS DISPONIBLES ===")
	for spell_id in available_spells:
		var spell = available_spells[spell_id]
		debug_log("- ", spell.name, " (", spell.id, ") - ", spell.ap_cost, " PA")
	
	debug_log("Sorts du joueur: ", player_spells)
	debug_log("Sort sélectionné: ", selected_spell.name if selected_spell else "Aucun")
	debug_log("=====================================") 