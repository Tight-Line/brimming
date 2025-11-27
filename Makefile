# Brimming Makefile
# All development commands run inside Docker containers for portability

COMPOSE_DEV = docker-compose -f docker-compose.dev.yml
COMPOSE_PROD = docker-compose -f docker-compose.yml
# Use -T to disable pseudo-TTY (avoids shell profile loading which causes RVM warnings)
DEV_EXEC = $(COMPOSE_DEV) exec -T dev
DEV_EXEC_TTY = $(COMPOSE_DEV) exec dev
DEV_RUN = $(COMPOSE_DEV) run --rm dev

.PHONY: help setup build up down restart logs shell console db-create db-migrate db-rollback db-reset db-seed db-console test test-models test-requests test-jobs test-all lint lint-fix security coverage clean helm-lint helm-test ci

# Default target
help:
	@echo "Brimming Development Commands"
	@echo ""
	@echo "Setup & Infrastructure:"
	@echo "  make setup        - Initial project setup (build, install deps, create db)"
	@echo "  make build        - Build Docker images"
	@echo "  make up           - Start all services"
	@echo "  make down         - Stop all services"
	@echo "  make restart      - Restart all services"
	@echo "  make logs         - Tail logs from all services"
	@echo "  make clean        - Remove containers, volumes, and generated files"
	@echo ""
	@echo "Development:"
	@echo "  make shell        - Open bash shell in dev container"
	@echo "  make console      - Open Rails console"
	@echo "  make server       - Start Rails server (accessible at localhost:3000)"
	@echo ""
	@echo "Database:"
	@echo "  make db-create    - Create databases"
	@echo "  make db-migrate   - Run pending migrations"
	@echo "  make db-rollback  - Rollback last migration"
	@echo "  make db-reset     - Drop, create, migrate, and seed database"
	@echo "  make db-seed      - Load seed data"
	@echo "  make db-console   - Open psql console (schema: brimming)"
	@echo ""
	@echo "Testing:"
	@echo "  make test         - Run all tests with coverage"
	@echo "  make test-models  - Run model specs"
	@echo "  make test-requests - Run request specs"
	@echo "  make test-jobs    - Run job specs"
	@echo "  make test-all     - Run all tests (alias for test)"
	@echo "  make coverage     - Run tests and open coverage report"
	@echo ""
	@echo "Code Quality:"
	@echo "  make lint         - Run RuboCop linter"
	@echo "  make lint-fix     - Run RuboCop with auto-fix"
	@echo "  make security     - Run security scans (Brakeman, bundler-audit)"
	@echo ""
	@echo "Helm:"
	@echo "  make helm-lint    - Lint Helm chart"
	@echo "  make helm-test    - Run Helm chart tests"
	@echo ""
	@echo "CI:"
	@echo "  make ci           - Run full CI pipeline (lint, security, test)"

# ============================================================================
# Setup & Infrastructure
# ============================================================================

setup: build
	$(COMPOSE_DEV) up -d postgres valkey
	@echo "Waiting for PostgreSQL to be ready..."
	@sleep 5
	$(DEV_RUN) bundle install
	$(DEV_RUN) rails db:create db:migrate db:seed
	@echo ""
	@echo "Setup complete! Run 'make up' to start all services."

build:
	$(COMPOSE_DEV) build

up:
	$(COMPOSE_DEV) up -d
	@echo "Services started. Run 'make logs' to see output."

down:
	$(COMPOSE_DEV) down

restart: down up

logs:
	$(COMPOSE_DEV) logs -f

clean:
	$(COMPOSE_DEV) down -v --remove-orphans
	rm -rf coverage/ tmp/cache log/*.log

# ============================================================================
# Development
# ============================================================================

shell:
	$(DEV_EXEC_TTY) bash

console:
	$(DEV_EXEC_TTY) rails console

server:
	$(DEV_EXEC) rails server -b 0.0.0.0

# ============================================================================
# Database
# ============================================================================

db-create:
	$(DEV_EXEC) rails db:create

db-migrate:
	$(DEV_EXEC) rails db:migrate

db-rollback:
	$(DEV_EXEC) rails db:rollback

db-reset:
	$(DEV_EXEC) rails db:drop db:create db:migrate db:seed

db-seed:
	$(DEV_EXEC) rails db:seed

db-console:
	$(COMPOSE_DEV) exec -e PGOPTIONS='-c search_path=brimming,public' postgres psql -U brimming -d brimming

# ============================================================================
# Testing
# ============================================================================

test:
	$(DEV_EXEC) bundle exec rspec

test-models:
	$(DEV_EXEC) bundle exec rspec spec/models

test-requests:
	$(DEV_EXEC) bundle exec rspec spec/requests

test-jobs:
	$(DEV_EXEC) bundle exec rspec spec/jobs

test-all: test

coverage: test
	@echo "Coverage report generated at coverage/index.html"

# ============================================================================
# Code Quality
# ============================================================================

lint:
	$(DEV_EXEC) bundle exec rubocop

lint-fix:
	$(DEV_EXEC) bundle exec rubocop -A

security:
	$(DEV_EXEC) bundle exec brakeman -q
	$(DEV_EXEC) bundle exec bundler-audit check --update

# ============================================================================
# Helm
# ============================================================================

helm-lint:
	helm lint helm/brimming

helm-test:
	helm unittest helm/brimming

helm-template:
	helm template brimming helm/brimming

# ============================================================================
# CI Pipeline
# ============================================================================

ci: lint security test helm-lint
	@echo ""
	@echo "CI pipeline completed successfully!"
