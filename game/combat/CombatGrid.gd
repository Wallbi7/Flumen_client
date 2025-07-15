extends Node2D
class_name CombatGrid

## GRILLE DE COMBAT TACTIQUE DOFUS-LIKE (Synchronisée avec serveur)
## =================================================================
## Grille isométrique adaptée pour le nouveau système de combat serveur.
## Gère les zones de placement, validation PA/PM, et interaction tactique.

# ================================
# CONSTANTES DE GRILLE (Compatibles Dofus)
# ================================
const CELL_WIDTH: int = 86
const CELL_HEIGHT: int = 43

# ================================
# VARIABLES DE GRILLE
# ================================

## Dimensions de la grille (synchronisées avec serveur)
var grid_width: int = 15
var grid_height: int = 17

## État de combat synchronisé avec serveur
var current_combat_state: CombatState = null

## Combattant du joueur local
var local_player_combatant: CombatState.Combatant = null

# ================================
# ÉNUMÉRATIONS
# ================================

## Types de cellules disponibles
enum CellType {
	WALKABLE,    # Cellule normale, marchable
	BLOCKED,     # Cellule bloquée (obstacle)
	WATER,       # Cellule d'eau (règles spéciales)
	ELEVATION    # Cellule avec élévation (bonus/malus)
}

## États visuels des cellules (étendus pour Dofus-like)
enum CellState {
	NORMAL,           # État par défaut
	HIGHLIGHTED,      # Cellule surligné (hover)
	MOVEMENT_RANGE,   # Dans la portée de mouvement (PM)
	SPELL_RANGE,      # Dans la portée de sort (selon sort sélectionné)
	PLACEMENT_ALLY,   # Zone de placement alliée
	PLACEMENT_ENEMY,  # Zone de placement ennemie
	PATH_PREVIEW,     # Prévisualisation du chemin
	OCCUPIED_ALLY,    # Cellule occupée par un allié
	OCCUPIED_ENEMY,   # Cellule occupée par un ennemi
	INVALID_TARGET    # Cible invalide pour l'action courante
}

# ================================
# VARIABLES DE GRILLE
# ================================

## Structure de données de la grille - chaque cellule contient:
## - type: CellType (WALKABLE, BLOCKED, etc.)
## - state: CellState (NORMAL, HIGHLIGHTED, etc.)
## - occupied_by: String (ID du combattant qui occupe la cellule, "" si vide)
## - position: Vector2i (coordonnées de grille)
var grid_data: Array[Dictionary] = []

## Nœud parent pour tous les éléments visuels de la grille
var grid_visual_parent: Node2D

## Action courante sélectionnée par le joueur
var current_action: CombatState.ActionType = CombatState.ActionType.MOVE
var selected_spell_id: String = ""

# ================================
# SIGNAUX
# ================================

## Émis quand une cellule est cliquée (avec validation PA/PM)
signal cell_clicked(grid_pos: Vector2i, action_type: CombatState.ActionType, action_data: Dictionary)



## Émis quand l'action demandée n'est pas valide
signal invalid_action(reason: String)

# ================================
# INITIALISATION
# ================================

func _ready():
	print("[CombatGrid] === GRILLE COMBAT DOFUS-LIKE INITIALISÉE ===")
	
	# Créer le conteneur visuel
	grid_visual_parent = Node2D.new()
	grid_visual_parent.name = "GridVisuals"
	add_child(grid_visual_parent)
	
	# Positionner la grille au centre de l'écran
	_center_grid_on_screen()
	
	# Masquer la grille par défaut
	visible = false
	
	# Initialiser la grille par défaut
	initialize_grid(grid_width, grid_height)

## Centre la grille sur l'écran
func _center_grid_on_screen():
	var screen_size = get_viewport().get_visible_rect().size
	var grid_screen_width = grid_width * CELL_WIDTH
	var grid_screen_height = grid_height * CELL_HEIGHT
	
	position = Vector2(
		(screen_size.x - grid_screen_width) / 2.0,
		(screen_size.y - grid_screen_height) / 2.0
	)

