extends Control

# Références aux contrôles UI
@onready var auth_manager = AuthManager
@onready var tab_container = $LoginPanel/VBoxContainer/TabContainer
@onready var version_label = $LoginPanel/VBoxContainer/VersionLabel
@onready var request_timer = $RequestTimer

# Onglet Connexion
@onready var login_identifier = $LoginPanel/VBoxContainer/TabContainer/Connexion/VBoxContainer/IdentifierInput
@onready var login_password = $LoginPanel/VBoxContainer/TabContainer/Connexion/VBoxContainer/PasswordInput
@onready var login_remember = $LoginPanel/VBoxContainer/TabContainer/Connexion/VBoxContainer/OptionsContainer/RememberCheckBox
@onready var login_button = $LoginPanel/VBoxContainer/TabContainer/Connexion/VBoxContainer/LoginButton
@onready var login_status = $LoginPanel/VBoxContainer/TabContainer/Connexion/VBoxContainer/StatusLabel
@onready var create_account_button = $LoginPanel/VBoxContainer/TabContainer/Connexion/VBoxContainer/CreateAccountButton
@onready var forgot_password_button = $LoginPanel/VBoxContainer/TabContainer/Connexion/VBoxContainer/OptionsContainer/ForgotPasswordButton

# Onglet Inscription
@onready var register_username = $LoginPanel/VBoxContainer/TabContainer/Inscription/VBoxContainer/UsernameInput
@onready var register_email = $LoginPanel/VBoxContainer/TabContainer/Inscription/VBoxContainer/EmailInput
@onready var register_password = $LoginPanel/VBoxContainer/TabContainer/Inscription/VBoxContainer/PasswordInput
@onready var register_confirm = $LoginPanel/VBoxContainer/TabContainer/Inscription/VBoxContainer/ConfirmPasswordInput
@onready var register_accept_terms = $LoginPanel/VBoxContainer/TabContainer/Inscription/VBoxContainer/AcceptTermsCheckBox
@onready var register_button = $LoginPanel/VBoxContainer/TabContainer/Inscription/VBoxContainer/RegisterButton
@onready var register_status = $LoginPanel/VBoxContainer/TabContainer/Inscription/VBoxContainer/StatusLabel
@onready var back_to_login_button = $LoginPanel/VBoxContainer/TabContainer/Inscription/VBoxContainer/BackToLoginButton

func _ready():
	print("LoginScene: Initializing...")
	
	# Les signaux de l'AuthManager sont toujours nécessaires
	auth_manager.login_success.connect(_on_login_success)
	auth_manager.login_failed.connect(_on_login_failed)
	auth_manager.register_success.connect(_on_register_success)
	auth_manager.register_failed.connect(_on_register_failed)
	
	# La connexion du timer est aussi nécessaire car elle est dans le code
	request_timer.timeout.connect(_on_request_timeout)
	
	# Le reste des connexions (boutons, etc.) sont maintenant dans le .tscn
	
	# Afficher l'adresse du serveur dans le label de version
	version_label.text = "Version 1.0.0 - Serveur: " + ServerConfig.server_domain + ":" + str(ServerConfig.server_port)
	
	# Afficher l'état de connexion dans le statut
	login_status.text = "Prêt à se connecter"
	login_status.modulate = Color.YELLOW
	
	# Vérifier si le joueur est déjà connecté
	if auth_manager.is_authenticated():
		print("LoginScene: Player already authenticated: ", auth_manager.get_username())
		# Vérifier si le token est vraiment valide en testant une requête
		_validate_existing_token()
	else:
		print("LoginScene: No authentication found, showing login form")

func _on_login_button_pressed():
	"""Gestionnaire du bouton de connexion"""
	
	var identifier = login_identifier.text.strip_edges()
	var password = login_password.text
	var remember_me = login_remember.button_pressed
	
	if identifier == "" or password == "":
		login_status.text = "Veuillez remplir tous les champs"
		login_status.modulate = Color.RED
		return
	
	login_status.text = "Connexion en cours..."
	request_timer.start()
	auth_manager.login(identifier, password, remember_me)

func _on_register_button_pressed():
	"""Gestionnaire du bouton d'inscription"""
	
	var username = register_username.text.strip_edges()
	var email = register_email.text.strip_edges()
	var password = register_password.text
	var confirm_password = register_confirm.text
	var accept_terms = register_accept_terms.button_pressed
	
	# Debug pour voir les valeurs récupérées
	print("DEBUG accept_terms:", accept_terms)
	print("DEBUG confirm_password:", confirm_password)
	print("DEBUG username:", username)
	
	# Classe par défaut pour simplifier l'inscription
	var character_class = "adventurer"
	
	if username == "" or email == "" or password == "" or confirm_password == "":
		register_status.text = "Veuillez remplir tous les champs"
		register_status.modulate = Color.RED
		return
	
	if not accept_terms:
		register_status.text = "Vous devez accepter les conditions d'utilisation"
		register_status.modulate = Color.RED
		return
	
	register_status.text = "Création du compte en cours..."
	request_timer.start()
	auth_manager.register(username, email, password, confirm_password, character_class, accept_terms)

