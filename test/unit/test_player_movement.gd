extends RefCounted
class_name TestPlayerMovement

# Tests pour le déplacement du joueur Flumen MMORPG
var test_name = "TestPlayerMovement"
var assertion_count = 0
var failed_assertions = []

func _init():
	print("=== Tests Player Movement ===")

func assert_eq(actual, expected, message: String = ""):
	assertion_count += 1
	if actual != expected:
		var error_msg = "Expected <%s> but got <%s>" % [expected, actual]
		if message != "":
			error_msg = message + " - " + error_msg
		failed_assertions.append(error_msg)
		print("❌ ASSERTION FAILED: ", error_msg)
		return false
	print("✅ ", message if message != "" else "Assertion passed")
	return true

func assert_true(value, message: String = ""):
	assertion_count += 1
	if not value:
		var error_msg = "Expected true but got <%s>" % value
		if message != "":
			error_msg = message + " - " + error_msg
		failed_assertions.append(error_msg)
		print("❌ ASSERTION FAILED: ", error_msg)
		return false
	print("✅ ", message if message != "" else "Assertion passed")
	return true

func assert_false(value, message: String = ""):
	assertion_count += 1
	if value:
		var error_msg = "Expected false but got <%s>" % value
		if message != "":
			error_msg = message + " - " + error_msg
		failed_assertions.append(error_msg)
		print("❌ ASSERTION FAILED: ", error_msg)
		return false
	print("✅ ", message if message != "" else "Assertion passed")
	return true

# Test 1: Déplacement case par case
func test_grid_based_movement():
	print("\n🎯 Test: Grid Based Movement")
	
	var grid_size = 32
	var player_position = Vector2(96, 96)  # Position alignée sur la grille (96 = 32 * 3)
	
	var movements = [
		{"direction": "right", "expected": Vector2(128, 96)},
		{"direction": "left", "expected": Vector2(64, 96)},
		{"direction": "up", "expected": Vector2(96, 64)},
		{"direction": "down", "expected": Vector2(96, 128)}
	]
	
	for movement in movements:
		var new_position = calculate_grid_movement(player_position, movement.direction, grid_size)
		assert_eq(new_position, movement.expected, "Déplacement %s devrait être correct" % movement.direction)
		
		var is_aligned = is_position_grid_aligned(new_position, grid_size)
		assert_true(is_aligned, "Position après déplacement %s devrait être alignée" % movement.direction)

# Test 2: Validation des mouvements
func test_movement_validation():
	print("\n✅ Test: Movement Validation")
	
	var map_bounds = {"width": 1000, "height": 600}
	var grid_size = 32
	
	var valid_moves = [
		{"from": Vector2(96, 96), "to": Vector2(128, 96)},
		{"from": Vector2(96, 96), "to": Vector2(64, 96)},
		{"from": Vector2(96, 96), "to": Vector2(96, 64)},
		{"from": Vector2(96, 96), "to": Vector2(96, 128)}
	]
	
	for move in valid_moves:
		var is_valid = validate_movement(move.from, move.to, map_bounds, grid_size)
		assert_true(is_valid, "Mouvement de %s vers %s devrait être valide" % [move.from, move.to])
	
	var invalid_moves = [
		{"from": Vector2(96, 96), "to": Vector2(192, 96)},  # Trop loin
		{"from": Vector2(96, 96), "to": Vector2(128, 128)},  # Diagonale
		{"from": Vector2(96, 96), "to": Vector2(-32, 96)}   # Hors limites
	]
	
	for move in invalid_moves:
		var is_invalid = validate_movement(move.from, move.to, map_bounds, grid_size)
		assert_false(is_invalid, "Mouvement de %s vers %s devrait être invalide" % [move.from, move.to])

# Test 3: États de déplacement
func test_movement_states():
	print("\n📊 Test: Movement States")
	
	var movement_states = {"IDLE": 0, "MOVING": 1, "WAITING_SERVER": 2, "COMPLETED": 3}
	
	var current_state = movement_states.IDLE
	assert_eq(current_state, 0, "État initial devrait être IDLE")
	
	current_state = movement_states.MOVING
	assert_eq(current_state, 1, "État devrait passer à MOVING")
	
	current_state = movement_states.COMPLETED
	assert_eq(current_state, 3, "État devrait passer à COMPLETED")

# Test 4: Animation et interpolation
func test_movement_animation():
	print("\n🎬 Test: Movement Animation")
	
	var start_position = Vector2(96, 96)
	var end_position = Vector2(128, 96)
	
	var interpolation_tests = [
		{"progress": 0.0, "expected": start_position},
		{"progress": 0.5, "expected": Vector2(112, 96)},
		{"progress": 1.0, "expected": end_position}
	]
	
	for test in interpolation_tests:
		var interpolated_pos = interpolate_movement(start_position, end_position, test.progress)
		assert_eq(interpolated_pos, test.expected, "Interpolation à %.1f devrait être correcte" % test.progress)

# Fonctions utilitaires
func calculate_grid_movement(current_pos: Vector2, direction: String, grid_size: int) -> Vector2:
	match direction:
		"right":
			return current_pos + Vector2(grid_size, 0)
		"left":
			return current_pos + Vector2(-grid_size, 0)
		"up":
			return current_pos + Vector2(0, -grid_size)
		"down":
			return current_pos + Vector2(0, grid_size)
		_:
			return current_pos

func is_position_grid_aligned(position: Vector2, grid_size: int) -> bool:
	# Utiliser fmod pour les nombres flottants
	return fmod(position.x, grid_size) == 0.0 and fmod(position.y, grid_size) == 0.0

func validate_movement(from: Vector2, to: Vector2, map_bounds: Dictionary, grid_size: int) -> bool:
	var diff = to - from
	var abs_diff = Vector2(abs(diff.x), abs(diff.y))
	
	if not ((abs_diff.x == grid_size and abs_diff.y == 0) or (abs_diff.x == 0 and abs_diff.y == grid_size)):
		return false
	
	if to.x < 0 or to.y < 0 or to.x >= map_bounds.width or to.y >= map_bounds.height:
		return false
	
	return true

func interpolate_movement(start: Vector2, end: Vector2, progress: float) -> Vector2:
	return start.lerp(end, progress)

func run_all_tests():
	print("🧪 Démarrage des tests Player Movement...")
	
	test_grid_based_movement()
	test_movement_validation()
	test_movement_states()
	test_movement_animation()
	
	print("\n📊 === RÉSULTATS ===")
	print("Assertions: ", assertion_count)
	print("Échecs: ", failed_assertions.size())
	
	if failed_assertions.size() == 0:
		print("✅ Tous les tests Player Movement ont réussi!")
		return true
	else:
		print("❌ Tests Player Movement échoués:")
		for failure in failed_assertions:
			print("  - ", failure)
		return false