# ================================
# SYNCHRONISATION AVEC SERVEUR
# ================================

## Met à jour la grille avec un nouvel état de combat du serveur
func update_from_combat_state(combat_state: CombatState):
	current_combat_state = combat_state
	local_player_combatant = _find_local_player_combatant()
	
	print("[CombatGrid] 🔄 Mise à jour grille depuis état serveur")
	
	# Mettre à jour les dimensions si nécessaire
	if combat_state.grid_width != grid_width or combat_state.grid_height != grid_height:
		grid_width = combat_state.grid_width
		grid_height = combat_state.grid_height
		initialize_grid(grid_width, grid_height)
	
	# Mettre à jour les positions des combattants
	_update_combatant_positions()
	
	# Mettre à jour les zones de placement selon la phase
	_update_placement_zones()
	
	# Mettre à jour les portées d'action selon le combattant actuel
	_update_action_ranges()

## Trouve le combattant correspondant au joueur local
func _find_local_player_combatant() -> CombatState.Combatant:
	if not current_combat_state:
		return null
	
	for combatant in current_combat_state.combatants:
		if combatant.is_player and combatant.team_id == 0:  # Équipe alliée
			return combatant
	return null

## Met à jour les positions des combattants sur la grille
func _update_combatant_positions():
	# Nettoyer toutes les occupations existantes
	for y in range(grid_height):
		for x in range(grid_width):
			var grid_pos = Vector2i(x, y)
			var cell_data = get_cell_data(grid_pos)
			if not cell_data.is_empty():
				cell_data["occupied_by"] = ""
				# Ne pas changer l'état si c'est une zone de placement
				if cell_data["state"] == CellState.OCCUPIED_ALLY or cell_data["state"] == CellState.OCCUPIED_ENEMY:
					cell_data["state"] = CellState.NORMAL
	
	# Placer tous les combattants selon leurs positions serveur
	if current_combat_state:
		for combatant in current_combat_state.combatants:
			var grid_pos = Vector2i(combatant.pos_x, combatant.pos_y)
			if is_valid_grid_position(grid_pos):
				set_cell_occupied(grid_pos, combatant.character_id)
				var state = CellState.OCCUPIED_ALLY if combatant.team_id == 0 else CellState.OCCUPIED_ENEMY
				set_cell_state(grid_pos, state)
	
	# Regénérer la grille visuelle
	_generate_visual_grid()

## Met à jour les zones de placement selon la phase de combat
func _update_placement_zones():
	if not current_combat_state:
		return
	
	# Afficher les zones de placement uniquement en phase PLACEMENT
	if current_combat_state.status == CombatState.CombatStatus.PLACEMENT:
		# Zones alliées
		for cell_pos in current_combat_state.ally_placement_cells:
			if is_valid_grid_position(cell_pos):
				set_cell_state(cell_pos, CellState.PLACEMENT_ALLY)
		
		# Zones ennemies
		for cell_pos in current_combat_state.enemy_placement_cells:
			if is_valid_grid_position(cell_pos):
				set_cell_state(cell_pos, CellState.PLACEMENT_ENEMY)

## Met à jour les portées d'action selon le combattant actuel et l'action sélectionnée
func _update_action_ranges():
	if not current_combat_state or not local_player_combatant:
		return
	
	var current_combatant = current_combat_state.get_current_combatant()
	if not current_combatant or current_combatant.character_id != local_player_combatant.character_id:
		# Ce n'est pas le tour du joueur, nettoyer les portées
		_clear_action_ranges()
		return
	
	# Afficher les portées selon l'action courante
	match current_action:
		CombatState.ActionType.MOVE:
			_show_movement_range()
		CombatState.ActionType.CAST_SPELL:
			_show_spell_range()

