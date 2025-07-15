extends Node

# Signaux pour informer l'interface utilisateur
signal login_success(player_data: Dictionary)
signal login_failed(error_message: String)
signal register_success(player_data: Dictionary)
signal register_failed(error_message: String)
signal logout_complete()
# signal token_refreshed(new_token: String) # Commenté car non utilisé pour l'instant

# Configuration du serveur
var _server_base_url = ""
var _http_request: HTTPRequest

# Données d'authentification
var _access_token: String = ""
var _refresh_token: String = ""
var _player_data: Dictionary = {}
var _is_authenticated: bool = false
var _should_remember: bool = false
var _request_in_progress: bool = false  # Protection contre requêtes multiples

# Clé de chiffrement locale (32 bytes). À terme, générer via settings.
const _LOCAL_AES_KEY = "0123456789ABCDEF0123456789ABCDEF" # 32 chars -> 256 bits

# Timer pour auto-refresh
var _refresh_timer: Timer

func _ready():
	print("AuthManager: Initializing...")
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)
	
	_http_request.timeout = 15.0
	
	# Utiliser l'URL depuis la configuration centralisée
	_server_base_url = ServerConfig.API_URL
	print("AuthManager: Using server URL from ServerConfig: ", _server_base_url)
	
	# Créer le timer de refresh
	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = 600.0 # 10 minutes
	_refresh_timer.autostart = true
	_refresh_timer.one_shot = false
	_refresh_timer.timeout.connect(_on_refresh_timer_timeout)
	add_child(_refresh_timer)
	# Charger tokens si remember-me actif
	_load_saved_tokens()

# ===================================================================
# INSCRIPTION (REGISTER)
# ===================================================================

func register(username: String, email: String, password: String, confirm_password: String, _character_class: String = "adventurer", _accept_terms: bool = false):
	"""
	Inscrit un nouveau joueur
	
	Args:
		username: Nom d'utilisateur (3-50 caractères, alphanumériques + _-)
		email: Adresse email valide
		password: Mot de passe (min 8 caractères avec majuscule, minuscule, chiffre, caractère spécial)
		confirm_password: Confirmation du mot de passe
		character_class: Classe du personnage (warrior, mage, archer, rogue, adventurer)
		accept_terms: booléen, doit être true
	"""
	
	# Validation côté client
	var validation_error = _validate_registration_data(username, email, password, confirm_password)
	if validation_error != "":
		print("AuthManager: Registration validation failed: ", validation_error)
		register_failed.emit(validation_error)
		return
	
	var request_data = {
		"username": username,
		"email": email,
		"password": password
	}
	
	print("AuthManager: Sending registration request for user: ", username)
	print("DEBUG request_data:", request_data)
	_send_request("register", request_data, HTTPClient.METHOD_POST)

# ===================================================================
# CONNEXION (LOGIN)
# ===================================================================

func login(identifier: String, password: String, remember_me: bool = false):
	"""
	Connecte un joueur existant
	
	Args:
		identifier: Email ou nom d'utilisateur
		password: Mot de passe du compte
		remember_me: Si true, la session sera sauvegardée localement
	"""
	
	if identifier.strip_edges() == "" or password == "":
		login_failed.emit("L'identifiant et le mot de passe sont requis")
		return
	
	var request_data = {
		"email": identifier,
		"password": password
	}
	
	# Stocker la préférence pour la sauvegarde
	_should_remember = remember_me
	
	print("AuthManager: Sending login request for user: ", identifier, " (Remember: ", remember_me, ")")
	_send_request("login", request_data, HTTPClient.METHOD_POST)

# ===================================================================
# DÉCONNEXION (LOGOUT)
# ===================================================================

func logout():
	"""Déconnecte le joueur actuel"""
	
	if not _is_authenticated:
		logout_complete.emit()
		return
	
	print("AuthManager: Logging out user")
	
	# Envoyer la requête de déconnexion au serveur
	# var headers = ["Authorization: Bearer " + _access_token]
	# _http_request.request(_server_base_url + "/logout", headers, HTTPClient.METHOD_POST)
	# NOTE: Endpoint non implémenté côté serveur, la déconnexion est gérée localement.
	
	# Nettoyer les données locales
	_clear_auth_data()
	logout_complete.emit()

# ===================================================================
# GESTION DES TOKENS
# ===================================================================

func refresh_token():
	"""Rafraîchit le token d'accès avec le refresh token"""
	
	if _refresh_token == "":
		print("AuthManager: No refresh token available")
		_clear_auth_data()
		return
	
	var request_data = {
		"refreshToken": _refresh_token
	}
	
	print("AuthManager: Refreshing access token")
	_send_request("refresh", request_data, HTTPClient.METHOD_POST)

