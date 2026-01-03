SHELL := /bin/bash
COMPOSE_FILE := docker-compose.yml

.PHONY: setup up down restart logs clean help

setup:
	@echo "🔧 Setting up local environment..."
	@bash scripts/setup.sh

up: setup
	@echo "🚀 Starting containers..."
	@docker compose up -d
	@echo "✨ System is up! Access via:"
	@echo "- https://auth.homelab.local"
	@echo "- https://monitor.homelab.local"

down:
	@echo "🛑 Stopping containers..."
	@docker compose down

logs:
	@docker compose logs -f

clean:
	@echo "⚠️ Cleaning up all data and certificates..."
	@docker compose down -v
	@rm -rf nginx/cert/*.pem
	@rm -rf data/authelia/secrets/*
	@rm -rf data/authelia/config/users.yml
