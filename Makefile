.PHONY: sync lint format sam-build sam-validate

sync:
	uv sync --all-groups

lint:
	uv run ruff check .

format:
	uv run ruff format .

sam-build:
	sam build

sam-validate:
	sam validate