func get_auth_header() -> Array:
	"""Retourne le header d'autorisation pour les requêtes authentifiées"""
	if _access_token != "":
		return ["Authorization: Bearer " + _access_token, "Content-Type: application/json"]
	return ["Content-Type: application/json"]

# ===================================================================
# GETTERS PUBLICS
# ===================================================================

func is_authenticated() -> bool:
	return _is_authenticated and _access_token != ""

func get_player_data() -> Dictionary:
	return _player_data

func get_username() -> String:
	return _player_data.get("username", "")

func get_player_level() -> int:
	return _player_data.get("level", 1)

func get_player_gold() -> int:
	return _player_data.get("gold", 0)

func get_character_id() -> int:
	"""Retourne l'ID du personnage depuis le JWT sous forme d'entier."""
	var payload = get_jwt_payload()
	var char_id = payload.get("character_id", 0)
	if typeof(char_id) == TYPE_INT:
		return char_id
	# Si c'est une chaîne, essayer de la convertir
	if typeof(char_id) == TYPE_STRING and char_id.is_valid_int():
		return int(char_id)
	return 0 # Retourne 0 si invalide ou non trouvé

func get_access_token() -> String:
	"""Retourne le token d'accès actuel."""
	return _access_token

func get_jwt_token() -> String:
	"""Alias pour get_access_token pour plus de clarté."""
	return _access_token

# Nouvelle méthode pour mettre à jour le token depuis d'autres managers
func set_access_token(token: String):
	"""Met à jour le token d'accès et l'état d'authentification."""
	_access_token = token
	_is_authenticated = token != ""

func get_jwt_payload() -> Dictionary:
	"""Décode le payload du token JWT sans vérifier la signature."""
	if _access_token == "":
		return {}
	
	var parts = _access_token.split(".")
	if parts.size() != 3:
		print("AuthManager: Invalid JWT format")
		return {}
	
	var payload_base64 = parts[1]
	
	# Ajouter le padding nécessaire pour base64
	while payload_base64.length() % 4 != 0:
		payload_base64 += "="
	
	var payload_bytes = Marshalls.base64_to_raw(payload_base64)
	if payload_bytes.size() == 0:
		print("AuthManager: Failed to decode base64 payload")
		return {}
	
	var json = JSON.new()
	var payload_string = payload_bytes.get_string_from_utf8()
	if json.parse(payload_string) != OK:
		print("AuthManager: Failed to parse JWT payload JSON: ", payload_string)
		return {}
	
	return json.data

# ===================================================================
# MÉTHODES PRIVÉES
# ===================================================================

func _send_request(endpoint: String, data: Dictionary, method: HTTPClient.Method):
	"""Envoie une requête HTTP au serveur"""
	
	# Vérifier si une requête est déjà en cours
	if _request_in_progress:
		print("AuthManager: Requête déjà en cours, ignorée")
		return
	
	_request_in_progress = true
	var url = _server_base_url + "/" + endpoint
	var headers = ["Content-Type: application/json"]
	var json_data = JSON.stringify(data)
	
	print("AuthManager: RAW JSON BODY: ", json_data)
	print("AuthManager: Sending ", endpoint, " request to: ", url)
	print("AuthManager: Request method: ", method)
	print("AuthManager: Request headers: ", headers)
	
	# Vérifier l'état de HTTPRequest avant d'envoyer
	if _http_request == null:
		print("AuthManager: ERROR - HTTPRequest is null!")
		return
	
	var result = _http_request.request(url, headers, method, json_data)
	print("AuthManager: Request call result: ", result)
	
	if result != OK:
		print("AuthManager: ERROR - Failed to send request, error code: ", result)
		_request_in_progress = false  # Reset flag en cas d'erreur
		var error_msg = "Erreur lors de l'envoi de la requête (code: " + str(result) + ")"
		login_failed.emit(error_msg)
		register_failed.emit(error_msg)

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	"""Gestionnaire de réponse HTTP"""
	
	# Marquer la requête comme terminée
	_request_in_progress = false
	
	var response_text = body.get_string_from_utf8()
	print("AuthManager: Received response - Code: ", response_code, " Body: ", response_text)
	
	if response_code == 0:
		print("AuthManager: Serveur principal inaccessible, tentative avec le serveur de fallback...")
		
		# Essayer de basculer vers localhost si ce n'est pas déjà fait
		if ServerConfig.server_domain != ServerConfig.fallback_domain:
			ServerConfig.use_fallback_server()
			_server_base_url = ServerConfig.auth_url
			print("AuthManager: Basculement vers: ", _server_base_url)
			
			# Retry la dernière requête avec le nouveau serveur
			# Note: Cette approche simple ne sauvegarde pas les données de la dernière requête
			# Pour une solution complète, il faudrait implémenter un système de retry plus sophistiqué
			var error_msg = "Serveur principal inaccessible. Veuillez réessayer (fallback activé)."
			login_failed.emit(error_msg)
			register_failed.emit(error_msg)
		else:
			var error_msg = "Impossible de contacter le serveur. Vérifiez que le serveur est démarré."
			login_failed.emit(error_msg)
			register_failed.emit(error_msg)
		return
	
	var json = JSON.new()
	var parse_result = json.parse(response_text)
	
	if parse_result != OK:
		print("AuthManager: Failed to parse JSON response")
		return
	
	var response_data = json.data
	
	# Gérer les différents types de réponses
	if response_code >= 200 and response_code < 300:
		_handle_success_response(response_data)
	else:
		_handle_error_response(response_data, response_code)

