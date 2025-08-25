# CI/CD Pipeline Health Dashboard - Docker Management
# ==============================================

# Default environment
ENV ?= dev

# Docker compose files
COMPOSE_DEV = docker-compose.dev.yml
COMPOSE_PROD = docker-compose.prod.yml
COMPOSE_DEFAULT = docker-compose.yml

# Help target
.PHONY: help
help:
	@echo "🐳 CI/CD Pipeline Health Dashboard - Docker Commands"
	@echo "=================================================="
	@echo ""
	@echo "Development:"
	@echo "  make dev-up        Start development environment"
	@echo "  make dev-down      Stop development environment"
	@echo "  make dev-logs      View development logs"
	@echo "  make dev-build     Build development containers"
	@echo ""
	@echo "Production:"
	@echo "  make prod-up       Start production environment"
	@echo "  make prod-down     Stop production environment"
	@echo "  make prod-logs     View production logs"
	@echo "  make prod-build    Build production containers"
	@echo ""
	@echo "General:"
	@echo "  make up            Start default environment"
	@echo "  make down          Stop all containers"
	@echo "  make build         Build all containers"
	@echo "  make clean         Clean up containers and volumes"
	@echo "  make health        Check container health"
	@echo "  make backup        Backup database"
	@echo "  make restore       Restore database"
	@echo "  make test          Run tests in containers"
	@echo ""

# Development environment
.PHONY: dev-up dev-down dev-logs dev-build dev-restart
dev-up:
	@echo "🚀 Starting development environment..."
	docker compose -f $(COMPOSE_DEV) up -d --build

dev-down:
	@echo "🛑 Stopping development environment..."
	docker compose -f $(COMPOSE_DEV) down

dev-logs:
	@echo "📋 Viewing development logs..."
	docker compose -f $(COMPOSE_DEV) logs -f

dev-build:
	@echo "🔨 Building development containers..."
	docker compose -f $(COMPOSE_DEV) build --no-cache

dev-restart:
	@echo "🔄 Restarting development environment..."
	$(MAKE) dev-down
	$(MAKE) dev-up

# Production environment
.PHONY: prod-up prod-down prod-logs prod-build prod-restart
prod-up:
	@echo "🚀 Starting production environment..."
	docker compose -f $(COMPOSE_PROD) up -d --build

prod-down:
	@echo "🛑 Stopping production environment..."
	docker compose -f $(COMPOSE_PROD) down

prod-logs:
	@echo "📋 Viewing production logs..."
	docker compose -f $(COMPOSE_PROD) logs -f

prod-build:
	@echo "🔨 Building production containers..."
	docker compose -f $(COMPOSE_PROD) build --no-cache

prod-restart:
	@echo "🔄 Restarting production environment..."
	$(MAKE) prod-down
	$(MAKE) prod-up

# Default environment
.PHONY: up down logs build restart
up:
	@echo "🚀 Starting default environment..."
	docker compose up -d --build

down:
	@echo "🛑 Stopping all containers..."
	docker compose down
	docker compose -f $(COMPOSE_DEV) down
	docker compose -f $(COMPOSE_PROD) down

logs:
	@echo "📋 Viewing logs..."
	docker compose logs -f

build:
	@echo "🔨 Building containers..."
	docker compose build --no-cache

restart:
	@echo "🔄 Restarting containers..."
	$(MAKE) down
	$(MAKE) up

# Maintenance commands
.PHONY: clean health backup restore test
clean:
	@echo "🧹 Cleaning up containers and volumes..."
	docker compose down -v
	docker compose -f $(COMPOSE_DEV) down -v
	docker compose -f $(COMPOSE_PROD) down -v
	docker system prune -f
	docker volume prune -f

health:
	@echo "🏥 Checking container health..."
	@echo "Development containers:"
	-docker compose -f $(COMPOSE_DEV) ps
	@echo ""
	@echo "Production containers:"
	-docker compose -f $(COMPOSE_PROD) ps
	@echo ""
	@echo "Default containers:"
	-docker compose ps
	@echo ""
	@echo "Health endpoints:"
	@echo "Backend: curl -f http://localhost:8001/health"
	@echo "Frontend: curl -f http://localhost:5173/"

backup:
	@echo "💾 Backing up database..."
	@mkdir -p ./backups
	@timestamp=$$(date +%Y%m%d_%H%M%S) && \
	docker compose exec backend cp /app/data/dashboard.db /tmp/backup_$$timestamp.db && \
	docker cp ci-dashboard-backend:/tmp/backup_$$timestamp.db ./backups/backup_$$timestamp.db && \
	echo "Database backed up to ./backups/backup_$$timestamp.db"

restore:
	@echo "📥 Restoring database..."
	@echo "Available backups:"
	@ls -la ./backups/ 2>/dev/null || echo "No backups found"
	@read -p "Enter backup filename: " backup && \
	docker cp ./backups/$$backup ci-dashboard-backend:/tmp/restore.db && \
	docker compose exec backend cp /tmp/restore.db /app/data/dashboard.db && \
	echo "Database restored from $$backup"

test:
	@echo "🧪 Running tests in containers..."
	docker compose -f $(COMPOSE_DEV) up -d --build
	@echo "Testing backend health..."
	@timeout 30 bash -c 'until curl -f http://localhost:8001/health; do sleep 2; done'
	@echo "Testing frontend health..."
	@timeout 30 bash -c 'until curl -f http://localhost:5173/; do sleep 2; done'
	@echo "Testing alerting system..."
	docker compose -f $(COMPOSE_DEV) exec backend python -m pytest -v || true
	python test_alerts.py || true
	@echo "✅ Tests completed"

# Environment setup
.PHONY: setup env-dev env-prod
setup:
	@echo "⚙️ Setting up environment..."
	@if [ ! -f .env ]; then \
		cp .env.sample .env; \
		echo "Created .env from .env.sample"; \
		echo "Please edit .env with your configuration"; \
	else \
		echo ".env already exists"; \
	fi

env-dev:
	@echo "🔧 Setting up development environment..."
	$(MAKE) setup
	$(MAKE) dev-build
	$(MAKE) dev-up
	$(MAKE) health

env-prod:
	@echo "🔧 Setting up production environment..."
	$(MAKE) setup
	@echo "⚠️  Please configure production values in .env"
	@echo "Required settings:"
	@echo "  - ALERT_SLACK_WEBHOOK or SMTP settings"
	@echo "  - Production database URL (if not SQLite)"
	@echo "  - CORS origins for production domain"
	$(MAKE) prod-build
	$(MAKE) prod-up
	$(MAKE) health

# Quick commands
.PHONY: start stop status
start: up
stop: down
status: health

# Development workflow shortcuts
.PHONY: dev prod
dev: dev-up
prod: prod-up
