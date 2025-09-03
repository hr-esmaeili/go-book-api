# Go Book API

A simple REST API for managing books built with Go and Gorilla Mux.

## Features

- List all books
- Get book by ID
- Create new book
- Update existing book
- Delete book
- Health check endpoint
- Environment variable configuration

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/books` | Get all books |
| GET | `/api/books/{id}` | Get book by ID |
| POST | `/api/books` | Create a new book |
| PUT | `/api/books/{id}` | Update an existing book |
| DELETE | `/api/books/{id}` | Delete a book |
| GET | `/health` | Health check |

## Book Model

```json
{
  "id": 1,
  "title": "The Go Programming Language",
  "author": "Alan A. A. Donovan",
  "year": 2015,
  "isbn": "978-0134190440"
}
```

## Getting Started

### Prerequisites

- Go 1.21 or higher

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd go-book-api
```

2. Download dependencies:
```bash
go mod tidy
```

3. Run the server:
```bash
go run main.go
```

The server will start on port 8080 by default. You can change the port by setting the `PORT` environment variable.

### Environment Variables

The application supports environment variable configuration. Create a `.env` file in the root directory or set environment variables directly:

#### Option 1: Using .env file
Create a `.env` file in the project root:
```env
# Server Configuration
PORT=8080

# Database Configuration (for future use)
# DB_HOST=localhost
# DB_PORT=5432
# DB_NAME=bookdb
# DB_USER=postgres
# DB_PASSWORD=password

# Logging Configuration
# LOG_LEVEL=info
# LOG_FORMAT=json
```

#### Option 2: Setting environment variables directly

**Windows (PowerShell):**
```powershell
$env:PORT=3000
go run main.go
```

**Windows (Command Prompt):**
```cmd
set PORT=3000
go run main.go
```

**Linux/macOS:**
```bash
export PORT=3000
go run main.go
```

**Or run with environment variable inline:**
```bash
PORT=3000 go run main.go
```

### Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | The port number the server will listen on |

## Usage Examples

### Get all books
```bash
curl http://localhost:8080/api/books
```

### Get book by ID
```bash
curl http://localhost:8080/api/books/1
```

### Create a new book
```bash
curl -X POST http://localhost:8080/api/books \
  -H "Content-Type: application/json" \
  -d '{
    "title": "New Book",
    "author": "John Doe",
    "year": 2023,
    "isbn": "978-1234567890"
  }'
```

### Update a book
```bash
curl -X PUT http://localhost:8080/api/books/1 \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Updated Book Title",
    "author": "John Doe",
    "year": 2023,
    "isbn": "978-1234567890"
  }'
```

### Delete a book
```bash
curl -X DELETE http://localhost:8080/api/books/1
```

### Health check
```bash
curl http://localhost:8080/health
```

## Project Structure

```
go-book-api/
├── main.go              # Main application file
├── go.mod               # Go module file
├── go.sum               # Go module checksums
├── app/                 # Application structure
│   └── book/
│       └── model/
│           └── book.go  # Book model definition
├── .github/
│   └── workflows/
│       └── deploy.yml   # GitHub Actions deployment
├── .gitignore           # Git ignore file
├── Makefile             # Build and run commands
├── test_api.http        # HTTP test file
├── deploy.sh            # Server deployment script
├── deploy-manual.sh     # Manual deployment script
├── Dockerfile           # Docker configuration
├── docker-compose.yml   # Docker Compose setup
├── nginx.conf           # Nginx configuration
├── init.sql             # Database initialization
├── env.template         # Environment variables template
├── DEPLOYMENT.md        # Deployment guide
└── README.md            # This file
```

## Deployment

This project includes comprehensive deployment options:

### GitHub Actions Deployment
- Automated CI/CD pipeline
- Deploys to Ubuntu server via SSH
- Includes testing, building, and deployment steps
- See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed setup instructions

### Docker Deployment
- Multi-stage Docker build
- Docker Compose with MySQL and Nginx
- Production-ready configuration

### Manual Deployment
- Systemd service configuration
- Automated deployment script
- Backup and rollback capabilities

For detailed deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

### Required GitHub Secrets

Configure these secrets in your GitHub repository (Settings → Secrets and variables → Actions):

| Secret | Description | Example |
|--------|-------------|---------|
| `HOST` | Server IP/domain | `192.168.1.100` |
| `USERNAME` | SSH username | `ubuntu` |
| `PASSWORD` | SSH password | `your_ssh_password` |
| `PORT` | SSH port (optional) | `22` |
| `DB_PASSWORD` | MySQL password | `your_password` |

## Notes

- This implementation uses MySQL database with GORM ORM
- The API includes comprehensive validation and error handling
- Environment variables are loaded from `.env` file if present, otherwise from system environment
- Port validation ensures only valid port numbers are accepted
- Includes health check endpoint with database connectivity status
- ISBN uniqueness validation prevents duplicate entries

## License

This project is open source and available under the [MIT License](LICENSE). 