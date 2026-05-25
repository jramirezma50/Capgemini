# Terraform Project

## Description

This is a Terraform project for managing infrastructure as code (IaC). It provides automated deployment and management of cloud resources across multiple environments.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Workflow](#workflow)
- [Usage](#usage)
- [Best Practices](#best-practices)
- [Contributing](#contributing)
- [License](#license)

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) (or relevant cloud provider CLI)
- Cloud provider credentials configured
- Git for version control
- Text editor or IDE (VS Code recommended)

## Project Structure

```
.
├── environments/          # Environment-specific configurations
│   ├── dev/
│   ├── staging/
│   └── prod/
├── modules/              # Reusable Terraform modules
│   ├── networking/
│   ├── compute/
│   └── storage/
├── variables.tf          # Variable definitions
├── outputs.tf            # Output definitions
├── main.tf               # Primary resource definitions
├── provider.tf           # Provider configuration
├── terraform.tfvars      # Variable values (not committed)
├── .terraform/           # Terraform working directory (gitignored)
├── .gitignore            # Git ignore rules
└── README.md             # This file
```

## Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd <project-directory>
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Configure credentials:**
   Set up your cloud provider credentials (AWS, Azure, GCP, etc.)

## Workflow

### 1. **Plan Phase**
   Review infrastructure changes before applying:
   ```bash
   terraform plan -out=tfplan
   ```
   
   For specific environment:
   ```bash
   terraform plan -var-file="environments/dev/terraform.tfvars" -out=tfplan
   ```

### 2. **Review Phase**
   - Examine the plan output
   - Verify resources to be created, modified, or destroyed
   - Peer review recommended for production changes

### 3. **Apply Phase**
   Deploy infrastructure changes:
   ```bash
   terraform apply tfplan
   ```

### 4. **Validate Phase**
   Verify deployed resources:
   ```bash
   terraform validate
   ```

### 5. **Destroy Phase** (if needed)
   Remove infrastructure:
   ```bash
   terraform destroy -var-file="environments/dev/terraform.tfvars"
   ```

## Usage

### Deploy to Development
```bash
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars"
```

### Deploy to Staging
```bash
terraform plan -var-file="environments/staging/terraform.tfvars"
terraform apply -var-file="environments/staging/terraform.tfvars"
```

### Deploy to Production
```bash
terraform plan -var-file="environments/prod/terraform.tfvars"
terraform apply -var-file="environments/prod/terraform.tfvars"
```

### View Current State
```bash
terraform state list
terraform state show <resource-address>
```

### Refresh State
```bash
terraform refresh
```

## Best Practices

- **Use modules** for code reusability and organization
- **Separate environments** with distinct variable files
- **Use remote state** with Terraform Cloud or S3 backends
- **Version control** — commit .tf files, exclude tfstate files
- **Code review** — peer review all infrastructure changes
- **Lock files** — use `.terraform.lock.hcl` for dependency versioning
- **Naming conventions** — maintain consistent resource naming
- **Documentation** — document variables, outputs, and custom modules
- **Plan before apply** — always run `terraform plan` before `terraform apply`
- **Use workspaces** for environment isolation if needed

## Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make changes and test locally
3. Run `terraform plan` and validate output
4. Commit changes: `git commit -m "Add your message"`
5. Push to repository: `git push origin feature/your-feature`
6. Create a Pull Request for review

## License

This project is licensed under the MIT License — see LICENSE file for details.
