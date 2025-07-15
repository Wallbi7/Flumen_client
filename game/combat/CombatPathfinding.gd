extends Node
class_name CombatPathfinding

## SYSTÈME DE PATHFINDING A* POUR LE COMBAT TACTIQUE
## ==================================================
## Cette classe implémente l'algorithme A* optimisé pour les grilles de combat isométriques.
## Elle gère le calcul de chemins, la portée de mouvement, et les obstacles dynamiques.
##
## FONCTIONNALITÉS:
## - Algorithme A* avec heuristique Manhattan
## - Calcul de portée de mouvement avec algorithme de Dijkstra
## - Gestion des obstacles statiques et dynamiques
## - Support du mouvement diagonal et cardinal
## - Optimisations pour les performances en temps réel

# ================================
# STRUCTURES DE DONNÉES
# ================================

## Classe représentant un nœud dans l'algorithme A*
class PathNode:
	var position: Vector2i      # Position dans la grille
	var g_cost: int = 0         # Coût depuis le départ
	var h_cost: int = 0         # Heuristique vers l'arrivée
	var f_cost: int = 0         # Coût total (g + h)
	var parent: PathNode = null # Nœud parent pour reconstruction du chemin
	var is_walkable: bool = true # Si le nœud est accessible
	
	func _init(pos: Vector2i, walkable: bool = true):
		position = pos
		is_walkable = walkable
		update_f_cost()
	
	func update_f_cost():
		f_cost = g_cost + h_cost

# ================================
# VARIABLES PRINCIPALES
# ================================

## Référence à la grille de combat
var combat_grid: CombatGrid = null

## Cache des chemins calculés pour optimisation
var path_cache: Dictionary = {}

## Limite de cache pour éviter l'explosion mémoire
const MAX_CACHE_SIZE: int = 100

## Coûts de mouvement selon la direction
const CARDINAL_COST: int = 10    # Mouvement horizontal/vertical
const DIAGONAL_COST: int = 14    # Mouvement diagonal (approximation de √2 * 10)

## Limite maximale pour éviter les boucles infinies
const MAX_ITERATIONS: int = 1000

# ================================
# SIGNAUX
# ================================

## Émis quand un chemin est calculé
signal path_calculated(from: Vector2i, to: Vector2i, path: Array[Vector2i])

## Émis quand aucun chemin n'est trouvé
signal path_not_found(from: Vector2i, to: Vector2i)

# ================================
# INITIALISATION
# ================================

func _ready():
	print("[CombatPathfinding] === INITIALISATION DU SYSTÈME DE PATHFINDING ===")

## Initialise le système avec une référence à la grille de combat
func setup_with_grid(grid: CombatGrid):
	combat_grid = grid
	print("[CombatPathfinding] ✅ Grille de combat connectée")

# ================================
# ALGORITHME A* PRINCIPAL
# ================================

