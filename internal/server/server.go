package server

import (
	"context"
	"flumen_server/internal/auth"
	"flumen_server/internal/database"
	"flumen_server/internal/network"

	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5"
	"golang.org/x/crypto/bcrypt"
)

// Structures pour les requêtes
type RegisterRequest struct {
	Username       string `json:"username"`
	Email          string `json:"email"`
	Password       string `json:"password"`
	CharacterClass string `json:"characterClass"`
}

type LoginRequest struct {
	Identifier string `json:"identifier"` // Peut être un email ou un username
	Password   string `json:"password"`
}

func (s *Server) Start(ctx context.Context, networkManager *network.Manager) error {
	// ...
	// Routes d'authentification
	authGroup := s.app.Group("/auth")
	authGroup.Post("/register", s.registerHandler)
	authGroup.Post("/login", s.loginHandler)

	// Route WebSocket pour le jeu
	s.app.Get("/game", networkManager.HandleWebSocket) // ...
}

// registerHandler gère l'inscription d'un nouvel utilisateur.
func (s *Server) registerHandler(c *fiber.Ctx) error {
	req := new(RegisterRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Cannot parse JSON"})
	}

	// TODO: Ajouter une validation plus robuste pour les entrées

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		s.logger.Error().Err(err).Msg("Failed to hash password")
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
	}

	newUser := &database.User{
		Username:       req.Username,
		Email:          req.Email,
		PasswordHash:   string(hashedPassword),
		CharacterClass: req.CharacterClass,
	}

	if err := s.db.CreateUser(c.Context(), newUser); err != nil {
		s.logger.Error().Err(err).Msg("Failed to create user")
		// TODO: Gérer les erreurs de duplications (username/email)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not create user"})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"message": "User created successfully"})
}

// loginHandler gère la connexion d'un utilisateur existant.
func (s *Server) loginHandler(c *fiber.Ctx) error {
	req := new(LoginRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Cannot parse JSON"})
	}

	// Déterminer si l'identifiant est un email ou un username
	user, err := s.db.GetUserByEmail(c.Context(), req.Identifier)
	if err == pgx.ErrNoRows {
		user, err = s.db.GetUserByUsername(c.Context(), req.Identifier)
	}

	if err != nil {
		if err == pgx.ErrNoRows {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid credentials"})
		}
		s.logger.Error().Err(err).Msg("Failed to get user")
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
	}

	// Comparer le mot de passe
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid credentials"})
	}

	// Générer les tokens
	accessToken, refreshToken, err := auth.GenerateTokens(user.ID, user.Username, s.config.JWTSecret)
	if err != nil {
		s.logger.Error().Err(err).Msg("Failed to generate tokens")
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
	}

	return c.JSON(fiber.Map{
		"accessToken":  accessToken,
		"refreshToken": refreshToken,
		"user": fiber.Map{
			"id":       user.ID,
			"username": user.Username,
		},
	})
}

// Supprimer les handlers de démo
// func (s *Server) demoLoginHandler(c *fiber.Ctx) error ...
// func (s *Server) demoRegisterHandler(c *fiber.Ctx) error ...
