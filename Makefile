.PHONY: sync lint format tf-init tf-plan tf-apply tf-destroy

sync:
	uv sync --all-groups

lint:
	uv run ruff check .

format:
	uv run ruff format .

tf-init:
	terraform -chdir=infra/terraform init

tf-plan:
	terraform -chdir=infra/terraform plan

tf-apply:
	terraform -chdir=infra/terraform apply

tf-destroy:
	terraform -chdir=infra/terraform destroy