func _handle_success_response(data: Dictionary):
	"""Gère les réponses de succès"""
	
	# Nouvelle réponse pour l'inscription
	if data.has("userID"):
		var user_id = data.get("userID")
		print("AuthManager: Registration successful for user. UserID: ", user_id)
		
		# Nous n'avons pas encore toutes les données du joueur, juste l'ID.
		# Nous émettons le succès, LoginScene peut alors passer à la suite.
		register_success.emit({"userID": user_id})
		return

	# Nouvelle réponse pour le login, qui contient le token
	if data.has("token"):
		_access_token = data.get("token", "")
		_refresh_token = data.get("refresh_token", _refresh_token)
		_is_authenticated = true
		
		# On doit maintenant décoder le token pour récupérer les infos utilisateur
		# C'est une étape avancée, pour l'instant on utilise les données de la requête
		_player_data = {
			"username": "N/A", # A extraire du token plus tard
			"email": "N/A" # A extraire du token plus tard
		}
		
		# Sauvegarder le token seulement si demandé
		if _should_remember:
			_save_tokens()
			print("AuthManager: Tokens saved (remember me enabled)")
		else:
			print("AuthManager: Tokens not saved (remember me disabled)")
		
		print("AuthManager: Login successful. Token received.")
		login_success.emit(_player_data)
		return
	
	if data.has("accessToken"):
		# Réponse d'authentification (login) - reste la même pour l'instant
		_access_token = data.get("accessToken", "")
		_refresh_token = data.get("refreshToken", "")
		_is_authenticated = true
		
		# Extraire les données du joueur
		_player_data = {
			"playerUuid": data.get("playerUuid", ""),
			"username": data.get("username", ""),
			"email": data.get("email", ""),
			"level": data.get("level", 1),
			"experience": data.get("experience", 0),
			"gold": data.get("gold", 0),
			"characterClass": data.get("characterClass", ""),
			"currentMapId": data.get("currentMapId", ""),
			"positionX": data.get("positionX", 0.0),
			"positionY": data.get("positionY", 0.0),
			"firstLogin": data.get("firstLogin", false)
		}
		
		# Sauvegarder les tokens
		_save_tokens()
		
		print("AuthManager: Authentication successful for user: ", _player_data.username)
		
		# Émettre le signal approprié
		if data.get("firstLogin", false):
			register_success.emit(_player_data)
		else:
			login_success.emit(_player_data)
	else:
		# L'ancienne réponse de succès générique
		print("AuthManager: Received a success response without a known token or ID.")
		# On peut décider d'émettre un signal d'échec si on attendait une réponse spécifique
		register_failed.emit("Le serveur a répondu avec succès mais le format est inattendu.")

func _handle_error_response(data: Dictionary, response_code: int):
	"""Gère les réponses d'erreur"""
	
	var error_message = "Erreur inconnue"
	print("AuthManager: Full error response - ", data)
	print("AuthManager: Response code - ", response_code)
	
	# Si c'est une erreur de validation, essayer d'extraire plus de détails
	if data.has("errors"):
		var errors = data.get("errors", [])
		print("AuthManager: Validation errors - ", errors)
		if errors.size() > 0:
			error_message = "Erreur de validation: " + str(errors[0])
	elif data.has("error"):
		error_message = data.get("error", "Erreur inconnue")
		if data.has("message"):
			error_message += ": " + data.get("message")
	
	print("AuthManager: Error - ", error_message)
	
	# Le backend renvoie maintenant des erreurs plus génériques
	# On peut se fier au code de la requête pour différencier login/register
	# Pour l'instant, on émet sur les deux.
	register_failed.emit(error_message)
	login_failed.emit(error_message)

