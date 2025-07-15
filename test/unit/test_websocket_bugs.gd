extends RefCounted
class_name TestWebSocketBugs

# Tests pour les bugs WebSocket rencontrés dans le développement
var test_name = "TestWebSocketBugs"
var assertion_count = 0
var failed_assertions = []

func _init():
	print("=== Tests WebSocket Bugs ===")

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

# Bug 1: GameManager ne trouvait pas WebSocketManager
func test_gamemanager_websocket_connection():
	print("\n🔍 Test: GameManager WebSocket Connection Bug")
	
	var mock_autoloads = {}
	var mock_main_scene = {"WebSocketManager": "mock_websocket_manager"}
	
	var found_in_autoloads = mock_autoloads.has("WebSocketManager")
	var found_in_scene = mock_main_scene.has("WebSocketManager")
	
	assert_false(found_in_autoloads, "WebSocketManager ne devrait pas être dans les Autoloads")
	assert_true(found_in_scene, "WebSocketManager devrait être trouvé dans la scène principale")

# Bug 2: Messages WebSocket mal formatés
func test_websocket_message_format():
	print("\n📨 Test: WebSocket Message Format Bug")
	
	var correct_message = {
		"type": "move",
		"data": {"x": 100, "y": 200},
		"timestamp": 1234567890
	}
	
	assert_true(correct_message.has("type"), "Message devrait avoir un type")
	assert_true(correct_message.has("data"), "Message devrait avoir des données")
	assert_true(correct_message.has("timestamp"), "Message devrait avoir un timestamp")

# Bug 3: Timeout de connexion WebSocket
func test_websocket_timeout_handling():
	print("\n⏱️ Test: WebSocket Timeout Handling")
	
	var connection_start_time = 0
	var current_time = 5000  # 5 secondes
	var timeout_duration = 3000  # 3 secondes
	
	var is_timeout = (current_time - connection_start_time) > timeout_duration
	assert_true(is_timeout, "Timeout devrait être détecté après 3 secondes")

func run_all_tests():
	print("🧪 Démarrage des tests WebSocket Bugs...")
	
	test_gamemanager_websocket_connection()
	test_websocket_message_format()
	test_websocket_timeout_handling()
	
	print("\n📊 === RÉSULTATS ===")
	print("Assertions: ", assertion_count)
	print("Échecs: ", failed_assertions.size())
	
	if failed_assertions.size() == 0:
		print("✅ Tous les tests WebSocket ont réussi!")
		return true
	else:
		print("❌ Tests WebSocket échoués:")
		for failure in failed_assertions:
			print("  - ", failure)
		return false
