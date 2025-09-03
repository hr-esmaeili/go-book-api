# Go Book API

A simple REST API for managing books, built with Go and deployed with CI/CD automation.

## Features

- **CRUD Operations**: Create, Read, Update, Delete books
- **RESTful API**: Clean HTTP endpoints with JSON responses
- **In-memory Storage**: Fast data access (can be extended to use databases)
- **Health Check**: Built-in health monitoring endpoint
- **CORS Support**: Cross-origin resource sharing enabled
- **CI/CD Pipeline**: Automated testing and deployment
- **Systemd Service**: Production-ready service management

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check endpoint |
| GET | `/books` | Get all books |
| POST | `/books` | Create a new book |
| GET | `/books/{id}` | Get a specific book |
| PUT | `/books/{id}` | Update a specific book |
| DELETE | `/books/{id}` | Delete a specific book |

## Book Model

```json
{
  "id": 1,
  "title": "The Go Programming Language",
  "author": "Alan Donovan & Brian Kernighan",
  "isbn": "978-0134190440",
  "published_at": "2015-11-05T00:00:00Z",
  "created_at": "2024-01-01T12:00:00Z",
  "updated_at": "2024-01-01T12:00:00Z"
}
```

## Local Development

### Prerequisites

- Go 1.21 or higher
- Git

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd go-book-api
```

2. Install dependencies:
```bash
go mod download
```

3. Run the application:
```bash
go run main.go
```

4. Test the API:
```bash
# Health check
curl http://localhost:8080/health

# Get all books
curl http://localhost:8080/books

# Create a new book
curl -X POST http://localhost:8080/books \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My Book",
    "author": "John Doe",
    "isbn": "1234567890",
    "published_at": "2024-01-01T00:00:00Z"
  }'
```

### Running Tests

```bash
go test -v ./...
```

## Deployment

### Automated Deployment (CI/CD)

The application is automatically deployed to your Ubuntu server when you push to the `staging` branch.

#### Prerequisites

1. **GitHub Repository Secrets**: Configure the following secrets in your GitHub repository:
   - `SERVER_HOST`: Your Ubuntu server IP address
   - `SERVER_USER`: SSH username (usually `ubuntu`)
   - `SERVER_PASSWORD`: Your SSH password
   - `SERVER_PORT`: SSH port (usually `22`)

2. **Server Setup**: Run the setup script on your Ubuntu server:
```bash
# On your Ubuntu server
curl -O https://raw.githubusercontent.com/your-username/go-book-api/staging/deploy/setup-server.sh
chmod +x setup-server.sh
./setup-server.sh
```

#### Deployment Process

1. Push to `staging` branch:
```bash
git checkout staging
git push origin staging
```

2. GitHub Actions will automatically:
   - Run tests
   - Build the application
   - Deploy to your server
   - Start the systemd service
   - Verify deployment with health check

### Manual Deployment

1. Build the application:
```bash
go build -o go-book-api .
```

2. Copy files to server:
```bash
# Using password authentication
scp go-book-api user@server:/opt/go-book-api/
scp deploy/go-book-api.service user@server:/tmp/
scp deploy/env.production user@server:/opt/go-book-api/.env
```

3. Setup service on server:
```bash
ssh user@server
sudo cp /tmp/go-book-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable go-book-api
sudo systemctl start go-book-api
```

## Production Configuration

### Environment Variables

The application uses the following environment variables (configured in `/opt/go-book-api/.env`):

- `PORT`: Server port (default: 8080)
- `HOST`: Server host (default: 0.0.0.0)

### Service Management

```bash
# Check service status
sudo systemctl status go-book-api

# Start service
sudo systemctl start go-book-api

# Stop service
sudo systemctl stop go-book-api

# Restart service
sudo systemctl restart go-book-api

# View logs
sudo journalctl -u go-book-api -f
```

### Rollback

If you need to rollback to a previous version:

```bash
# On your server
curl -O https://raw.githubusercontent.com/your-username/go-book-api/staging/deploy/rollback.sh
chmod +x rollback.sh
./rollback.sh
```

## Monitoring

### Health Check

The application provides a health check endpoint at `/health`:

```bash
curl http://your-server:8080/health
```

Response:
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": "2024-01-01T12:00:00Z"
  }
}
```

### Logs

Application logs are available through systemd journal:

```bash
# View recent logs
sudo journalctl -u go-book-api --since "1 hour ago"

# Follow logs in real-time
sudo journalctl -u go-book-api -f
```

## Security Considerations

- The application runs as a non-root user (`go-book-api`)
- Systemd service includes security restrictions
- CORS is configured for cross-origin requests
- Input validation is implemented for all endpoints

## Future Enhancements

- Database integration (PostgreSQL/MySQL)
- JWT authentication
- Redis caching
- Rate limiting
- API versioning
- Swagger documentation
- Docker containerization

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License.