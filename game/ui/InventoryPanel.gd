extends PanelContainer

## GESTIONNAIRE D'INVENTAIRE STYLE DOFUS 1.29
## ===========================================
## Interface d'inventaire avec grille d'objets, slots d'équipement, et communication serveur.

## CONSTANTES
## ===========
const INVENTORY_SLOTS = 60  # 6x10 grille comme Dofus
const EQUIPMENT_SLOTS = ["HEAD", "CHEST", "WEAPON", "AMULET", "RING", "BELT", "BOOTS", "PET", "MOUNT"]

## VARIABLES D'ÉTAT
## =================
var is_visible = false
var character_id: String = ""
var inventory_data: Dictionary = {}
var dragging_item: Dictionary = {}
var drag_source_slot = null

## RÉFÉRENCES AUX NŒUDS UI
## ========================
var inventory_grid: GridContainer
var equipment_slots: Dictionary = {}
var item_tooltip: Control
var loading_label: Label
var character_stats: Dictionary = {}

## INITIALISATION
## ===============
func _ready():
	print("[Inventory] === INITIALISATION INVENTAIRE ===")
	
	# Configuration initiale
	if not _setup_ui_references():
		push_error("[Inventory] Échec de l'initialisation des références UI")
		return
	_setup_drag_and_drop()
	_load_character_info()
	
	# Masquer initialement
	visible = false
	
	print("[Inventory] Inventaire initialisé.")

## CONFIGURATION DES RÉFÉRENCES UI
## ================================
func _setup_ui_references():
	"""Configure les références vers les nœuds UI."""
	# Grille d'inventaire principal
	inventory_grid = get_node_or_null("VBox/MainHBox/InventoryArea/ScrollContainer/InventoryGrid")
	if not inventory_grid:
		push_error("[Inventory] ❌ InventoryGrid non trouvé - vérifiez la structure de InventoryPanel.tscn")
		return false
	
	# Area des équipements
	var equipment_area = get_node_or_null("VBox/MainHBox/EquipmentArea")
	if equipment_area:
		for slot_name in EQUIPMENT_SLOTS:
			var slot_node = equipment_area.get_node_or_null(slot_name + "Slot")
			if slot_node:
				equipment_slots[slot_name] = slot_node
	
	# Tooltip et loading
	item_tooltip = get_node_or_null("ItemTooltip")
	loading_label = get_node_or_null("VBox/LoadingLabel")
	
	# Bouton fermeture
	var close_btn = get_node_or_null("VBox/TitleBar/CloseButton")
	if close_btn:
		close_btn.pressed.connect(_on_close_button_pressed)

## CONFIGURATION DRAG & DROP
## ==========================
func _setup_drag_and_drop():
	"""Configure le système de glisser-déposer."""
	# Configuration des slots d'inventaire
	if inventory_grid:
		for i in range(INVENTORY_SLOTS):
			var slot = _create_inventory_slot(i)
			inventory_grid.add_child(slot)
	
	# Configuration des slots d'équipement
	for slot_name in equipment_slots:
		var slot_node = equipment_slots[slot_name]
		_setup_equipment_slot(slot_node, slot_name)

func _create_inventory_slot(index: int) -> Control:
	"""Crée un slot d'inventaire."""
	var slot = Panel.new()
	slot.name = "InventorySlot_" + str(index)
	slot.custom_minimum_size = Vector2(48, 48)
	slot.set_script(load("res://game/ui/ItemSlot.gd"))
	
	# Configuration du slot
	if slot.has_method("setup_slot"):
		slot.setup_slot("inventory", index)
		slot.slot_clicked.connect(_on_inventory_slot_clicked)
		slot.item_dragged.connect(_on_item_drag_started)
		slot.item_dropped.connect(_on_item_dropped)
	
	return slot