## Affiche la portée de mouvement (PM)
func _show_movement_range():
	if not local_player_combatant:
		return
	
	var player_pos = Vector2i(local_player_combatant.pos_x, local_player_combatant.pos_y)
	var movement_points = local_player_combatant.remaining_movement_points
	
	# Calculer toutes les cellules accessibles avec les PM restants
	var reachable_cells = _get_reachable_cells(player_pos, movement_points)
	
	for cell_pos in reachable_cells:
		if get_cell_data(cell_pos)["state"] == CellState.NORMAL:
			set_cell_state(cell_pos, CellState.MOVEMENT_RANGE)

## Affiche la portée de sort selon le sort sélectionné
func _show_spell_range():
	if not local_player_combatant or selected_spell_id.is_empty():
		return
	
	# TODO: Récupérer les données du sort depuis le serveur
	# Pour l'instant, utiliser une portée par défaut
	var spell_range = 3
	var player_pos = Vector2i(local_player_combatant.pos_x, local_player_combatant.pos_y)
	
	# Calculer les cellules dans la portée du sort
	var spell_cells = _get_cells_in_range(player_pos, spell_range)
	
	for cell_pos in spell_cells:
		if get_cell_data(cell_pos)["state"] == CellState.NORMAL:
			set_cell_state(cell_pos, CellState.SPELL_RANGE)

## Nettoie toutes les portées d'action affichées
func _clear_action_ranges():
	for y in range(grid_height):
		for x in range(grid_width):
			var grid_pos = Vector2i(x, y)
			var cell_data = get_cell_data(grid_pos)
			if not cell_data.is_empty():
				if cell_data["state"] in [CellState.MOVEMENT_RANGE, CellState.SPELL_RANGE, CellState.PATH_PREVIEW]:
					cell_data["state"] = CellState.NORMAL
	
	_generate_visual_grid()

# ================================
# CALCULS DE PORTÉE ET PATHFINDING
# ================================

## Calcule toutes les cellules accessibles avec un nombre de PM donné
func _get_reachable_cells(start_pos: Vector2i, movement_points: int) -> Array[Vector2i]:
	var reachable: Array[Vector2i] = []
	var visited: Dictionary = {}
	var queue: Array[Dictionary] = [{"pos": start_pos, "cost": 0}]
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var pos = current["pos"]
		var cost = current["cost"]
		
		if visited.has(str(pos)) or cost > movement_points:
			continue
		
		visited[str(pos)] = true
		if pos != start_pos:  # Ne pas inclure la position de départ
			reachable.append(pos)
		
		# Explorer les cellules adjacentes
		var neighbors = _get_adjacent_cells(pos)
		for neighbor in neighbors:
			if is_cell_walkable(neighbor) and not visited.has(str(neighbor)):
				queue.append({"pos": neighbor, "cost": cost + 1})
	
	return reachable

## Calcule toutes les cellules dans une portée donnée (pour les sorts)
func _get_cells_in_range(center_pos: Vector2i, range_distance: int) -> Array[Vector2i]:
	var cells_in_range: Array[Vector2i] = []
	
	for y in range(grid_height):
		for x in range(grid_width):
			var grid_pos = Vector2i(x, y)
			var distance = _calculate_grid_distance(center_pos, grid_pos)
			if distance <= range_distance and distance > 0:  # Exclure la cellule centrale
				cells_in_range.append(grid_pos)
	
	return cells_in_range

## Calcule la distance en grille entre deux positions
func _calculate_grid_distance(pos1: Vector2i, pos2: Vector2i) -> int:
	# Distance de Manhattan pour grille isométrique
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)

## Obtient les cellules adjacentes à une position
func _get_adjacent_cells(pos: Vector2i) -> Array[Vector2i]:
	var adjacent: Array[Vector2i] = []
	var directions = [
		Vector2i(0, -1),  # Haut
		Vector2i(1, 0),   # Droite
		Vector2i(0, 1),   # Bas
		Vector2i(-1, 0)   # Gauche
	]
	
	for direction in directions:
		var neighbor = pos + direction
		if is_valid_grid_position(neighbor):
			adjacent.append(neighbor)
	
	return adjacent 

# ================================
# GESTION DES CELLULES ET INITIALISATION
# ================================

