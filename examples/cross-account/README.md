# Cross-Account Example

## Overview

This example demonstrates a complete **production-style AWS multi-account architecture** using Terraform.

The deployment spans two AWS accounts:

- **DEV Account** (Network Owner)
- **PROD Account** (Application Account)

The DEV account owns the AWS Transit Gateway and shares it with the PROD account using AWS Resource Access Manager (RAM).

The PROD account accepts the shared resource and creates its own Transit Gateway Attachment to establish private connectivity between VPCs.

This example represents the complete implementation documented throughout this repository.

---

# Architecture

```text
                     AWS Organization

        ┌──────────────────────────────────┐
        │                                  │
        │         DEV Account              │
        │                                  │
        │  VPC                             │
        │  EC2                             │
        │  Transit Gateway                 │
        │  AWS RAM Share                   │
        │                                  │
        └───────────────┬──────────────────┘
                        │
                 AWS RAM Share
                        │
        ┌───────────────▼──────────────────┐
        │                                  │
        │        PROD Account              │
        │                                  │
        │  VPC                             │
        │  EC2                             │
        │  TGW Attachment                  │
        │  Route Tables                    │
        │                                  │
        └──────────────────────────────────┘
```

---

# What This Example Deploys

This example provisions:

- AWS VPC
- Public Subnets
- Private Subnets
- Security Groups
- IAM Instance Profiles
- EC2 Instances
- AWS Transit Gateway
- AWS Resource Access Manager (RAM)
- RAM Share Accepter
- Transit Gateway Attachments
- VPC Route Tables
- Cross-Account Routing
- Terraform Remote State

---

# Deployment Flow

```text
Bootstrap

↓

Deploy DEV Environment

↓

Create Transit Gateway

↓

Create AWS RAM Share

↓

Accept RAM Share (PROD)

↓

Deploy PROD Environment

↓

Create TGW Attachment

↓

Configure Route Tables

↓

Private EC2 Communication
```

---

# Repository Layout

```text
cross-account/
│
├── README.md
│
├── dev/
│   ├── main.tf
│   ├── providers.tf
│   └── terraform.tfvars.example
│
└── prod/
    ├── main.tf
    ├── providers.tf
    └── terraform.tfvars.example
```

---

# Prerequisites

Before deploying this example, ensure you have:

- Terraform installed
- AWS CLI configured
- Two AWS accounts
- Appropriate IAM permissions
- Remote State backend configured
- AWS credentials for both accounts

---

# Modules Used

This example demonstrates all reusable modules in this repository:

- VPC
- Security Group
- IAM Instance Profile
- EC2
- VPC Endpoint
- Transit Gateway
- RAM Share
- RAM Share Accepter
- TGW Attachment
- TGW Routes

---

# Learning Objectives

After completing this example, you should understand:

- Multi-account AWS networking
- Terraform module composition
- Root and Child Modules
- Terraform Remote State
- AWS Resource Access Manager (RAM)
- AWS Transit Gateway
- Cross-account routing
- VPC Route Tables
- Transit Gateway Attachments
- Production-style Terraform repository design

---

# Deployment Order

Deploy the environments in the following order:

1. Bootstrap
2. DEV
3. Transit Gateway
4. RAM Share
5. PROD
6. RAM Share Acceptance
7. TGW Attachment
8. Route Tables
9. Connectivity Validation

---

# Related Documentation

- `docs/01-AWS-Architecture.md`
- `docs/02-Deployment-SOP.md`
- `docs/07-Terraform-Remote-State.md`
- `docs/08-Transit-Gateway.md`
- `docs/09-AWS-RAM.md`
- `docs/10-Cross-Account-TGW.md`
- `docs/11-Routing.md`

---

# Notes

This is the most advanced example in this repository and is intended for users who are already familiar with:

- Terraform basics
- AWS networking
- IAM
- VPCs
- Route Tables

If you are new to the project, complete the following examples first:

1. `examples/minimal/`
2. `examples/single-account/`

before attempting this deployment.