## Trouve le chemin le plus court entre deux points
func find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if combat_grid == null:
		print("[CombatPathfinding] ❌ Erreur: Grille de combat non initialisée")
		return []
	
	# Vérifier que les positions sont valides
	if not combat_grid.is_valid_grid_position(start) or not combat_grid.is_valid_grid_position(goal):
		print("[CombatPathfinding] ❌ Position invalide: ", start, " -> ", goal)
		path_not_found.emit(start, goal)
		return []
	
	# Vérifier que la destination est accessible
	if not combat_grid.is_cell_walkable(goal):
		print("[CombatPathfinding] ❌ Destination non accessible: ", goal)
		path_not_found.emit(start, goal)
		return []
	
	# Vérifier le cache
	var cache_key = str(start) + "_" + str(goal)
	if path_cache.has(cache_key):
		print("[CombatPathfinding] 📋 Chemin trouvé en cache: ", start, " -> ", goal)
		var cached_path = path_cache[cache_key]
		path_calculated.emit(start, goal, cached_path)
		return cached_path
	
	print("[CombatPathfinding] 🔍 Calcul de chemin A*: ", start, " -> ", goal)
	
	# Initialiser les listes
	var open_list: Array[PathNode] = []
	var closed_list: Dictionary = {}  # position -> PathNode
	
	# Créer le nœud de départ
	var start_node = PathNode.new(start, true)
	start_node.g_cost = 0
	start_node.h_cost = calculate_heuristic(start, goal)
	start_node.update_f_cost()
	
	open_list.append(start_node)
	
	var iterations = 0
	
	# Boucle principale A*
	while not open_list.is_empty() and iterations < MAX_ITERATIONS:
		iterations += 1
		
		# Trouver le nœud avec le plus petit f_cost
		var current_node = get_lowest_f_cost_node(open_list)
		open_list.erase(current_node)
		closed_list[current_node.position] = current_node
		
		# Vérifier si on a atteint l'objectif
		if current_node.position == goal:
			var path = reconstruct_path(current_node)
			print("[CombatPathfinding] ✅ Chemin trouvé en ", iterations, " itérations (longueur: ", path.size(), ")")
			
			# Mettre en cache
			_add_to_cache(cache_key, path)
			
			path_calculated.emit(start, goal, path)
			return path
		
		# Examiner les voisins
		var neighbors = combat_grid.get_neighbors(current_node.position, true)
		for neighbor_pos in neighbors:
			# Ignorer si déjà traité
			if closed_list.has(neighbor_pos):
				continue
			
			# Ignorer si non accessible
			if not combat_grid.is_cell_walkable(neighbor_pos):
				continue
			
			# Calculer le coût de mouvement
			var movement_cost = get_movement_cost(current_node.position, neighbor_pos)
			var tentative_g_cost = current_node.g_cost + movement_cost
			
			# Chercher si le voisin est déjà dans la liste ouverte
			var neighbor_node = find_node_in_open_list(open_list, neighbor_pos)
			
			if neighbor_node == null:
				# Nouveau nœud
				neighbor_node = PathNode.new(neighbor_pos, true)
				neighbor_node.g_cost = tentative_g_cost
				neighbor_node.h_cost = calculate_heuristic(neighbor_pos, goal)
				neighbor_node.parent = current_node
				neighbor_node.update_f_cost()
				open_list.append(neighbor_node)
			elif tentative_g_cost < neighbor_node.g_cost:
				# Chemin plus court trouvé
				neighbor_node.g_cost = tentative_g_cost
				neighbor_node.parent = current_node
				neighbor_node.update_f_cost()
	
	print("[CombatPathfinding] ❌ Aucun chemin trouvé après ", iterations, " itérations")
	path_not_found.emit(start, goal)
	return []

## Trouve le nœud avec le plus petit f_cost dans la liste ouverte
func get_lowest_f_cost_node(open_list: Array[PathNode]) -> PathNode:
	var lowest_node = open_list[0]
	
	for node in open_list:
		if node.f_cost < lowest_node.f_cost or (node.f_cost == lowest_node.f_cost and node.h_cost < lowest_node.h_cost):
			lowest_node = node
	
	return lowest_node

## Trouve un nœud par position dans la liste ouverte
func find_node_in_open_list(open_list: Array[PathNode], position: Vector2i) -> PathNode:
	for node in open_list:
		if node.position == position:
			return node
	return null

## Reconstruit le chemin depuis le nœud d'arrivée
func reconstruct_path(end_node: PathNode) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current_node = end_node
	
	while current_node != null:
		path.push_front(current_node.position)
		current_node = current_node.parent
	
	return path

# ================================
# CALCULS DE COÛTS ET HEURISTIQUES
# ================================

## Calcule l'heuristique Manhattan entre deux positions
func calculate_heuristic(from: Vector2i, to: Vector2i) -> int:
	var dx = abs(to.x - from.x)
	var dy = abs(to.y - from.y)
	
	# Heuristique Manhattan optimisée pour mouvement diagonal
	return CARDINAL_COST * (dx + dy) + (DIAGONAL_COST - 2 * CARDINAL_COST) * min(dx, dy)

## Calcule le coût de mouvement entre deux positions adjacentes
func get_movement_cost(from: Vector2i, to: Vector2i) -> int:
	var dx = abs(to.x - from.x)
	var dy = abs(to.y - from.y)
	
	# Mouvement diagonal
	if dx == 1 and dy == 1:
		return DIAGONAL_COST
	
	# Mouvement cardinal
	if (dx == 1 and dy == 0) or (dx == 0 and dy == 1):
		return CARDINAL_COST
	
	# Ne devrait pas arriver pour des voisins adjacents
	print("[CombatPathfinding] ⚠️ Mouvement non adjacent détecté: ", from, " -> ", to)
	return CARDINAL_COST * (dx + dy)

