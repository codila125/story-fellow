.PHONY: install lint format infra-init infra-plan infra-apply run destroy tf-init tf-plan tf-apply tf-destroy

install:
	uv sync --all-groups

lint:
	uv run ruff check .

format:
	uv run ruff format .

infra-init:
	terraform -chdir=infra/terraform init

infra-plan:
	terraform -chdir=infra/terraform plan

infra-apply:
	terraform -chdir=infra/terraform apply

run:
	python3 -m http.server 8000 --directory web

destroy:
	terraform -chdir=infra/terraform destroy

# Backward-compatible aliases
tf-init: infra-init

tf-plan: infra-plan

tf-apply: infra-apply

tf-destroy: destroy
