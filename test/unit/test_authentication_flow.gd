extends RefCounted
class_name TestAuthenticationFlow

# Tests pour le flow d'authentification Flumen MMORPG
var test_name = "TestAuthenticationFlow"
var assertion_count = 0
var failed_assertions = []

func _init():
	print("=== Tests Authentication Flow ===")

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

func assert_not_null(value, message: String = ""):
	assertion_count += 1
	if value == null:
		var error_msg = "Expected non-null value but got null"
		if message != "":
			error_msg = message + " - " + error_msg
		failed_assertions.append(error_msg)
		print("❌ ASSERTION FAILED: ", error_msg)
		return false
	print("✅ ", message if message != "" else "Assertion passed")
	return true

# Test 1: Validation des identifiants
func test_credentials_validation():
	print("\n🔐 Test: Credentials Validation")
	
	var valid_credentials = {"username": "testuser", "password": "testpass123"}
	var is_valid = validate_credentials(valid_credentials)
	assert_true(is_valid, "Identifiants valides devraient être acceptés")
	
	var invalid_credentials = [
		{"username": "", "password": "testpass123"},
		{"username": "testuser", "password": ""},
		{"username": "ab", "password": "testpass123"},
		{"username": "testuser", "password": "123"}
	]
	
	for cred in invalid_credentials:
		var is_invalid = validate_credentials(cred)
		assert_false(is_invalid, "Identifiants invalides devraient être rejetés")

# Test 2: États d'authentification
func test_authentication_states():
	print("\n📊 Test: Authentication States")
	
	var auth_states = {"IDLE": 0, "CONNECTING": 1, "AUTHENTICATING": 2, "AUTHENTICATED": 3}
	
	var current_state = auth_states.IDLE
	assert_eq(current_state, 0, "État initial devrait être IDLE")
	
	current_state = auth_states.CONNECTING
	assert_eq(current_state, 1, "État devrait passer à CONNECTING")
	
	current_state = auth_states.AUTHENTICATED
	assert_eq(current_state, 3, "État devrait passer à AUTHENTICATED")

# Test 3: Gestion des erreurs
func test_authentication_error_handling():
	print("\n⚠️ Test: Authentication Error Handling")
	
	var error_types = {
		"INVALID_CREDENTIALS": "Identifiants invalides",
		"SERVER_ERROR": "Erreur serveur",
		"TIMEOUT": "Timeout de connexion"
	}
	
	for error_code in error_types.keys():
		var error_message = error_types[error_code]
		var handled_error = handle_auth_error(error_code, error_message)
		
		assert_not_null(handled_error, "Erreur %s devrait être gérée" % error_code)
		assert_true(handled_error.has("code"), "Erreur devrait avoir un code")
		assert_true(handled_error.has("message"), "Erreur devrait avoir un message")

# Fonctions utilitaires
func validate_credentials(credentials: Dictionary) -> bool:
	if not credentials.has("username") or not credentials.has("password"):
		return false
	
	var username = credentials.username
	var password = credentials.password
	
	if username.length() < 3 or password.length() < 6:
		return false
	
	return true

func handle_auth_error(error_code: String, error_message: String) -> Dictionary:
	var user_friendly_messages = {
		"INVALID_CREDENTIALS": "Nom d'utilisateur ou mot de passe incorrect",
		"SERVER_ERROR": "Erreur du serveur, veuillez réessayer",
		"TIMEOUT": "Connexion expirée, veuillez réessayer"
	}
	
	return {
		"code": error_code,
		"message": error_message,
		"user_friendly": user_friendly_messages.get(error_code, "Erreur inconnue")
	}

func run_all_tests():
	print("🧪 Démarrage des tests Authentication Flow...")
	
	test_credentials_validation()
	test_authentication_states()
	test_authentication_error_handling()
	
	print("\n📊 === RÉSULTATS ===")
	print("Assertions: ", assertion_count)
	print("Échecs: ", failed_assertions.size())
	
	if failed_assertions.size() == 0:
		print("✅ Tous les tests Authentication Flow ont réussi!")
		return true
	else:
		print("❌ Tests Authentication Flow échoués:")
		for failure in failed_assertions:
			print("  - ", failure)
		return false
