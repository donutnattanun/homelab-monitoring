# ตัวแปรพื้นฐาน
SHELL := /bin/bash
COMPOSE_FILE := docker-compose.yml

.PHONY: setup up down restart logs clean help

# คำสั่งเริ่มต้น: ให้รันสคริปต์ setup ที่เราเขียนไว้
setup:
	@echo "🔧 Setting up local environment..."
	@bash scripts/setup.sh

# สั่งรันระบบ (Build และ Up แบบ Detached)
up: setup
	@echo "🚀 Starting containers..."
	@docker compose up -d
	@echo "✨ System is up! Access via:"
	@echo "   - https://auth.homelab.local"
	@echo "   - https://monitor.homelab.local"

# สั่งหยุดระบบ
down:
	@echo "🛑 Stopping containers..."
	@docker compose down

# ดู Logs แบบ Real-time
logs:
	@docker compose logs -f

# ล้างข้อมูลทิ้งทั้งหมด (ระวัง: ข้อมูลใน DB จะหาย)
clean:
	@echo "⚠️ Cleaning up all data and certificates..."
	@docker compose down -v
	@rm -rf nginx/cert/*.pem
	@rm -rf data/authelia/secrets/*
	@rm -rf data/authelia/config/users.yml
