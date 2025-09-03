package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"go-book-api/app/book/model"

	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// Config holds application configuration
type Config struct {
	Port     string
	DBHost   string
	DBPort   string
	DBUser   string
	DBPass   string
	DBName   string
	LogLevel string
}

// Database instance
var db *gorm.DB

// loadConfig loads configuration from environment variables
func loadConfig() *Config {
	// Load environment variables from .env file
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	config := &Config{
		Port:     getEnv("PORT", "8080"),
		DBHost:   getEnv("DB_HOST", "localhost"),
		DBPort:   getEnv("DB_PORT", "3306"),
		DBUser:   getEnv("DB_USER", "root"),
		DBPass:   getEnv("DB_PASS", "1234"),
		DBName:   getEnv("DB_NAME", "bookdb"),
		LogLevel: getEnv("LOG_LEVEL", "info"),
	}

	log.Printf("Configuration loaded - Port: %s, DB: %s@%s:%s/%s",
		config.Port, config.DBUser, config.DBHost, config.DBPort, config.DBName)
	return config
}

// getEnv gets an environment variable or returns a default value
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// connectDB establishes connection to MySQL database
func connectDB(config *Config) error {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		config.DBUser, config.DBPass, config.DBHost, config.DBPort, config.DBName)

	var err error
	db, err = gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		return fmt.Errorf("failed to connect to database: %v", err)
	}

	// Auto migrate the schema
	if err := db.AutoMigrate(&model.Book{}); err != nil {
		return fmt.Errorf("failed to migrate database: %v", err)
	}

	log.Println("Database connected and migrated successfully")
	return nil
}

// seedDatabase adds sample data to the database
func seedDatabase() error {
	// Check if books already exist
	var count int64
	db.Model(&model.Book{}).Count(&count)
	if count > 0 {
		log.Println("Database already contains books, skipping seed")
		return nil
	}

	sampleBooks := []model.Book{
		{Title: "The Go Programming Language", Author: "Alan A. A. Donovan", Year: 2015, ISBN: "978-0134190440"},
		{Title: "Clean Code", Author: "Robert C. Martin", Year: 2008, ISBN: "978-0132350884"},
		{Title: "Design Patterns", Author: "Erich Gamma", Year: 1994, ISBN: "978-0201633610"},
	}

	if err := db.Create(&sampleBooks).Error; err != nil {
		return fmt.Errorf("failed to seed database: %v", err)
	}

	log.Printf("Seeded database with %d sample books", len(sampleBooks))
	return nil
}

func main() {
	// Load configuration
	config := loadConfig()

	// Connect to database
	if err := connectDB(config); err != nil {
		log.Fatalf("Database connection failed: %v", err)
	}

	// Seed database with sample data
	if err := seedDatabase(); err != nil {
		log.Printf("Warning: Failed to seed database: %v", err)
	}

	// Initialize router
	r := mux.NewRouter()

	// Define routes
	r.HandleFunc("/api/books", getBooks).Methods("GET")
	r.HandleFunc("/api/books/{id}", getBook).Methods("GET")
	r.HandleFunc("/api/books", createBook).Methods("POST")
	r.HandleFunc("/api/books/{id}", updateBook).Methods("PUT")
	r.HandleFunc("/api/books/{id}", deleteBook).Methods("DELETE")

	// Health check endpoint
	r.HandleFunc("/health", healthCheck).Methods("GET")

	// Validate port configuration
	if _, err := strconv.Atoi(config.Port); err != nil {
		log.Fatalf("Invalid port number: %s", config.Port)
	}

	fmt.Printf("Server starting on port %s...\n", config.Port)
	log.Fatal(http.ListenAndServe(":"+config.Port, r))
}

// getBooks returns all books
func getBooks(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var books []model.Book
	if err := db.Find(&books).Error; err != nil {
		http.Error(w, "Failed to fetch books", http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(books)
}

// getBook returns a specific book by ID
func getBook(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "Invalid book ID", http.StatusBadRequest)
		return
	}

	var book model.Book
	if err := db.First(&book, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			http.Error(w, "Book not found", http.StatusNotFound)
		} else {
			http.Error(w, "Failed to fetch book", http.StatusInternalServerError)
		}
		return
	}

	json.NewEncoder(w).Encode(book)
}

// createBook creates a new book
func createBook(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var book model.Book
	if err := json.NewDecoder(r.Body).Decode(&book); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Validate required fields
	if book.Title == "" || book.Author == "" {
		http.Error(w, "Title and Author are required", http.StatusBadRequest)
		return
	}

	// Check if ISBN already exists
	if book.ISBN != "" {
		var existingBook model.Book
		if err := db.Where("isbn = ?", book.ISBN).First(&existingBook).Error; err == nil {
			http.Error(w, "Book with this ISBN already exists", http.StatusConflict)
			return
		}
	}

	if err := db.Create(&book).Error; err != nil {
		http.Error(w, "Failed to create book", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(book)
}

// updateBook updates an existing book
func updateBook(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "Invalid book ID", http.StatusBadRequest)
		return
	}

	var book model.Book
	if err := db.First(&book, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			http.Error(w, "Book not found", http.StatusNotFound)
		} else {
			http.Error(w, "Failed to fetch book", http.StatusInternalServerError)
		}
		return
	}

	var updatedBook model.Book
	if err := json.NewDecoder(r.Body).Decode(&updatedBook); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Validate required fields
	if updatedBook.Title == "" || updatedBook.Author == "" {
		http.Error(w, "Title and Author are required", http.StatusBadRequest)
		return
	}

	// Check if ISBN already exists (excluding current book)
	if updatedBook.ISBN != "" && updatedBook.ISBN != book.ISBN {
		var existingBook model.Book
		if err := db.Where("isbn = ? AND id != ?", updatedBook.ISBN, id).First(&existingBook).Error; err == nil {
			http.Error(w, "Book with this ISBN already exists", http.StatusConflict)
			return
		}
	}

	// Update the book
	if err := db.Model(&book).Updates(updatedBook).Error; err != nil {
		http.Error(w, "Failed to update book", http.StatusInternalServerError)
		return
	}

	// Fetch the updated book
	if err := db.First(&book, id).Error; err != nil {
		http.Error(w, "Failed to fetch updated book", http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(book)
}

// deleteBook deletes a book by ID
func deleteBook(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "Invalid book ID", http.StatusBadRequest)
		return
	}

	var book model.Book
	if err := db.First(&book, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			http.Error(w, "Book not found", http.StatusNotFound)
		} else {
			http.Error(w, "Failed to fetch book", http.StatusInternalServerError)
		}
		return
	}

	if err := db.Delete(&book).Error; err != nil {
		http.Error(w, "Failed to delete book", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// healthCheck returns a simple health check response
func healthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Check database connection
	var count int64
	dbStatus := "healthy"
	if err := db.Model(&model.Book{}).Count(&count).Error; err != nil {
		dbStatus = "unhealthy"
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":    "healthy",
		"message":   "Book API is running",
		"database":  dbStatus,
		"timestamp": time.Now().Format(time.RFC3339),
	})
}
