# Single Account Example

## Overview

This example deploys the complete infrastructure into a **single AWS account**.

Unlike the cross-account example, this deployment does not use AWS Resource Access Manager (RAM) or Terraform Remote State.

It is intended for users who want to learn the Terraform modules before implementing the production-style multi-account architecture.

---

# Architecture

```text
AWS Account
│
├── VPC
│
├── Public Subnets
│
├── Private Subnets
│
├── Security Groups
│
├── EC2 Instance
│
├── Transit Gateway
│
└── VPC Routes
```

---

# What This Example Deploys

This example provisions:

- Amazon VPC
- Public Subnets
- Private Subnets
- Security Groups
- IAM Instance Profile
- EC2 Instance
- AWS Transit Gateway
- Transit Gateway Attachment
- VPC Route Tables
- VPC Routes

This example intentionally excludes:

- AWS RAM
- Cross-Account Sharing
- Terraform Remote State

---

# Prerequisites

Before running this example, ensure you have:

- Terraform installed
- AWS CLI installed
- AWS credentials configured
- One AWS account
- Appropriate IAM permissions

---

# Files

```text
single-account/
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

This example demonstrates the following modules:

- VPC
- Security Group
- IAM Instance Profile
- EC2
- Transit Gateway
- Transit Gateway Attachment
- Transit Gateway Routes

---

# Learning Objectives

After completing this example, you should understand:

- Root Modules
- Child Modules
- Module Composition
- VPC Networking
- Transit Gateway Attachments
- Route Tables
- Terraform Outputs

---

# When Should You Use This Example?

Use this example if:

- You have only one AWS account.
- You want to understand the module relationships.
- You are learning Terraform module composition.
- You want to validate the reusable modules before attempting a multi-account deployment.

---

# Next Step

After completing this example, continue with:

```text
examples/cross-account/
```

to deploy the complete DEV ↔ PROD architecture using:

- AWS Transit Gateway
- AWS RAM
- Terraform Remote State
