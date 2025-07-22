extends Node2D
class_name CombatGrid

## GRILLE DE COMBAT TACTIQUE DOFUS-LIKE (Synchronisée avec serveur)
## =================================================================
## Grille isométrique adaptée pour le nouveau système de combat serveur.
## Gère les zones de placement, validation PA/PM, et interaction tactique.

# ================================
# CONSTANTES DE GRILLE (Style Dofus Authentique)
# ================================
const CELL_WIDTH: int = 64  # Taille plus grande pour meilleure visibilité
const CELL_HEIGHT: int = 32  # Ratio 2:1 pour losanges isométriques parfaits

# ================================
# VARIABLES DE GRILLE
# ================================

## Dimensions de la grille (Style Dofus authentique)
var grid_width: int = 17  # Largeur standard Dofus
var grid_height: int = 15  # Hauteur standard Dofus

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

## Centre la grille style Dofus sur l'écran
func _center_grid_on_screen():
	# CORRECTION: Ne pas centrer la grille forcément pour conserver les positions relatives
	print("[CombatGrid] 📍 Conservation de la position naturelle de la grille (pas de recentrage)")
	print("[CombatGrid] 📍 Position actuelle conservée: %s" % position)
	
	# La grille reste à sa position naturelle pour conserver la cohérence spatiale avec la carte normale
	# Cela évite la téléportation du joueur vers une position incorrecte

# ================================
# SYNCHRONISATION AVEC SERVEUR
# ================================

## Met à jour la grille avec un nouvel état de combat du serveur
func update_from_combat_state(combat_state: CombatState):
	current_combat_state = combat_state
	local_player_combatant = _find_local_player_combatant()
	
	print("[CombatGrid] 🔄 Mise à jour grille depuis état serveur")
	
	# Mettre à jour les dimensions si nécessaire
	var dimensions_changed = false
	if combat_state.grid_width != grid_width or combat_state.grid_height != grid_height:
		grid_width = combat_state.grid_width
		grid_height = combat_state.grid_height
		initialize_grid(grid_width, grid_height)
		dimensions_changed = true
		print("[CombatGrid] 📐 Dimensions changées - grille réinitialisée")
	
	# IMPORTANT: Si les dimensions ont changé, initialize_grid a déjà créé les zones
	# Ne pas appeler _update_placement_zones qui va les écraser !
	if not dimensions_changed:
		print("[CombatGrid] 🔄 Mise à jour zones de placement (dimensions inchangées)")
		_update_placement_zones()
	else:
		print("[CombatGrid] ⏭️ Zones déjà créées par initialize_grid - skip _update_placement_zones")
	
	# Mettre à jour les positions des combattants
	_update_combatant_positions()
	
	# Mettre à jour les portées d'action selon le combattant actuel
	_update_action_ranges()
	
	# Forcer la régénération visuelle pour s'assurer que les zones sont visibles
	_generate_visual_grid()

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
					# Restaurer l'état de zone de placement si elle existe
					if cell_data.has("placement_zone"):
						if cell_data["placement_zone"] == "ally":
							cell_data["state"] = CellState.PLACEMENT_ALLY
						elif cell_data["placement_zone"] == "enemy":
							cell_data["state"] = CellState.PLACEMENT_ENEMY
					else:
						cell_data["state"] = CellState.NORMAL
	
	# Placer tous les combattants selon leurs positions serveur
	if current_combat_state:
		for combatant in current_combat_state.combatants:
			var grid_pos = Vector2i(combatant.pos_x, combatant.pos_y)
			if is_valid_grid_position(grid_pos):
				set_cell_occupied(grid_pos, combatant.character_id)
				var cell_data = get_cell_data(grid_pos)
				
				# Ne pas écraser l'état de zone de placement, juste marquer comme occupé
				if not cell_data.has("placement_zone"):
					var state = CellState.OCCUPIED_ALLY if combatant.team_id == 0 else CellState.OCCUPIED_ENEMY
					set_cell_state(grid_pos, state)
				else:
					# Garder la zone de placement visible, mais marquer comme occupé
					print("[CombatGrid] Combattant placé sur zone de placement: ", grid_pos, " zone=", cell_data["placement_zone"])
	
	# Ne pas régénérer ici - on le fait dans update_from_server_state()