func _setup_equipment_slot(slot_node: Control, slot_type: String):
	"""Configure un slot d'équipement."""
	if slot_node and slot_node.has_method("setup_slot"):
		slot_node.setup_slot("equipment", slot_type)
		slot_node.slot_clicked.connect(_on_equipment_slot_clicked)
		slot_node.item_dragged.connect(_on_item_drag_started)
		slot_node.item_dropped.connect(_on_item_dropped)

## CHARGEMENT DES DONNÉES
## =======================
func _load_character_info():
	"""Charge l'ID du personnage depuis AuthManager."""
	# Debug: voir ce qu'il y a dans le JWT
	var payload = AuthManager.get_jwt_payload()
	print("[Inventory] Payload JWT: ", payload)
	
	var char_id = AuthManager.get_character_id()
	if char_id > 0:
		character_id = str(char_id)
		print("[Inventory] ID personnage trouvé: ", character_id)
	else:
		print("[Inventory] ❌ character_id non trouvé, essai alternatives...")
		
		# Essai alternatif via payload JWT
		if payload.has("user_id"):
			character_id = str(payload.user_id)
			print("[Inventory] ✅ Utilisation user_id comme character_id: ", character_id)
		elif payload.has("sub"):
			character_id = str(payload.sub) 
			print("[Inventory] ✅ Utilisation sub comme character_id: ", character_id)
		else:
			print("[Inventory] ❌ Aucun ID utilisable trouvé")
			character_id = ""

## OUVERTURE/FERMETURE
## ====================
func open_inventory():
	"""Ouvre l'inventaire et charge les données."""
	if character_id.is_empty():
		print("[Inventory] ❌ Impossible d'ouvrir l'inventaire: ID personnage manquant")
		return
	
	print("[Inventory] 📦 Ouverture de l'inventaire")
	is_visible = true
	visible = true
	
	# Afficher loading
	if loading_label:
		loading_label.visible = true
		loading_label.text = "Chargement de l'inventaire..."
	
	# Charger les données depuis le serveur
	_fetch_inventory_data()

func close_inventory():
	"""Ferme l'inventaire."""
	print("[Inventory] 📦 Fermeture de l'inventaire")
	is_visible = false
	visible = false

func toggle_inventory():
	"""Bascule l'état d'ouverture/fermeture."""
	if is_visible:
		close_inventory()
	else:
		open_inventory()

## COMMUNICATION SERVEUR
## ======================
func _fetch_inventory_data():
	"""Récupère les données d'inventaire depuis le serveur."""
	var url = "%s/inventory/%s" % [ServerConfig.API_URL, character_id]
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + AuthManager.get_access_token()
	]
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_inventory_data_received.bind(http_request))
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		print("[Inventory] ❌ Erreur lors de la requête inventaire: ", error)
		_show_error("Erreur de connexion au serveur")
		http_request.queue_free()

func _on_inventory_data_received(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, request_node: HTTPRequest):
	"""Traite les données d'inventaire reçues."""
	if loading_label:
		loading_label.visible = false
	
	if response_code == 200:
		var response_data = JSON.parse_string(body.get_string_from_utf8())
		if response_data and response_data.has("success") and response_data.success:
			inventory_data = response_data.get("inventory", {})
			_update_inventory_display()
			print("[Inventory] ✅ Inventaire chargé avec succès")
		else:
			_show_error("Données d'inventaire invalides")
	else:
		print("[Inventory] ❌ Erreur serveur: ", response_code)
		_show_error("Erreur lors du chargement")
	
	request_node.queue_free()

func _update_inventory_display():
	"""Met à jour l'affichage de l'inventaire."""
	if not inventory_data:
		return
	
	# Vider les slots actuels
	_clear_all_slots()
	
	# Afficher les objets de l'inventaire
	var items = inventory_data.get("items", [])
	for item in items:
		_display_item_in_inventory(item)
	
	# Afficher les équipements
	var equipment = inventory_data.get("equipment", {})
	for slot_name in equipment:
		var equipped_item = equipment[slot_name]
		_display_item_in_equipment(equipped_item, slot_name)

