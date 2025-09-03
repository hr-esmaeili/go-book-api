# Go Book API Makefile

.PHONY: help build test run clean deploy

# Default target
help:
	@echo "Available targets:"
	@echo "  build    - Build the application"
	@echo "  test     - Run tests"
	@echo "  run      - Run the application locally"
	@echo "  clean    - Clean build artifacts"
	@echo "  deploy   - Deploy to staging (requires git push)"

# Build the application
build:
	@echo "Building go-book-api..."
	go build -o go-book-api .

# Run tests
test:
	@echo "Running tests..."
	go test -v ./...

# Run the application locally
run:
	@echo "Starting go-book-api..."
	go run main.go

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f go-book-api
	rm -f go-book-api.exe

# Deploy to staging (triggers CI/CD)
deploy:
	@echo "Deploying to staging..."
	git checkout staging
	git merge main
	git push origin staging
	@echo "Deployment triggered! Check GitHub Actions for progress."

# Install dependencies
deps:
	@echo "Installing dependencies..."
	go mod download
	go mod tidy

# Format code
fmt:
	@echo "Formatting code..."
	go fmt ./...

# Lint code
lint:
	@echo "Linting code..."
	golangci-lint run

# Run with hot reload (requires air)
dev:
	@echo "Starting development server with hot reload..."
	air