func _on_login_success(_player_data: Dictionary):
	"""Appelé quand la connexion réussit"""
	request_timer.stop()
	print("LoginScene: Login successful for user.")
	login_status.text = "Connexion réussie ! Bienvenue !"
	login_status.modulate = Color.GREEN
	
	# Transitionner vers la scène principale
	_go_to_game()

func _on_login_failed(error_message: String):
	request_timer.stop()
	"""Appelé quand la connexion échoue"""
	
	print("LoginScene: Login failed: ", error_message)
	login_status.text = "Erreur: " + error_message
	login_status.modulate = Color.RED
	login_button.disabled = false

func _on_register_success(_player_data: Dictionary):
	"""Appelé quand l'inscription réussit"""
	request_timer.stop()
	print("LoginScene: Registration successful.")
	register_status.text = "Inscription réussie ! Vous pouvez maintenant vous connecter."
	register_status.modulate = Color.GREEN
	
	# Basculer vers l'onglet de connexion pour que l'utilisateur puisse se connecter
	tab_container.current_tab = 0

func _on_register_failed(error_message: String):
	request_timer.stop()
	"""Appelé quand l'inscription échoue"""
	
	print("LoginScene: Registration failed: ", error_message)
	register_status.text = "Erreur: " + error_message
	register_status.modulate = Color.RED
	register_button.disabled = false

func _go_to_game():
	print("LoginScene: Transitioning to character selection scene...")
	# Rediriger vers la sélection de personnages au lieu du jeu directement
	get_tree().call_deferred("change_scene_to_file", "res://game/ui/CharacterSelection.tscn")

# Gestionnaires pour les nouveaux boutons
func _on_create_account_button_pressed():
	"""Passer à l'onglet inscription"""
	tab_container.current_tab = 1

func _on_back_to_login_button_pressed():
	"""Retour à l'onglet connexion"""
	tab_container.current_tab = 0

func _on_forgot_password_button_pressed():
	"""Gestionnaire pour mot de passe oublié"""
	print("LoginScene: Forgot password clicked")
	# TODO: Implémenter la récupération de mot de passe
	login_status.text = "Fonctionnalité bientôt disponible"
	login_status.modulate = Color.YELLOW 

func _input(event):
	"""Gestionnaire d'entrée pour les raccourcis clavier"""
	if event is InputEventKey and event.pressed:
		# Ctrl+Shift+L pour forcer la déconnexion (debug)
		if event.ctrl_pressed and event.shift_pressed and event.keycode == KEY_L:
			print("LoginScene: Force logout triggered by hotkey")
			auth_manager.force_logout()
			login_status.text = "Déconnexion forcée - Données nettoyées"
			login_status.modulate = Color.GREEN 

func _on_request_timeout():
	login_status.text = "Le serveur ne répond pas."
	login_status.modulate = Color.RED
	register_status.text = "Le serveur ne répond pas."
	register_status.modulate = Color.RED
	print("LoginScene: Request timed out.") 

func _validate_existing_token():
	"""Valide le token existant en testant une requête vers le serveur"""
	print("LoginScene: Validating existing token...")
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_token_validation_completed)
	
	var headers = auth_manager.get_auth_header()
	var api_url = ServerConfig.API_URL
	var err = http_request.request(api_url + "/characters", headers, HTTPClient.METHOD_GET)
	
	if err != OK:
		print("LoginScene: Failed to validate token, clearing auth data")
		auth_manager.force_logout()

func _on_token_validation_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	"""Gestionnaire de validation du token"""
	
	print("LoginScene: Token validation response code: ", response_code)
	
	if response_code == 200:
		print("LoginScene: Token is valid, proceeding to game")
		_go_to_game()
	else:
		print("LoginScene: Token is invalid (code: ", response_code, "), clearing auth data")
		var response_text = body.get_string_from_utf8()
		print("LoginScene: Error response: ", response_text)
		
		# Nettoyer les données d'authentification
		auth_manager.force_logout()
		
		# Afficher un message à l'utilisateur
		login_status.text = "Session expirée, veuillez vous reconnecter"
		login_status.modulate = Color.YELLOW 
