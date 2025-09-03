package http

import "net/http"

type Server struct {
	ip           string
	port         int
	publicServer *http.Server
	localServer  *http.Server
}