func _display_item_in_inventory(item: Dictionary):
	"""Affiche un objet dans la grille d'inventaire."""
	# Trouver le premier slot libre
	for i in range(INVENTORY_SLOTS):
		var slot = inventory_grid.get_child(i)
		if slot and slot.has_method("is_empty") and slot.is_empty():
			if slot.has_method("set_item"):
				slot.set_item(item)
			break

func _display_item_in_equipment(item: Dictionary, slot_name: String):
	"""Affiche un objet équipé."""
	if equipment_slots.has(slot_name):
		var slot = equipment_slots[slot_name]
		if slot and slot.has_method("set_item"):
			slot.set_item(item)

func _clear_all_slots():
	"""Vide tous les slots de l'inventaire."""
	# Vider inventaire
	if inventory_grid:
		for i in range(inventory_grid.get_child_count()):
			var slot = inventory_grid.get_child(i)
			if slot and slot.has_method("clear_item"):
				slot.clear_item()
	
	# Vider équipements
	for slot_name in equipment_slots:
		var slot = equipment_slots[slot_name]
		if slot and slot.has_method("clear_item"):
			slot.clear_item()

## GESTION DES ÉQUIPEMENTS
## ========================
func _equip_item(item_id: String, slot: String):
	"""Équipe un objet."""
	var url = "%s/inventory/%s/equip" % [ServerConfig.API_URL, character_id]
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + AuthManager.get_access_token()
	]
	
	var body = {
		"item_id": item_id,
		"slot": slot
	}
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_equip_response.bind(http_request))
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		print("[Inventory] ❌ Erreur lors de l'équipement: ", error)
		http_request.queue_free()

func _unequip_item(slot: String):
	"""Déséquipe un objet."""
	var url = "%s/inventory/%s/unequip" % [ServerConfig.API_URL, character_id]
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + AuthManager.get_access_token()
	]
	
	var body = {
		"slot": slot
	}
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_unequip_response.bind(http_request))
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		print("[Inventory] ❌ Erreur lors du déséquipement: ", error)
		http_request.queue_free()

func _on_equip_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, request_node: HTTPRequest):
	"""Traite la réponse d'équipement."""
	if response_code == 200:
		var response_data = JSON.parse_string(body.get_string_from_utf8())
		if response_data and response_data.has("success") and response_data.success:
			print("[Inventory] ✅ Objet équipé avec succès")
			# Rafraîchir l'inventaire
			_fetch_inventory_data()
			# Notifier le HUD pour mettre à jour les stats
			_notify_stats_changed(response_data.get("stats", {}))
		else:
			_show_error("Impossible d'équiper cet objet")
	else:
		print("[Inventory] ❌ Erreur équipement: ", response_code)
		_show_error("Erreur lors de l'équipement")
	
	request_node.queue_free()

func _on_unequip_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, request_node: HTTPRequest):
	"""Traite la réponse de déséquipement."""
	if response_code == 200:
		var response_data = JSON.parse_string(body.get_string_from_utf8())
		if response_data and response_data.has("success") and response_data.success:
			print("[Inventory] ✅ Objet déséquipé avec succès")
			# Rafraîchir l'inventaire
			_fetch_inventory_data()
			# Notifier le HUD pour mettre à jour les stats
			_notify_stats_changed(response_data.get("stats", {}))
		else:
			_show_error("Impossible de déséquiper cet objet")
	else:
		print("[Inventory] ❌ Erreur déséquipement: ", response_code)
		_show_error("Erreur lors du déséquipement")
	
	request_node.queue_free()

## GESTION DES ÉVÉNEMENTS
## =======================
func _on_inventory_slot_clicked(slot_index: int, item_data: Dictionary):
	"""Gère le clic sur un slot d'inventaire."""
	print("[Inventory] Clic sur slot inventaire: ", slot_index, " - ", item_data)
	
	if item_data.is_empty():
		return
	
	# Double-clic pour équiper automatiquement
	if Input.is_action_just_pressed("ui_accept"):
		_auto_equip_item(item_data)

