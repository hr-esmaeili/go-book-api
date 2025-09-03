.PHONY: run build test clean run-dev run-prod

# Default target
all: build

# Run the application
run:
	go run ./cmd

# Run with development port (3000)
run-dev:
	PORT=3000 go run ./cmd

# Run with production port (8080)
run-prod:
	PORT=8080 go run ./cmd

# Run with custom port (usage: make run-custom PORT=5000)
run-custom:
	PORT=$(PORT) go run ./cmd

# Build the application
build:
	go build -o bin/go-book-api ./cmd

# Run tests
test:
	go test ./...

# Clean build artifacts
clean:
	rm -rf bin/
	go clean

# Install dependencies
deps:
	go mod tidy
	go mod download

# Run with hot reload (requires air: go install github.com/cosmtrek/air@latest)
dev:
	air

# Build for different platforms
build-linux:
	GOOS=linux GOARCH=amd64 go build -o bin/go-book-api-linux ./cmd

build-windows:
	GOOS=windows GOARCH=amd64 go build -o bin/go-book-api.exe ./cmd

build-mac:
	GOOS=darwin GOARCH=amd64 go build -o bin/go-book-api-mac ./cmd 