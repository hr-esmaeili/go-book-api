package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
)

// Book represents a book in our system
type Book struct {
	ID          int       `json:"id"`
	Title       string    `json:"title"`
	Author      string    `json:"author"`
	ISBN        string    `json:"isbn"`
	PublishedAt time.Time `json:"published_at"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// BookStore represents our in-memory storage
type BookStore struct {
	books  map[int]Book
	nextID int
}

// NewBookStore creates a new book store
func NewBookStore() *BookStore {
	return &BookStore{
		books:  make(map[int]Book),
		nextID: 1,
	}
}

// CreateBook adds a new book to the store
func (bs *BookStore) CreateBook(book Book) Book {
	book.ID = bs.nextID
	book.CreatedAt = time.Now()
	book.UpdatedAt = time.Now()
	bs.books[book.ID] = book
	bs.nextID++
	return book
}

// GetBook retrieves a book by ID
func (bs *BookStore) GetBook(id int) (Book, bool) {
	book, exists := bs.books[id]
	return book, exists
}

// GetAllBooks returns all books
func (bs *BookStore) GetAllBooks() []Book {
	books := make([]Book, 0, len(bs.books))
	for _, book := range bs.books {
		books = append(books, book)
	}
	return books
}

// UpdateBook updates an existing book
func (bs *BookStore) UpdateBook(id int, updatedBook Book) (Book, bool) {
	if _, exists := bs.books[id]; !exists {
		return Book{}, false
	}
	updatedBook.ID = id
	updatedBook.CreatedAt = bs.books[id].CreatedAt
	updatedBook.UpdatedAt = time.Now()
	bs.books[id] = updatedBook
	return updatedBook, true
}

// DeleteBook removes a book from the store
func (bs *BookStore) DeleteBook(id int) bool {
	if _, exists := bs.books[id]; !exists {
		return false
	}
	delete(bs.books, id)
	return true
}

// API represents our API handlers
type API struct {
	store *BookStore
}

// NewAPI creates a new API instance
func NewAPI() *API {
	return &API{
		store: NewBookStore(),
	}
}

// JSONResponse represents a standard JSON response
type JSONResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}

// writeJSON writes a JSON response
func writeJSON(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(data)
}

// writeError writes an error response
func writeError(w http.ResponseWriter, statusCode int, message string) {
	response := JSONResponse{
		Success: false,
		Error:   message,
	}
	writeJSON(w, statusCode, response)
}

// writeSuccess writes a success response
func writeSuccess(w http.ResponseWriter, data interface{}) {
	response := JSONResponse{
		Success: true,
		Data:    data,
	}
	writeJSON(w, http.StatusOK, response)
}

// GetBooks handles GET /books
func (api *API) GetBooks(w http.ResponseWriter, r *http.Request) {
	books := api.store.GetAllBooks()
	writeSuccess(w, books)
}

// GetBook handles GET /books/{id}
func (api *API) GetBook(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		writeError(w, http.StatusBadRequest, "Invalid book ID")
		return
	}

	book, exists := api.store.GetBook(id)
	if !exists {
		writeError(w, http.StatusNotFound, "Book not found")
		return
	}

	writeSuccess(w, book)
}

// CreateBook handles POST /books
func (api *API) CreateBook(w http.ResponseWriter, r *http.Request) {
	var book Book
	if err := json.NewDecoder(r.Body).Decode(&book); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid JSON")
		return
	}

	// Validate required fields
	if book.Title == "" || book.Author == "" {
		writeError(w, http.StatusBadRequest, "Title and Author are required")
		return
	}

	createdBook := api.store.CreateBook(book)
	writeJSON(w, http.StatusCreated, JSONResponse{
		Success: true,
		Data:    createdBook,
	})
}

// UpdateBook handles PUT /books/{id}
func (api *API) UpdateBook(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		writeError(w, http.StatusBadRequest, "Invalid book ID")
		return
	}

	var book Book
	if err := json.NewDecoder(r.Body).Decode(&book); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid JSON")
		return
	}

	// Validate required fields
	if book.Title == "" || book.Author == "" {
		writeError(w, http.StatusBadRequest, "Title and Author are required")
		return
	}

	updatedBook, exists := api.store.UpdateBook(id, book)
	if !exists {
		writeError(w, http.StatusNotFound, "Book not found")
		return
	}

	writeSuccess(w, updatedBook)
}

// DeleteBook handles DELETE /books/{id}
func (api *API) DeleteBook(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		writeError(w, http.StatusBadRequest, "Invalid book ID")
		return
	}

	if !api.store.DeleteBook(id) {
		writeError(w, http.StatusNotFound, "Book not found")
		return
	}

	writeSuccess(w, map[string]string{"message": "Book deleted successfully"})
}

// HealthCheck handles GET /health
func (api *API) HealthCheck(w http.ResponseWriter, r *http.Request) {
	writeSuccess(w, map[string]string{
		"status":    "healthy",
		"timestamp": time.Now().Format(time.RFC3339),
	})
}

// setupRoutes configures all the routes
func (api *API) setupRoutes() *mux.Router {
	router := mux.NewRouter()

	// Health check
	router.HandleFunc("/health", api.HealthCheck).Methods("GET")

	// Book routes
	router.HandleFunc("/books", api.GetBooks).Methods("GET")
	router.HandleFunc("/books", api.CreateBook).Methods("POST")
	router.HandleFunc("/books/{id}", api.GetBook).Methods("GET")
	router.HandleFunc("/books/{id}", api.UpdateBook).Methods("PUT")
	router.HandleFunc("/books/{id}", api.DeleteBook).Methods("DELETE")

	// Add CORS middleware
	router.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

			if r.Method == "OPTIONS" {
				w.WriteHeader(http.StatusOK)
				return
			}

			next.ServeHTTP(w, r)
		})
	})

	return router
}

func main() {
	api := NewAPI()
	router := api.setupRoutes()

	// Add some sample data
	sampleBooks := []Book{
		{
			Title:       "The Go Programming Language",
			Author:      "Alan Donovan & Brian Kernighan",
			ISBN:        "978-0134190440",
			PublishedAt: time.Date(2015, 11, 5, 0, 0, 0, 0, time.UTC),
		},
		{
			Title:       "Clean Code",
			Author:      "Robert C. Martin",
			ISBN:        "978-0132350884",
			PublishedAt: time.Date(2008, 8, 1, 0, 0, 0, 0, time.UTC),
		},
	}

	for _, book := range sampleBooks {
		api.store.CreateBook(book)
	}

	port := ":8080"
	fmt.Printf("Server starting on port %s\n", port)
	fmt.Println("Available endpoints:")
	fmt.Println("  GET    /health")
	fmt.Println("  GET    /books")
	fmt.Println("  POST   /books")
	fmt.Println("  GET    /books/{id}")
	fmt.Println("  PUT    /books/{id}")
	fmt.Println("  DELETE /books/{id}")

	log.Fatal(http.ListenAndServe(port, router))
}