## Met à jour les zones de placement depuis l'état du serveur uniquement
func _update_placement_zones():
	if not current_combat_state:
		# Créer les zones par défaut si pas d'état combat
		_create_default_dofus_placement_zones()
		return
	
	# NOUVEAU: Utiliser UNIQUEMENT les zones du serveur (JSON config ou default)
	print("[CombatGrid] 🔄 Utilisation des zones serveur - Alliés: ", current_combat_state.ally_start_zone.size(), " Ennemis: ", current_combat_state.enemy_start_zone.size())
	
	# Nettoyer les zones existantes
	_clear_all_placement_zones()
	
	# Appliquer les zones alliées (ROUGE) du serveur
	for zone_pos in current_combat_state.ally_start_zone:
		var cell_pos = Vector2i(zone_pos.x, zone_pos.y)
		if is_valid_grid_position(cell_pos):
			var cell_data = get_cell_data(cell_pos)
			cell_data["placement_zone"] = "ally"
			set_cell_state(cell_pos, CellState.PLACEMENT_ALLY)
			print("[CombatGrid] 🔴 Zone alliée (rouge) du serveur: ", cell_pos)
	
	# Appliquer les zones ennemies (BLEUE) du serveur  
	for zone_pos in current_combat_state.enemy_start_zone:
		var cell_pos = Vector2i(zone_pos.x, zone_pos.y)
		if is_valid_grid_position(cell_pos):
			var cell_data = get_cell_data(cell_pos)
			cell_data["placement_zone"] = "enemy"
			set_cell_state(cell_pos, CellState.PLACEMENT_ENEMY)
			print("[CombatGrid] 🔵 Zone ennemie (bleue) du serveur: ", cell_pos)

## Crée les zones de placement par défaut style Dofus avec plus de cases
func _create_default_dofus_placement_zones():
	print("[CombatGrid] 🎨 Création des zones de placement - Rouge=Alliés, Bleu=Ennemis")
	
	var enemy_placed = 0
	var ally_placed = 0
	
	# Zone BLEUE (ennemis/monstres) - côté gauche étendu  
	var enemy_columns = 6  # Plus de colonnes pour les ennemis
	for y in range(grid_height):
		for x in range(0, min(enemy_columns, grid_width)):
			var cell_pos = Vector2i(x, y)
			if is_valid_grid_position(cell_pos):
				var cell_data = get_cell_data(cell_pos)
				# Marquer comme zone ennemie ET forcer l'état visuel
				cell_data["placement_zone"] = "enemy"
				set_cell_state(cell_pos, CellState.PLACEMENT_ENEMY)  # Bleu pour ennemis - TOUJOURS
				enemy_placed += 1
				print("[CombatGrid] 🔵 Zone ennemie (bleue) forcée: ", cell_pos, " état=", cell_data["state"])
	
	# Zone ROUGE (alliés/joueur) - côté droit étendu
	var ally_columns = 6  # Plus de colonnes pour les alliés
	var start_x = max(grid_width - ally_columns, 0)
	for y in range(grid_height):
		for x in range(start_x, grid_width):
			var cell_pos = Vector2i(x, y)
			if is_valid_grid_position(cell_pos):
				var cell_data = get_cell_data(cell_pos)
				# Marquer comme zone alliée ET forcer l'état visuel
				cell_data["placement_zone"] = "ally"
				set_cell_state(cell_pos, CellState.PLACEMENT_ALLY)  # Rouge pour alliés - TOUJOURS
				ally_placed += 1
				print("[CombatGrid] 🔴 Zone alliée (rouge) forcée: ", cell_pos, " état=", cell_data["state"])
	
	# FORCER la régénération des visuels pour afficher les zones
	print("[CombatGrid] 🔄 Régénération forcée des visuels...")
	_generate_visual_grid()
	
	print("[CombatGrid] ✅ Zones créées et affichées: %d cases bleues (ennemis), %d cases rouges (alliés)" % [enemy_placed, ally_placed])

