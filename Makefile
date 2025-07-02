# Makefile for ClickHouse Dev Battlestation

.PHONY: dev-up dev-load dev-benchmark dev-reset

dev-up:
	@echo "[dev-up] Spinning up full ClickHouse cluster..."
	docker-compose up -d

dev-load:
	@echo "[dev-load] Loading sample data into ClickHouse..."
	./scripts/dev-load.sh

dev-benchmark:
	@echo "[dev-benchmark] Running performance benchmarks..."
	./scripts/dev-benchmark.sh

dev-reset:
	@echo "[dev-reset] Destroying and resetting environment..."
	docker-compose down -v
	./scripts/dev-reset.sh 