func _validate_registration_data(username: String, email: String, password: String, confirm_password: String) -> String:
	"""Valide les données d'inscription côté client"""
	
	# Validation du nom d'utilisateur selon les nouvelles règles
	var username_error = _validate_username(username)
	if username_error != "":
		return username_error
	
	# Validation de l'email
	if not _is_valid_email(email):
		return "Format d'email invalide"
	
	# Validation du mot de passe
	if password.length() < 8:
		return "Le mot de passe doit contenir au moins 8 caractères"
	
	if password != confirm_password:
		return "Les mots de passe ne correspondent pas"
	
	# Vérifier la force du mot de passe
	if not _is_strong_password(password):
		return "Le mot de passe doit contenir au moins une majuscule, une minuscule, un chiffre et un caractère spécial"
	
	return ""

func _validate_username(username: String) -> String:
	"""Valide le nom d'utilisateur selon les règles"""
	
	if username.length() < 4:
		return "Le nom d'utilisateur doit faire au moins 4 caractères"
	if username.length() > 20:
		return "Le nom d'utilisateur ne doit pas dépasser 20 caractères"
	
	# Vérifier les caractères autorisés
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z][a-z0-9-]*$")
	if not regex.search(username):
		return "Le nom d'utilisateur doit commencer par une lettre et ne peut contenir que des lettres minuscules, des chiffres et des tirets"
	
	# Vérifier les tirets
	var hyphen_count = 0
	for i in range(username.length()):
		if username[i] == "-":
			hyphen_count += 1
			if i == 0 or i == username.length() - 1:
				return "Le tiret ne peut pas être au début ou à la fin"
	if hyphen_count > 2:
		return "Maximum 2 tirets autorisés"
	
	# Vérifier les lettres consécutives identiques
	for i in range(username.length() - 2):
		if username[i] == username[i + 1] and username[i] == username[i + 2]:
			return "Maximum 2 lettres identiques consécutives autorisées"
	
	return ""

func _validate_email(email: String) -> String:
	"""Valide l'adresse email"""
	
	if email.strip_edges() == "":
		return "L'email est requis"
	
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
	if not regex.search(email):
		return "Format d'email invalide"
	
	return ""

func _validate_password(password: String) -> String:
	"""Valide le mot de passe"""
	if password.length() < 8:
		return "Le mot de passe doit faire au moins 8 caractères"

	var has_upper = false
	var has_lower = false
	var has_digit = false
	var has_special = false

	var alphanum_regex = RegEx.new()
	alphanum_regex.compile("^[a-zA-Z0-9]$")

	for c in password:
		if c == c.to_upper() and c != c.to_lower() and not c.is_valid_int():
			has_upper = true
		elif c == c.to_lower() and c != c.to_upper() and not c.is_valid_int():
			has_lower = true
		elif c.is_valid_int():
			has_digit = true
		elif not alphanum_regex.search(c):
			has_special = true

	var missing = []
	if not has_upper:
		missing.append("une majuscule")
	if not has_lower:
		missing.append("une minuscule")
	if not has_digit:
		missing.append("un chiffre")
	if not has_special:
		missing.append("un caractère spécial")

	if missing.size() > 0:
		return "Le mot de passe doit contenir " + ", ".join(missing)

	return ""

func _is_valid_email(email: String) -> bool:
	"""Vérifie si l'email a un format valide"""
	var email_regex = RegEx.new()
	email_regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
	return email_regex.search(email) != null

func _is_strong_password(password: String) -> bool:
	"""Vérifie si le mot de passe est suffisamment fort"""
	var has_lower = false
	var has_upper = false
	var has_digit = false
	var has_special = false
	var special_chars = "@$!%*?&"
	
	for i in password.length():
		var current_char = password[i]
		if current_char >= 'a' and current_char <= 'z':
			has_lower = true
		elif current_char >= 'A' and current_char <= 'Z':
			has_upper = true
		elif current_char >= '0' and current_char <= '9':
			has_digit = true
		elif special_chars.find(current_char) != -1:
			has_special = true
	
	return has_lower and has_upper and has_digit and has_special