# ================================
# CALCUL DE PORTÉE DE MOUVEMENT
# ================================

## Calcule toutes les cellules accessibles dans une portée donnée (algorithme de Dijkstra)
func calculate_movement_range(start: Vector2i, max_movement_points: int) -> Array[Vector2i]:
	if combat_grid == null:
		print("[CombatPathfinding] ❌ Erreur: Grille de combat non initialisée")
		return []
	
	if not combat_grid.is_valid_grid_position(start):
		print("[CombatPathfinding] ❌ Position de départ invalide: ", start)
		return []
	
	print("[CombatPathfinding] 📏 Calcul de portée depuis ", start, " (PM: ", max_movement_points, ")")
	
	var reachable_cells: Array[Vector2i] = []
	var distances: Dictionary = {}  # position -> distance minimale
	var queue: Array[Dictionary] = []  # [{position: Vector2i, distance: int}]
	
	# Initialiser avec la position de départ
	distances[start] = 0
	queue.append({"position": start, "distance": 0})
	
	while not queue.is_empty():
		# Prendre l'élément avec la plus petite distance
		var current = queue.pop_front()
		var current_pos = current["position"]
		var current_distance = current["distance"]
		
		# Ajouter à la liste des cellules accessibles
		if current_distance <= max_movement_points:
			reachable_cells.append(current_pos)
		
		# Explorer les voisins
		var neighbors = combat_grid.get_neighbors(current_pos, true)
		for neighbor_pos in neighbors:
			# Ignorer si non accessible
			if not combat_grid.is_cell_walkable(neighbor_pos):
				continue
			
			# Calculer la nouvelle distance
			var movement_cost = get_movement_cost(current_pos, neighbor_pos)
			var new_distance = current_distance + movement_cost
			
			# Ignorer si dépasse la portée maximale
			if new_distance > max_movement_points * CARDINAL_COST:
				continue
			
			# Vérifier si c'est un chemin plus court
			if not distances.has(neighbor_pos) or new_distance < distances[neighbor_pos]:
				distances[neighbor_pos] = new_distance
				
				# Ajouter à la queue (insertion triée par distance)
				var inserted = false
				for i in range(queue.size()):
					if new_distance < queue[i]["distance"]:
						queue.insert(i, {"position": neighbor_pos, "distance": new_distance})
						inserted = true
						break
				
				if not inserted:
					queue.append({"position": neighbor_pos, "distance": new_distance})
	
	print("[CombatPathfinding] ✅ Portée calculée: ", reachable_cells.size(), " cellules accessibles")
	return reachable_cells

# ================================
# VALIDATION DE CHEMIN
# ================================

## Vérifie si un chemin est encore valide (aucun obstacle n'a été ajouté)
func is_path_valid(path: Array[Vector2i]) -> bool:
	if combat_grid == null or path.is_empty():
		return false
	
	for position in path:
		if not combat_grid.is_valid_grid_position(position):
			return false
		
		if not combat_grid.is_cell_walkable(position):
			return false
	
	return true

## Calcule le coût total d'un chemin
func calculate_path_cost(path: Array[Vector2i]) -> int:
	if path.size() < 2:
		return 0
	
	var total_cost = 0
	for i in range(1, path.size()):
		total_cost += get_movement_cost(path[i-1], path[i])
	
	return total_cost

# ================================
# GESTION DU CACHE
# ================================

## Ajoute un chemin au cache
func _add_to_cache(key: String, path: Array[Vector2i]):
	# Nettoyer le cache s'il est trop grand
	if path_cache.size() >= MAX_CACHE_SIZE:
		_clear_oldest_cache_entries()
	
	path_cache[key] = path