## Préserve les zones de placement locales (évite qu'elles soient écrasées par le serveur)
func _preserve_local_placement_zones():
	"""Maintient les zones locales étendues pendant la phase de placement"""
	print("[CombatGrid] 🛡️ Préservation des zones locales étendues...")
	
	var preserved_count = 0
	
	# Parcourir toutes les cellules et préserver celles avec placement_zone
	for y in range(grid_height):
		for x in range(grid_width):
			var cell_pos = Vector2i(x, y)
			if is_valid_grid_position(cell_pos):
				var cell_data = get_cell_data(cell_pos)
				if cell_data.has("placement_zone"):
					# Réappliquer l'état visuel pour être sûr
					if cell_data["placement_zone"] == "ally":
						set_cell_state(cell_pos, CellState.PLACEMENT_ALLY)
						preserved_count += 1
					elif cell_data["placement_zone"] == "enemy":
						set_cell_state(cell_pos, CellState.PLACEMENT_ENEMY)
						preserved_count += 1
	
	print("[CombatGrid] ✅ %d zones préservées et réappliquées" % preserved_count)

## Nettoie les zones de placement
func clear_placement_zones():
	"""Supprime les zones de placement bleues et rouges"""
	
	# PROTECTION: Ne jamais nettoyer pendant la phase de placement !
	if current_combat_state and current_combat_state.status == CombatState.CombatStatus.PLACEMENT:
		print("[CombatGrid] 🛡️ PROTECTION: Nettoyage des zones refusé en phase PLACEMENT")
		return
	
	print("[CombatGrid] 🧹 Nettoyage des zones de placement autorisé...")
	var cleaned_count = 0
	
	for y in range(grid_height):
		for x in range(grid_width):
			var cell_pos = Vector2i(x, y)
			var cell_data = get_cell_data(cell_pos)
			if not cell_data.is_empty():
				if cell_data["state"] in [CellState.PLACEMENT_ALLY, CellState.PLACEMENT_ENEMY]:
					set_cell_state(cell_pos, CellState.NORMAL)
					# Supprimer aussi la marque placement_zone
					if cell_data.has("placement_zone"):
						cell_data.erase("placement_zone")
					cleaned_count += 1
	
	_generate_visual_grid()
	print("[CombatGrid] ✅ %d zones de placement nettoyées" % cleaned_count)

## Nettoie toutes les zones de placement (sans protection)
func _clear_all_placement_zones():
	"""Supprime toutes les zones de placement sans vérification de phase"""
	var cleaned_count = 0
	
	for y in range(grid_height):
		for x in range(grid_width):
			var cell_pos = Vector2i(x, y)
			var cell_data = get_cell_data(cell_pos)
			if not cell_data.is_empty():
				if cell_data["state"] in [CellState.PLACEMENT_ALLY, CellState.PLACEMENT_ENEMY]:
					set_cell_state(cell_pos, CellState.NORMAL)
					# Supprimer aussi la marque placement_zone
					if cell_data.has("placement_zone"):
						cell_data.erase("placement_zone")
					cleaned_count += 1
	
	print("[CombatGrid] 🧹 %d zones nettoyées (sans protection)" % cleaned_count)

## Gère le clic sur une cellule de placement
func handle_placement_click(grid_pos: Vector2i):
	"""Gère le clic sur une cellule rouge pour placer le joueur"""
	if not is_valid_grid_position(grid_pos):
		print("[CombatGrid] ❌ Position invalide: ", grid_pos)
		return false
	
	var cell_data = get_cell_data(grid_pos)
	if cell_data.is_empty():
		print("[CombatGrid] ❌ Données cellule vides: ", grid_pos)
		return false
	
	# Vérifier que c'est une zone de placement alliée (rouge) ou marquée ally
	var is_ally_zone = (cell_data["state"] == CellState.PLACEMENT_ALLY) or (cell_data.get("placement_zone", "") == "ally")
	if not is_ally_zone:
		print("[CombatGrid] ❌ Placement invalide - Cliquer sur une zone rouge (alliée)")
		print("[CombatGrid] 📍 État actuel: ", cell_data["state"], " Zone: ", cell_data.get("placement_zone", "none"))
		return false
	
	# Vérifier que la cellule n'est pas occupée
	if cell_data["occupied_by"] != "":
		print("[CombatGrid] ❌ Cellule déjà occupée par: ", cell_data["occupied_by"])
		return false
	
	# Placer le joueur ici
	print("[CombatGrid] ✅ Placement joueur autorisé sur zone rouge: ", grid_pos)
	place_player_at(grid_pos)
	return true

