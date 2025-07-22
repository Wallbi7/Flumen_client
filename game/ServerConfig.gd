extends Node

# Configuration du serveur
var server_domain = "127.0.0.1"  # Changé de localhost à 127.0.0.1 pour éviter les problèmes DNS
var server_port = 9090
var api_base_path = "/api/v1"
var auth_url = "http://%s:%d%s" % [server_domain, server_port, api_base_path]
var websocket_url = "ws://%s:%d/ws/game" % [server_domain, server_port]

# Configuration de fallback
var fallback_domain = "localhost"
var fallback_auth_url = "http://%s:%d%s" % [fallback_domain, server_port, api_base_path]
var fallback_websocket_url = "ws://%s:%d/ws/game" % [fallback_domain, server_port]

# Fonction pour mettre à jour toutes les URLs en cas de changement de port
func update_urls():
	auth_url = "http://%s:%d%s" % [server_domain, server_port, api_base_path]
	websocket_url = "ws://%s:%d/ws/game" % [server_domain, server_port]

# Fonction pour basculer vers le serveur de fallback
func use_fallback_server():
	print("ServerConfig: Basculement vers le serveur de fallback (localhost)")
	server_domain = fallback_domain
	auth_url = fallback_auth_url
	websocket_url = fallback_websocket_url
	update_urls()

# Fonction pour vérifier la disponibilité du serveur
func check_server_status():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	# On pourrait ajouter un endpoint /health sur le backend pour un vrai check
	http_request.request(auth_url + "/login") 
	return true

# URL de base pour toutes les requêtes API.
# Doit pointer vers votre serveur Go.
const API_URL = "http://127.0.0.1:9090/api/v1"  # Changé de localhost à 127.0.0.1 et port 9090 
