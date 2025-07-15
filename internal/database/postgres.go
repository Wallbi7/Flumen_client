package database

import (
	"context"
	"time"
)

type User struct {
	ID             string    `db:"id"`
	Username       string    `db:"username"`
	Email          string    `db:"email"`
	PasswordHash   string    `db:"password_hash"`
	CharacterClass string    `db:"character_class"`
	CreatedAt      time.Time `db:"created_at"`
	UpdatedAt      time.Time `db:"updated_at"`
}

func (db *PostgresDB) CreateUser(ctx context.Context, user *User) error {
	query := `
		INSERT INTO users (username, email, password_hash, character_class)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at, updated_at`

	err := db.pool.QueryRow(ctx, query, user.Username, user.Email, user.PasswordHash, user.CharacterClass).Scan(&user.ID, &user.CreatedAt, &user.UpdatedAt)
	return err
}

func (db *PostgresDB) GetUserByEmail(ctx context.Context, email string) (*User, error) {
	user := &User{}
	query := "SELECT id, username, email, password_hash, character_class FROM users WHERE email = $1"
	err := db.pool.QueryRow(ctx, query, email).Scan(&user.ID, &user.Username, &user.Email, &user.PasswordHash, &user.CharacterClass)
	if err != nil {
		return nil, err
	}
	return user, nil
}

func (db *PostgresDB) GetUserByUsername(ctx context.Context, username string) (*User, error) {
	user := &User{}
	query := "SELECT id, username, email, password_hash, character_class FROM users WHERE username = $1"
	err := db.pool.QueryRow(ctx, query, username).Scan(&user.ID, &user.Username, &user.Email, &user.PasswordHash, &user.CharacterClass)
	if err != nil {
		return nil, err
	}
	return user, nil
}