## Place le joueur à une position spécifique
func place_player_at(grid_pos: Vector2i):
	"""Place le joueur à la position spécifiée"""
	# Vérifier s'il y a déjà un joueur placé et nettoyer l'ancienne position
	_clear_previous_player_position()
	
	# Déplacer le joueur physiquement
	var world_pos = grid_to_screen(grid_pos) + global_position
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.current_player:
		game_manager.current_player.global_position = world_pos
		
		# S'assurer que le joueur est visible et au premier plan
		game_manager.current_player.visible = true
		game_manager.current_player.z_index = 1000  # Premier plan absolu
		
		print("[CombatGrid] 🎭 Joueur placé au premier plan - z_index: 1000")
		
		# Orientation vers la gauche (vers les monstres dans zone bleue)
		var player = game_manager.current_player
		if player.has_method("set_facing_direction"):
			player.set_facing_direction(-1)  # Face aux monstres (gauche)
		else:
			# Essayer de trouver le sprite du joueur
			var sprite_node = player.get_node_or_null("Sprite2D")
			if not sprite_node:
				sprite_node = player.get_node_or_null("sprite")
			if sprite_node and sprite_node is Sprite2D:
				sprite_node.flip_h = true  # Face vers la gauche
	
	# Marquer la cellule comme occupée
	set_cell_occupied(grid_pos, "player")
	set_cell_state(grid_pos, CellState.OCCUPIED_ALLY)
	
	print("[CombatGrid] ✅ Joueur placé en position: ", grid_pos)

## Nettoie l'ancienne position du joueur
func _clear_previous_player_position():
	"""Nettoie la position précédente du joueur"""
	for y in range(grid_height):
		for x in range(grid_width):
			var pos = Vector2i(x, y)
			var cell_data = get_cell_data(pos)
			if cell_data["occupied_by"] == "player":
				cell_data["occupied_by"] = ""
				if cell_data["state"] == CellState.OCCUPIED_ALLY:
					# Remettre en zone de placement si c'était dans la zone rouge
					if x >= grid_width - 4:
						set_cell_state(pos, CellState.PLACEMENT_ALLY)
					else:
						set_cell_state(pos, CellState.NORMAL)

## Gestionnaire de clic sur une cellule
func _on_cell_clicked(grid_pos: Vector2i):
	"""Appelé quand l'utilisateur clique sur une cellule de la grille"""
	return func(viewport: Node, event: InputEvent, shape_idx: int):
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				print("[CombatGrid] 🖱️ Clic sur cellule: ", grid_pos)
				handle_cell_click(grid_pos)

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
	
	# Créer les zones de placement style Dofus par défaut
	_create_default_dofus_placement_zones()
	
	print("[CombatGrid] ✅ Grille Dofus %dx%d créée avec %d cellules et zones de placement" % [grid_width, grid_height, grid_width * grid_height])

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
	
	# Vérifier si on est en phase de placement
	if _is_placement_phase():
		if handle_placement_click(grid_pos):
			return
		else:
			invalid_action.emit("Placement invalide - Cliquer sur une zone rouge (alliée)")
			return
	
	# Mode combat normal
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

