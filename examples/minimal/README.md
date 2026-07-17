# Minimal Example

## Overview

This example demonstrates the minimum Terraform configuration required to use the reusable modules in this repository.

It is designed for users who want to understand the project structure before deploying the complete cross-account architecture.

---

# What This Example Deploys

This example deploys:

- One Amazon VPC
- Public and Private Subnets
- Security Groups
- One EC2 Instance

No Transit Gateway or AWS RAM resources are created in this example.

---

# Architecture

```text
VPC
 │
 ├── Public Subnet
 │
 ├── Private Subnet
 │
 └── EC2 Instance
```

---

# Prerequisites

Before running this example, ensure you have:

- Terraform installed
- AWS CLI configured
- An AWS account
- Appropriate IAM permissions

---

# Files

```text
minimal/
├── README.md
├── main.tf
├── providers.tf
├── versions.tf
└── terraform.tfvars.example
```

---

# Usage

Initialize Terraform:

```bash
terraform init
```

Review the execution plan:

```bash
terraform plan
```

Deploy the infrastructure:

```bash
terraform apply
```

Destroy the infrastructure:

```bash
terraform destroy
```

---

# Modules Used

This example uses:

- VPC Module
- Security Group Module
- EC2 Module

---

# Learning Objectives

After completing this example, you should understand:

- Terraform Root Modules
- Child Modules
- Module Inputs
- Module Outputs
- Basic AWS Networking
- EC2 Deployment

---

# Next Step

After completing this example, continue with:

```text
examples/single-account/
```

to deploy the complete infrastructure in a single AWS account.
