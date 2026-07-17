# AWS VPC Endpoint Module

## Overview

This module provisions AWS VPC Endpoints.

A VPC Endpoint allows resources inside a private VPC to communicate with AWS services without traversing the public Internet.

Instead of routing traffic through:

```
Private Subnet

↓

NAT Gateway

↓

Internet

↓

AWS Service
```

Traffic stays entirely inside the AWS network.

---

# Why This Module Exists

Private workloads often need access to AWS services such as:

- Amazon S3
- DynamoDB
- Systems Manager (SSM)
- CloudWatch Logs
- EC2 Messages
- Secrets Manager
- KMS

Without a VPC Endpoint, those services are typically reached through an Internet Gateway or NAT Gateway.

A VPC Endpoint removes that dependency.

---

# Resources Created

Depending on the endpoint type, this module creates:

```
aws_vpc_endpoint
```

AWS supports two common endpoint types:

```
Gateway Endpoint

or

Interface Endpoint
```

The endpoint type depends on the AWS service being accessed. :contentReference[oaicite:1]{index=1}

---

# Endpoint Types

## Gateway Endpoint

Used for services such as:

- Amazon S3
- Amazon DynamoDB

Gateway endpoints are associated with route tables.

```
Private Route Table

↓

Gateway Endpoint

↓

S3
```

---

## Interface Endpoint

Used for services such as:

- SSM
- EC2 Messages
- CloudWatch Logs
- Secrets Manager
- KMS

AWS creates Elastic Network Interfaces (ENIs) inside the selected subnets.

```
Private Subnet

↓

ENI

↓

AWS Service
```

Interface endpoints usually require Security Groups and can optionally enable private DNS. :contentReference[oaicite:2]{index=2}

---

# Module Architecture

```
Root Module

↓

VPC Endpoint Module

↓

VPC Endpoint

↓

AWS Service
```

The module focuses only on endpoint creation.

---

# Inputs

Typical inputs include:

| Variable | Description |
|----------|-------------|
| `vpc_id` | Target VPC |
| `service_name` | AWS service name |
| `vpc_endpoint_type` | Gateway or Interface |
| `subnet_ids` | Interface endpoint subnets |
| `route_table_ids` | Gateway endpoint route tables |
| `security_group_ids` | Security Groups (Interface endpoints) |
| `private_dns_enabled` | Enable Private DNS |
| `tags` | Resource tags |

---

# Outputs

Typical outputs include:

```hcl
output "vpc_endpoint_id"

output "vpc_endpoint_arn"

output "dns_entries"
```

These outputs can be consumed by other modules if required.

---

# How This Module Works

The Root Module supplies:

```
VPC ID

↓

Subnet IDs

↓

Route Table IDs

↓

Security Groups
```

The VPC Endpoint Module creates the endpoint using those existing resources.

It does not create networking infrastructure itself.

---

# Data Flow

```
Variables

↓

Root Module

↓

VPC Module Outputs

↓

VPC Endpoint Module

↓

AWS VPC Endpoint
```

---

# Design Decisions

## Single Responsibility

The module creates VPC Endpoints only.

It does not create:

- VPC
- Subnets
- Route Tables
- Security Groups
- EC2 Instances

---

## Reusable

The same module can provision endpoints for multiple AWS services.

Only the service name and endpoint type change.

Examples:

```
S3

DynamoDB

SSM

CloudWatch

Secrets Manager

KMS
```

---

## Root Module Controls Dependencies

Networking resources are created first.

The Root Module then passes the required IDs into this module.

This keeps the VPC Endpoint module generic.

---

# Gateway vs Interface Endpoints

## Gateway Endpoint

```
Private Route Table

↓

Route Added

↓

AWS Service
```

Used primarily for:

- Amazon S3
- DynamoDB

---

## Interface Endpoint

```
Private Subnet

↓

Elastic Network Interface

↓

Private DNS

↓

AWS Service
```

Used for most other AWS services.

---

# Common Mistakes

## Wrong Endpoint Type

Example:

Creating an Interface Endpoint for Amazon S3.

Instead, use a Gateway Endpoint where appropriate.

Always verify the supported endpoint type for the target service. :contentReference[oaicite:3]{index=3}

---

## Missing Route Table Associations

Gateway Endpoints require the appropriate route tables.

Without them, private subnets cannot reach the AWS service.

---

## Missing Security Groups

Interface Endpoints create ENIs.

Those ENIs require Security Groups allowing the intended traffic.

---

## Mixing Endpoint Associations

Avoid managing the same endpoint associations through both the `aws_vpc_endpoint` resource and separate association resources, as Terraform warns this can cause conflicts. :contentReference[oaicite:4]{index=4}

---

# Lessons Learned

While building this project I learned:

- VPC Endpoints improve security by avoiding public Internet paths.
- Gateway and Interface Endpoints solve different problems.
- Interface Endpoints require subnets and Security Groups.
- Gateway Endpoints integrate with route tables.
- Keeping endpoint creation in its own module improves reusability.

---

# Future Improvements

Possible enhancements include:

- Endpoint Policies
- Multi-AZ Interface Endpoints
- Centralized Shared Services Endpoints
- PrivateLink for Internal Services
- Automatic Endpoint Discovery
- Endpoint Monitoring

---

# Related Documentation

- `modules/vpc/README.md`
- `docs/01-AWS-Architecture.md`
- `docs/11-Routing.md`
- `docs/13-Terraform-Patterns.md`