## Vérifie si on est en phase de placement
func _is_placement_phase() -> bool:
	"""Vérifie si on est actuellement en phase de placement"""
	if current_combat_state:
		return current_combat_state.status == CombatState.CombatStatus.PLACEMENT
	
	# Si pas d'état de combat, on assume qu'on est en placement si on voit des zones
	for y in range(grid_height):
		for x in range(grid_width):
			var cell_data = get_cell_data(Vector2i(x, y))
			if not cell_data.is_empty() and cell_data["state"] == CellState.PLACEMENT_ALLY:
				return true
	return false

## Valide un mouvement vers une position
func _validate_movement(target_pos: Vector2i, action_data: Dictionary) -> bool:
	# Pendant la phase de placement, permettre le mouvement libre dans toute la zone rouge
	if _is_placement_phase():
		# Le joueur peut se déplacer librement dans la zone rouge (côté droit)
		if target_pos.x >= grid_width - 4:
			# Vérifier que la cellule n'est pas occupée
			if is_cell_walkable(target_pos):
				action_data["target_x"] = target_pos.x
				action_data["target_y"] = target_pos.y
				action_data["movement_cost"] = 0  # Gratuit pendant placement
				return true
		return false
	
	# Pendant le combat, utiliser le système de PM classique
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
	print("[CombatGrid] 🔄 Génération/mise à jour grille visuelle...")
	
	# NOUVELLE APPROCHE: Mettre à jour au lieu de recréer
	var existing_cells = {}
	
	# Inventaire des cellules existantes
	for child in grid_visual_parent.get_children():
		if child.name.begins_with("Cell_"):
			existing_cells[child.name] = child
	
	# Créer ou mettre à jour chaque cellule
	for y in range(grid_height):
		for x in range(grid_width):
			var grid_pos = Vector2i(x, y)
			var cell_name = "Cell_%d_%d" % [grid_pos.x, grid_pos.y]
			
			if existing_cells.has(cell_name):
				# Cellule existe déjà - juste mettre à jour sa couleur
				_update_cell_visual(grid_pos)
			else:
				# Nouvelle cellule - la créer
				_create_cell_visual(grid_pos)
	
	# Supprimer les cellules en trop (si la grille a rétréci)
	for cell_name in existing_cells:
		var coords = cell_name.split("_")
		if coords.size() >= 3:
			var x = int(coords[1])
			var y = int(coords[2]) 
			if x >= grid_width or y >= grid_height:
				existing_cells[cell_name].queue_free()
				print("[CombatGrid] 🗑️ Cellule supprimée: ", cell_name)
	
	print("[CombatGrid] ✅ Grille visuelle mise à jour sans destruction")

