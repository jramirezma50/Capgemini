.PHONY: help init plan apply destroy validate fmt clean

ENVIRONMENT ?= dev
TF_VARS = -var-file="environments/$(ENVIRONMENT)/terraform.tfvars"

help:
	@echo "Terraform Makefile Commands"
	@echo "============================"
	@echo "make init       - Initialize Terraform"
	@echo "make plan       - Plan infrastructure changes"
	@echo "make apply      - Apply infrastructure changes"
	@echo "make destroy    - Destroy infrastructure"
	@echo "make validate   - Validate Terraform configuration"
	@echo "make fmt        - Format Terraform files"
	@echo "make clean      - Clean Terraform working directory"
	@echo ""
	@echo "Usage: make <command> ENVIRONMENT=<dev|staging|prod>"
	@echo "Example: make plan ENVIRONMENT=prod"

init:
	terraform init

plan:
	terraform plan $(TF_VARS) -out=tfplan

apply:
	terraform apply tfplan

destroy:
	terraform destroy $(TF_VARS)

validate:
	terraform validate

fmt:
	terraform fmt -recursive

clean:
	rm -rf .terraform/
	rm -f .terraform.lock.hcl
	rm -f tfplan
	rm -f terraform.tfstate*

state-list:
	terraform state list

state-show:
	@read -p "Enter resource address: " resource; \
	terraform state show $$resource

refresh:
	terraform refresh $(TF_VARS)

output:
	terraform output -json

docs:
	@echo "Generating Terraform documentation..."
	terraform-docs markdown table . > docs/terraform.md

check: validate fmt
	@echo "All checks passed!"