func _on_equipment_slot_clicked(slot_name: String, item_data: Dictionary):
	"""Gère le clic sur un slot d'équipement."""
	print("[Inventory] Clic sur slot équipement: ", slot_name, " - ", item_data)
	
	# Double-clic pour déséquiper
	if Input.is_action_just_pressed("ui_accept"):
		_unequip_item(slot_name)

func _on_item_drag_started(item_data: Dictionary, source_slot):
	"""Démarre le glisser-déposer d'un objet."""
	dragging_item = item_data
	drag_source_slot = source_slot
	print("[Inventory] Début drag&drop: ", item_data.get("name", "Unknown"))

func _on_item_dropped(target_slot):
	"""Termine le glisser-déposer d'un objet."""
	if dragging_item.is_empty():
		return
	
	print("[Inventory] Fin drag&drop vers: ", target_slot)
	
	# Logique selon le type de slot cible
	if target_slot.has_method("get_slot_type"):
		var slot_type = target_slot.get_slot_type()
		var slot_id = target_slot.get_slot_id()
		
		match slot_type:
			"equipment":
				# Équiper l'objet
				_equip_item(dragging_item.get("id", ""), slot_id)
			"inventory":
				# Déplacer dans l'inventaire (réorganisation)
				_move_item_in_inventory(dragging_item, slot_id)
	
	# Nettoyer
	dragging_item.clear()
	drag_source_slot = null

func _on_close_button_pressed():
	"""Ferme l'inventaire."""
	close_inventory()

## FONCTIONS UTILITAIRES
## ======================
func _auto_equip_item(item_data: Dictionary):
	"""Équipe automatiquement un objet dans le bon slot."""
	var item_template = item_data.get("item_template", {})
	var item_type = item_template.get("item_type", "")
	
	# Déterminer le slot approprié selon le type d'objet
	var target_slot = _get_appropriate_slot(item_type)
	if not target_slot.is_empty():
		_equip_item(item_data.get("id", ""), target_slot)

func _get_appropriate_slot(item_type: String) -> String:
	"""Retourne le slot approprié pour un type d'objet."""
	match item_type:
		"WEAPON":
			return "WEAPON"
		"EQUIPMENT":
			return "CHEST"  # Par défaut, à améliorer avec plus de détails
		_:
			return ""

func _move_item_in_inventory(item_data: Dictionary, target_index: int):
	"""Déplace un objet dans l'inventaire (réorganisation)."""
	# Pour l'instant, simplement rafraîchir l'affichage
	# Cette fonction pourrait envoyer une requête au serveur pour sauvegarder l'ordre
	print("[Inventory] Réorganisation inventaire: ", item_data.get("name", ""), " -> slot ", target_index)

func _notify_stats_changed(new_stats: Dictionary):
	"""Notifie le HUD que les stats ont changé."""
	var hud = get_node_or_null("/root/Main/MainUI/HUD")
	if hud and hud.has_method("update_character_data"):
		var character_data = {"stats": new_stats}
		hud.update_character_data(character_data)

func _show_error(message: String):
	"""Affiche un message d'erreur."""
	print("[Inventory] ❌ ", message)
	# TODO: Afficher une popup d'erreur à l'utilisateur
	if loading_label:
		loading_label.visible = true
		loading_label.text = "Erreur: " + message

## MÉTHODES PUBLIQUES
## ===================
func refresh_inventory():
	"""Rafraîchit l'inventaire depuis le serveur."""
	if is_visible:
		_fetch_inventory_data()

func get_inventory_data() -> Dictionary:
	"""Retourne les données d'inventaire actuelles."""
	return inventory_data

## RACCOURCIS CLAVIER
## ===================
func _input(event):
	"""Gère les raccourcis clavier pour l'inventaire."""
	if not is_visible:
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				close_inventory()
			KEY_R:
				refresh_inventory()