## Nettoie les entrées les plus anciennes du cache
func _clear_oldest_cache_entries():
	var keys = path_cache.keys()
	var entries_to_remove = keys.size() - MAX_CACHE_SIZE + 10  # Retirer 10 entrées de plus
	
	for i in range(entries_to_remove):
		if i < keys.size():
			path_cache.erase(keys[i])
	
	print("[CombatPathfinding] 🧹 Cache nettoyé: ", entries_to_remove, " entrées supprimées")

## Vide complètement le cache
func clear_cache():
	path_cache.clear()
	print("[CombatPathfinding] 🧹 Cache vidé complètement")

# ================================
# OPTIMISATIONS ET UTILITAIRES
# ================================

## Trouve le chemin le plus court en évitant certaines positions
func find_path_avoiding_positions(start: Vector2i, goal: Vector2i, avoid_positions: Array[Vector2i]) -> Array[Vector2i]:
	# Temporairement marquer les positions à éviter comme non marchables
	var original_states: Dictionary = {}
	
	for pos in avoid_positions:
		if combat_grid.is_valid_grid_position(pos):
			var cell_data = combat_grid.get_cell_data(pos)
			original_states[pos] = cell_data.get("occupied_by", "")
			combat_grid.set_cell_occupied(pos, "temporary_obstacle")
	
	# Calculer le chemin
	var path = find_path(start, goal)
	
	# Restaurer les états originaux
	for pos in original_states.keys():
		combat_grid.set_cell_occupied(pos, original_states[pos])
	
	return path

## Trouve la position accessible la plus proche d'un objectif
func find_nearest_accessible_position(target: Vector2i, max_search_radius: int = 5) -> Vector2i:
	if combat_grid == null:
		return Vector2i(-1, -1)
	
	# Si la position cible est déjà accessible
	if combat_grid.is_cell_walkable(target):
		return target
	
	# Recherche en spirale autour de la cible
	for radius in range(1, max_search_radius + 1):
		var candidates = get_positions_at_distance(target, radius)
		
		for pos in candidates:
			if combat_grid.is_valid_grid_position(pos) and combat_grid.is_cell_walkable(pos):
				return pos
	
	return Vector2i(-1, -1)  # Aucune position accessible trouvée

## Obtient toutes les positions à une distance donnée d'un point central
func get_positions_at_distance(center: Vector2i, distance: int) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	
	for x in range(-distance, distance + 1):
		for y in range(-distance, distance + 1):
			if abs(x) + abs(y) == distance:  # Distance Manhattan exacte
				positions.append(center + Vector2i(x, y))
	
	return positions

# ================================
# DEBUG ET DIAGNOSTICS
# ================================

## Affiche des statistiques de performance
func debug_print_performance_stats():
	print("[CombatPathfinding] === STATISTIQUES DE PERFORMANCE ===")
	print("Entrées en cache: ", path_cache.size(), "/", MAX_CACHE_SIZE)
	print("Coût cardinal: ", CARDINAL_COST)
	print("Coût diagonal: ", DIAGONAL_COST)
	print("Limite d'itérations: ", MAX_ITERATIONS)
	print("Grille connectée: ", combat_grid != null)
	print("================================================")

## Teste les performances du pathfinding
func debug_performance_test(iterations: int = 100):
	if combat_grid == null:
		print("[CombatPathfinding] ❌ Impossible de tester: grille non connectée")
		return
	
	print("[CombatPathfinding] 🧪 Test de performance (", iterations, " itérations)...")
	
	var start_time = Time.get_ticks_msec()
	var successful_paths = 0
	
	for i in range(iterations):
		var start_pos = combat_grid.find_random_free_cell()
		var goal_pos = combat_grid.find_random_free_cell()
		
		if start_pos != Vector2i(-1, -1) and goal_pos != Vector2i(-1, -1):
			var path = find_path(start_pos, goal_pos)
			if not path.is_empty():
				successful_paths += 1
	
	var end_time = Time.get_ticks_msec()
	var total_time = end_time - start_time
	
	print("[CombatPathfinding] ✅ Test terminé:")
	print("  - Temps total: ", total_time, "ms")
	print("  - Temps moyen: ", float(total_time) / iterations, "ms par chemin")
	print("  - Chemins trouvés: ", successful_paths, "/", iterations, " (", float(successful_paths) / iterations * 100, "%)")
	print("  - Entrées en cache: ", path_cache.size()) 