## Crée le polygone pour une seule cellule (losange Dofus authentique)
func _create_cell_visual(grid_pos: Vector2i):
	var screen_pos = grid_to_screen(grid_pos)
	
	# Définir les points de la cellule (losange Dofus parfait)
	var corners: Array[Vector2] = [
		Vector2(0, -CELL_HEIGHT / 2.0),     # Haut
		Vector2(CELL_WIDTH / 2.0, 0),       # Droite  
		Vector2(0, CELL_HEIGHT / 2.0),      # Bas
		Vector2(-CELL_WIDTH / 2.0, 0)       # Gauche
	]
	
	var packed_corners: PackedVector2Array = PackedVector2Array()
	for corner in corners:
		packed_corners.append(corner)
	
	var cell = Polygon2D.new()
	cell.name = "Cell_%d_%d" % [grid_pos.x, grid_pos.y]
	cell.polygon = packed_corners
	cell.color = _get_color_for_cell_state(CellState.NORMAL)  # Couleur initiale
	cell.position = screen_pos
	
	# Créer une bordure style Dofus (visible et contrastée)
	var line = Line2D.new()
	line.name = "Border"
	line.points = packed_corners
	line.add_point(corners[0]) # Fermer la boucle
	line.width = 2.0  # Plus épaisse pour meilleure visibilité
	line.default_color = Color(0.1, 0.1, 0.1, 0.9)  # Noir presque opaque
	line.z_index = 1
	cell.add_child(line)

	grid_visual_parent.add_child(cell)
	
	# Ajouter une zone de clic pour la cellule
	var click_area = Area2D.new()
	click_area.name = "ClickArea"
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(CELL_WIDTH, CELL_HEIGHT)
	collision_shape.shape = shape
	click_area.add_child(collision_shape)
	cell.add_child(click_area)
	
	# Connecter le signal de clic
	click_area.input_event.connect(_on_cell_clicked(grid_pos))
	
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
		var color: Color
		
		# PRIORITÉ ABSOLUE aux zones de placement avec debug intensif
		if cell_data.has("placement_zone"):
			if cell_data["placement_zone"] == "ally":
				color = _get_color_for_cell_state(CellState.PLACEMENT_ALLY)
				print("[CombatGrid] 🔴 Zone alliée ROUGE forcée: ", grid_pos, " couleur=", color)
			elif cell_data["placement_zone"] == "enemy":
				color = _get_color_for_cell_state(CellState.PLACEMENT_ENEMY)
				print("[CombatGrid] 🔵 Zone ennemie BLEUE forcée: ", grid_pos, " couleur=", color)
			else:
				color = _get_color_for_cell_state(cell_data["state"])
				print("[CombatGrid] ⚪ Zone placement inconnue: ", grid_pos, " état=", cell_data["state"])
		else:
			color = _get_color_for_cell_state(cell_data["state"])
			if cell_data["state"] != CellState.NORMAL:
				print("[CombatGrid] ⚫ Cellule normale avec état: ", grid_pos, " état=", cell_data["state"])
		
		# FORCER l'application de la couleur
		cell_polygon.color = color
		cell_polygon.modulate = Color.WHITE  # S'assurer que la modulation ne cache pas la couleur
		
		# Debug final pour vérifier l'application
		print("[CombatGrid] 🎨 Couleur appliquée à ", grid_pos, ": ", color, " sur polygon: ", cell_polygon.color)
		
		# Ajuster la visibilité de la bordure pour les zones de placement
		var border = cell_node.get_node_or_null("Border")
		if border:
			# Bordure visible pour les zones de placement
			if cell_data.has("placement_zone") or cell_data["state"] in [CellState.PLACEMENT_ALLY, CellState.PLACEMENT_ENEMY]:
				border.visible = true
				border.default_color = Color.WHITE  # Bordure blanche pour contraste
				border.width = 3.0  # Plus épaisse pour les zones
			else:
				border.visible = (cell_data["state"] != CellState.NORMAL)
				if cell_data["state"] == CellState.HIGHLIGHTED or cell_data["state"] == CellState.PATH_PREVIEW:
					border.default_color = Color.WHITE
				else:
					border.default_color = Color(0.2, 0.2, 0.2)

## Retourne la couleur correspondant à un état de cellule (style Dofus authentique)
func _get_color_for_cell_state(state: CellState) -> Color:
	match state:
		CellState.NORMAL:
			return Color(0, 0, 0, 0) # Transparent
		CellState.HIGHLIGHTED:
			return Color(1, 1, 1, 0.4) # Blanc transparent
		CellState.MOVEMENT_RANGE:
			return Color(0.2, 0.7, 1.0, 0.6) # Bleu mouvement (PM)
		CellState.SPELL_RANGE:
			return Color(1.0, 0.3, 0.3, 0.6) # Rouge sort
		CellState.PLACEMENT_ALLY:
			return Color(1.0, 0.2, 0.2, 0.8) # Rouge pour zones alliées (joueur)
		CellState.PLACEMENT_ENEMY:
			return Color(0.2, 0.4, 1.0, 0.8) # Bleu pour zones ennemies (monstres)
		CellState.PATH_PREVIEW:
			return Color(0.0, 1.0, 0.0, 0.7) # Vert chemin
		CellState.OCCUPIED_ALLY:
			return Color(0.0, 0.7, 1.0, 0.5) # Bleu allié
		CellState.OCCUPIED_ENEMY:
			return Color(1.0, 0.0, 0.0, 0.5) # Rouge ennemi
		CellState.INVALID_TARGET:
			return Color(0.5, 0.5, 0.5, 0.4) # Gris invalide
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