## Initialise ou réinitialise la grille avec une taille donnée
func initialize_grid(new_width: int, new_height: int):
	print("[CombatGrid] Initialisation grille: %dx%d" % [new_width, new_height])
	
	grid_width = new_width
	grid_height = new_height
	
	grid_data.clear()
	
	# Créer chaque cellule de la grille
	for y in range(grid_height):
		for x in range(grid_width):
			var cell_data = {
				"type": CellType.WALKABLE,
				"state": CellState.NORMAL,
				"occupied_by": "",
				"position": Vector2i(x, y)
			}
			grid_data.append(cell_data)
	
	# (Re)Générer les visuels
	_generate_visual_grid()
	print("[CombatGrid] ✅ Grille créée avec %d cellules" % [grid_width * grid_height])

## Obtient les données d'une cellule à partir de coordonnées de grille
func get_cell_data(grid_pos: Vector2i) -> Dictionary:
	if not is_valid_grid_position(grid_pos):
		return {}
	
	var index = grid_pos.y * grid_width + grid_pos.x
	if index >= 0 and index < grid_data.size():
		return grid_data[index]
	return {}

## Modifie l'état d'une cellule
func set_cell_state(grid_pos: Vector2i, new_state: CellState):
	if not is_valid_grid_position(grid_pos):
		return
		
	var cell_data = get_cell_data(grid_pos)
	if not cell_data.is_empty():
		cell_data["state"] = new_state
		# Mettre à jour le visuel de la cellule concernée
		_update_cell_visual(grid_pos)

## Modifie le type d'une cellule
func set_cell_type(grid_pos: Vector2i, new_type: CellType):
	if not is_valid_grid_position(grid_pos):
		return
	
	var cell_data = get_cell_data(grid_pos)
	if not cell_data.is_empty():
		cell_data["type"] = new_type
		_update_cell_visual(grid_pos)