# =============================
# PERSISTENCE LOCALE CHIFFRÉE
# =============================
func _save_tokens():
	if not _should_remember:
		return
	var data = {
		"access": _access_token,
		"refresh": _refresh_token
	}
	var json_str = JSON.stringify(data)
	var enc = _encrypt_local(json_str)
	var file = FileAccess.open("user://tokens.dat", FileAccess.WRITE)
	file.store_string(enc)
	file.close()

func _load_saved_tokens():
	if not FileAccess.file_exists("user://tokens.dat"):
		return
	var file = FileAccess.open("user://tokens.dat", FileAccess.READ)
	var enc = file.get_as_text()
	file.close()
	var json_str = _decrypt_local(enc)
	if json_str == "":
		return
	var obj = JSON.parse_string(json_str)
	if typeof(obj) == TYPE_DICTIONARY:
		_access_token = obj.get("access", "")
		_refresh_token = obj.get("refresh", "")
		_is_authenticated = _access_token != ""

# =============================
# UTILS PADDING PKCS7 POUR AES
# =============================
func _pkcs7_pad(data: PackedByteArray, block_size: int = 16) -> PackedByteArray:
	var pad_len = block_size - (data.size() % block_size)
	if pad_len == 0:
		pad_len = block_size
	var padded = data.duplicate()
	for i in range(pad_len):
		padded.append(pad_len)
	return padded

func _pkcs7_unpad(data: PackedByteArray) -> PackedByteArray:
	if data.size() == 0:
		return data
	var pad_len = data[data.size() - 1]
	if pad_len > 16 or pad_len > data.size():
		return data # sécurité : padding incohérent
	return data.slice(0, data.size() - pad_len)

func _encrypt_local(plaintext: String) -> String:
	# Chiffrement AES-256-CBC compatible Godot 4 avec padding PKCS7
	var key: PackedByteArray = _LOCAL_AES_KEY.to_utf8_buffer()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var iv_bytes := PackedByteArray()
	for _i in range(16):
		iv_bytes.append(rng.randi_range(0, 255))
	var aes := AESContext.new()
	aes.start(AESContext.MODE_CBC_ENCRYPT, key, iv_bytes)
	var plain_bytes = plaintext.to_utf8_buffer()
	plain_bytes = _pkcs7_pad(plain_bytes, 16)
	var cipher := aes.update(plain_bytes)
	aes.finish()
	return Marshalls.raw_to_base64(iv_bytes + cipher)

func _decrypt_local(cipher_b64: String) -> String:
	var data := Marshalls.base64_to_raw(cipher_b64)
	if data.size() < 16:
		return ""
	var iv_bytes := data.slice(0, 16)
	var cipher := data.slice(16, data.size())
	var aes := AESContext.new()
	aes.start(AESContext.MODE_CBC_DECRYPT, _LOCAL_AES_KEY.to_utf8_buffer(), iv_bytes)
	var plain := aes.update(cipher)
	aes.finish()
	plain = _pkcs7_unpad(plain)
	return plain.get_string_from_utf8()

# =============================
# AUTO-REFRESH TOKEN
# =============================
func _on_refresh_timer_timeout():
	if _access_token == "" or _refresh_token == "":
		return
	# Vérifier expiration dans 10 min
	var payload = get_jwt_payload()
	if payload.is_empty():
		return
	var exp_ts = int(payload.get("exp", 0))
	var now_ts = Time.get_unix_time_from_system()
	if exp_ts - now_ts < 900: # moins de 15 min
		_refresh_token_request()

func _refresh_token_request():
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"refresh_token": _refresh_token})
	_http_request.request(_server_base_url + "/token/refresh", headers, HTTPClient.METHOD_POST, body)

# ===================================================================
# MÉTHODES PRIVÉES
# ===================================================================

func _clear_auth_data():
	"""Nettoie toutes les données d'authentification"""
	_access_token = ""
	_refresh_token = ""
	_player_data = {}
	_is_authenticated = false
	
	# Supprimer le fichier de sauvegarde des tokens
	if FileAccess.file_exists("user://tokens.dat"):
		var dir = DirAccess.open("user://")
		dir.remove("tokens.dat")
		print("AuthManager: Tokens file deleted")
	
	# Supprimer l'ancien fichier de sauvegarde si il existe
	if FileAccess.file_exists("user://auth_data.save"):
		var dir = DirAccess.open("user://")
		dir.remove("auth_data.save")
	
	print("AuthManager: Authentication data cleared") 

func force_logout():
	"""Force la déconnexion et nettoie toutes les données"""
	print("AuthManager: Force logout initiated")
	_clear_auth_data()
	logout_complete.emit() 
