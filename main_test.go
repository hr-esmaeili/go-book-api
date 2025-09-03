package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestBookStore(t *testing.T) {
	store := NewBookStore()

	// Test CreateBook
	book := Book{
		Title:       "Test Book",
		Author:      "Test Author",
		ISBN:        "1234567890",
		PublishedAt: time.Now(),
	}

	createdBook := store.CreateBook(book)
	if createdBook.ID != 1 {
		t.Errorf("Expected ID 1, got %d", createdBook.ID)
	}

	// Test GetBook
	retrievedBook, exists := store.GetBook(1)
	if !exists {
		t.Error("Expected book to exist")
	}
	if retrievedBook.Title != "Test Book" {
		t.Errorf("Expected title 'Test Book', got '%s'", retrievedBook.Title)
	}

	// Test GetAllBooks
	books := store.GetAllBooks()
	if len(books) != 1 {
		t.Errorf("Expected 1 book, got %d", len(books))
	}

	// Test UpdateBook
	updatedBook := Book{
		Title:       "Updated Book",
		Author:      "Updated Author",
		ISBN:        "0987654321",
		PublishedAt: time.Now(),
	}

	updated, exists := store.UpdateBook(1, updatedBook)
	if !exists {
		t.Error("Expected book to exist for update")
	}
	if updated.Title != "Updated Book" {
		t.Errorf("Expected title 'Updated Book', got '%s'", updated.Title)
	}

	// Test DeleteBook
	deleted := store.DeleteBook(1)
	if !deleted {
		t.Error("Expected book to be deleted")
	}

	_, exists = store.GetBook(1)
	if exists {
		t.Error("Expected book to not exist after deletion")
	}
}

func TestAPIHandlers(t *testing.T) {
	api := NewAPI()

	// Test HealthCheck
	req, _ := http.NewRequest("GET", "/health", nil)
	rr := httptest.NewRecorder()
	api.HealthCheck(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("Expected status 200, got %d", rr.Code)
	}

	var response JSONResponse
	err := json.Unmarshal(rr.Body.Bytes(), &response)
	if err != nil {
		t.Fatal("Failed to unmarshal response")
	}

	if !response.Success {
		t.Error("Expected success to be true")
	}

	// Test GetBooks
	req, _ = http.NewRequest("GET", "/books", nil)
	rr = httptest.NewRecorder()
	api.GetBooks(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("Expected status 200, got %d", rr.Code)
	}

	// Test CreateBook
	book := Book{
		Title:       "Test Book",
		Author:      "Test Author",
		ISBN:        "1234567890",
		PublishedAt: time.Now(),
	}

	bookJSON, _ := json.Marshal(book)
	req, _ = http.NewRequest("POST", "/books", bytes.NewBuffer(bookJSON))
	req.Header.Set("Content-Type", "application/json")
	rr = httptest.NewRecorder()
	api.CreateBook(rr, req)

	if rr.Code != http.StatusCreated {
		t.Errorf("Expected status 201, got %d", rr.Code)
	}

	// Test CreateBook with invalid data
	invalidBook := Book{
		Title:  "", // Missing required field
		Author: "Test Author",
	}

	invalidJSON, _ := json.Marshal(invalidBook)
	req, _ = http.NewRequest("POST", "/books", bytes.NewBuffer(invalidJSON))
	req.Header.Set("Content-Type", "application/json")
	rr = httptest.NewRecorder()
	api.CreateBook(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("Expected status 400, got %d", rr.Code)
	}
}

func TestJSONResponse(t *testing.T) {
	// Test writeSuccess
	w := httptest.NewRecorder()
	data := map[string]string{"message": "test"}
	writeSuccess(w, data)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status 200, got %d", w.Code)
	}

	var response JSONResponse
	err := json.Unmarshal(w.Body.Bytes(), &response)
	if err != nil {
		t.Fatal("Failed to unmarshal response")
	}

	if !response.Success {
		t.Error("Expected success to be true")
	}

	// Test writeError
	w = httptest.NewRecorder()
	writeError(w, http.StatusBadRequest, "test error")

	if w.Code != http.StatusBadRequest {
		t.Errorf("Expected status 400, got %d", w.Code)
	}

	err = json.Unmarshal(w.Body.Bytes(), &response)
	if err != nil {
		t.Fatal("Failed to unmarshal response")
	}

	if response.Success {
		t.Error("Expected success to be false")
	}

	if response.Error != "test error" {
		t.Errorf("Expected error 'test error', got '%s'", response.Error)
	}
}