## Vérifie si une position est dans les limites de la grille
func is_valid_grid_position(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < grid_width and grid_pos.y >= 0 and grid_pos.y < grid_height

## Vérifie si une cellule est marchable (pour le pathfinding)
func is_cell_walkable(grid_pos: Vector2i) -> bool:
	var cell_data = get_cell_data(grid_pos)
	if cell_data.is_empty():
		return false
	
	# Une cellule est marchable si elle n'est ni bloquée, ni occupée
	var is_walkable_type = cell_data["type"] == CellType.WALKABLE
	var is_unoccupied = cell_data["occupied_by"] == ""
	
	return is_walkable_type and is_unoccupied

## Définit l'occupant d'une cellule
func set_cell_occupied(grid_pos: Vector2i, occupant_id: String):
	if not is_valid_grid_position(grid_pos):
		return
		
	var cell_data = get_cell_data(grid_pos)
	if not cell_data.is_empty():
		cell_data["occupied_by"] = occupant_id

# ================================
# SÉLECTION D'ACTIONS ET VALIDATION
# ================================

## Définit l'action courante du joueur
func set_current_action(action: CombatState.ActionType, spell_id: String = ""):
	current_action = action
	selected_spell_id = spell_id
	
	# Mettre à jour les portées affichées
	_update_action_ranges()
	
	print("[CombatGrid] Action sélectionnée: ", action, " (sort: ", spell_id, ")")

## Gère le clic sur une cellule avec validation PA/PM
func handle_cell_click(grid_pos: Vector2i):
	if not is_valid_grid_position(grid_pos):
		invalid_action.emit("Position invalide")
		return
	
	var cell_data = get_cell_data(grid_pos)
	if cell_data.is_empty():
		invalid_action.emit("Cellule inaccessible")
		return
	
	# Valider l'action selon le type
	var action_data = {}
	var is_valid = false
	
	match current_action:
		CombatState.ActionType.MOVE:
			is_valid = _validate_movement(grid_pos, action_data)
		CombatState.ActionType.CAST_SPELL:
			is_valid = _validate_spell_cast(grid_pos, action_data)
		_:
			invalid_action.emit("Action non supportée")
			return
	
	if is_valid:
		cell_clicked.emit(grid_pos, current_action, action_data)
	else:
		invalid_action.emit("Action invalide pour cette cellule")

## Valide un mouvement vers une position
func _validate_movement(target_pos: Vector2i, action_data: Dictionary) -> bool:
	if not local_player_combatant:
		return false
	
	var player_pos = Vector2i(local_player_combatant.pos_x, local_player_combatant.pos_y)
	var distance = _calculate_grid_distance(player_pos, target_pos)
	
	# Vérifier si la cellule est dans la portée de mouvement
	if distance > local_player_combatant.remaining_movement_points:
		return false
	
	# Vérifier si la cellule est marchable
	if not is_cell_walkable(target_pos):
		return false
	
	action_data["target_x"] = target_pos.x
	action_data["target_y"] = target_pos.y
	action_data["movement_cost"] = distance
	
	return true

## Valide un lancement de sort vers une position
func _validate_spell_cast(target_pos: Vector2i, action_data: Dictionary) -> bool:
	if not local_player_combatant or selected_spell_id.is_empty():
		return false
	
	var player_pos = Vector2i(local_player_combatant.pos_x, local_player_combatant.pos_y)
	var distance = _calculate_grid_distance(player_pos, target_pos)
	
	# TODO: Récupérer les vraies données du sort depuis le serveur
	# Pour l'instant, utiliser des valeurs par défaut
	var spell_range = 3
	var spell_ap_cost = 2
	
	# Vérifier si le joueur a assez de PA
	if local_player_combatant.remaining_action_points < spell_ap_cost:
		return false
	
	# Vérifier si la cible est dans la portée
	if distance > spell_range:
		return false
	
	action_data["spell_id"] = selected_spell_id
	action_data["target_x"] = target_pos.x
	action_data["target_y"] = target_pos.y
	action_data["ap_cost"] = spell_ap_cost
	
	return true

# ================================
# CONVERSIONS DE COORDONNÉES
# ================================

## Convertit des coordonnées de grille en coordonnées écran (isométrique)
func grid_to_screen(grid_pos: Vector2i) -> Vector2:
	var screen_x = (grid_pos.x - grid_pos.y) * (CELL_WIDTH / 2.0)
	var screen_y = (grid_pos.x + grid_pos.y) * (CELL_HEIGHT / 2.0)
	return Vector2(screen_x, screen_y)

## Convertit des coordonnées écran en coordonnées de grille
func screen_to_grid(screen_pos: Vector2) -> Vector2i:
	var local_pos = screen_pos
	var grid_x = (local_pos.x / (CELL_WIDTH / 2.0) + local_pos.y / (CELL_HEIGHT / 2.0)) / 2.0
	var grid_y = (local_pos.y / (CELL_HEIGHT / 2.0) - local_pos.x / (CELL_WIDTH / 2.0)) / 2.0
	return Vector2i(floor(grid_x), floor(grid_y))

# ================================
# GESTION VISUELLE
# ================================

## Génère ou met à jour les polygones pour toutes les cellules de la grille
func _generate_visual_grid():
	# Nettoyer les anciens visuels
	for child in grid_visual_parent.get_children():
		child.queue_free()

	# Créer les polygones pour chaque cellule
	for y in range(grid_height):
		for x in range(grid_width):
			var grid_pos = Vector2i(x, y)
			_create_cell_visual(grid_pos)

## Crée le polygone pour une seule cellule
func _create_cell_visual(grid_pos: Vector2i):
	var screen_pos = grid_to_screen(grid_pos)
	
	# Définir les points de la cellule (losange isométrique)
	var corners: Array[Vector2] = [
		Vector2(0, -CELL_HEIGHT / 2.0), # Haut
		Vector2(CELL_WIDTH / 2.0, 0),   # Droite
		Vector2(0, CELL_HEIGHT / 2.0),  # Bas
		Vector2(-CELL_WIDTH / 2.0, 0)   # Gauche
	]
	
	var packed_corners: PackedVector2Array = PackedVector2Array()
	for corner in corners:
		packed_corners.append(corner)
	
	var cell = Polygon2D.new()
	cell.name = "Cell_%d_%d" % [grid_pos.x, grid_pos.y]
	cell.polygon = packed_corners
	cell.color = _get_color_for_cell_state(CellState.NORMAL)
	cell.position = screen_pos
	
	# Créer une bordure
	var line = Line2D.new()
	line.name = "Border"
	line.points = packed_corners
	line.add_point(corners[0]) # Fermer la boucle
	line.width = 1.0
	line.default_color = Color.BLACK
	cell.add_child(line)

	grid_visual_parent.add_child(cell)
	
	# Mettre à jour la couleur initiale
	_update_cell_visual(grid_pos)

## Met à jour l'apparence d'une seule cellule
func _update_cell_visual(grid_pos: Vector2i):
	var cell_node = grid_visual_parent.get_node_or_null("Cell_%d_%d" % [grid_pos.x, grid_pos.y])
	if cell_node:
		var cell_data = get_cell_data(grid_pos)
		if cell_data.is_empty():
			return

		var cell_polygon: Polygon2D = cell_node
		cell_polygon.color = _get_color_for_cell_state(cell_data["state"])
			
		# Ajuster la visibilité de la bordure
		var border = cell_node.get_node_or_null("Border")
		if border:
			border.visible = (cell_data["state"] != CellState.NORMAL)
			if cell_data["state"] == CellState.HIGHLIGHTED or cell_data["state"] == CellState.PATH_PREVIEW:
				border.default_color = Color.WHITE
			else:
				border.default_color = Color(0.2, 0.2, 0.2)

## Retourne la couleur correspondant à un état de cellule (style Dofus)
func _get_color_for_cell_state(state: CellState) -> Color:
	match state:
		CellState.NORMAL:
			return Color(0, 0, 0, 0) # Transparent
		CellState.HIGHLIGHTED:
			return Color(1, 1, 1, 0.2) # Blanc transparent
		CellState.MOVEMENT_RANGE:
			return Color(0.2, 0.8, 1.0, 0.4) # Bleu clair (PM)
		CellState.SPELL_RANGE:
			return Color(1.0, 0.4, 0.2, 0.4) # Rouge orangé (Sort)
		CellState.PLACEMENT_ALLY:
			return Color(0.2, 0.8, 1.0, 0.6) # Cyan (Placement allié)
		CellState.PLACEMENT_ENEMY:
			return Color(1.0, 0.6, 0.2, 0.6) # Orange (Placement ennemi)
		CellState.PATH_PREVIEW:
			return Color(0.2, 1.0, 0.5, 0.5) # Vert (Chemin)
		CellState.OCCUPIED_ALLY:
			return Color(0.0, 0.8, 0.0, 0.3) # Vert (Allié)
		CellState.OCCUPIED_ENEMY:
			return Color(0.8, 0.0, 0.0, 0.3) # Rouge (Ennemi)
		CellState.INVALID_TARGET:
			return Color(0.5, 0.5, 0.5, 0.4) # Gris (Invalide)
	return Color.BLACK

# ================================
# MÉTHODES UTILITAIRES
# ================================

## Réinitialise tous les états visuels
func clear_all_states():
	for y in range(grid_height):
		for x in range(grid_width):
			var grid_pos = Vector2i(x, y)
			var cell_data = get_cell_data(grid_pos)
			
			# Garder l'occupation mais remettre à l'état normal
			if cell_data.get("occupied_by", "") != "":
				var team_id = 0  # TODO: Récupérer la vraie équipe
				var state = CellState.OCCUPIED_ALLY if team_id == 0 else CellState.OCCUPIED_ENEMY
				set_cell_state(grid_pos, state)
			else:
				set_cell_state(grid_pos, CellState.NORMAL)

## Affiche ou masque la grille
func show_grid():
	visible = true
	print("[CombatGrid] Grille affichée")

func hide_grid():
	visible = false
	print("[CombatGrid] Grille masquée") 
