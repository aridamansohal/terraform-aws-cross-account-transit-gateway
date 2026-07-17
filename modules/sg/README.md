# AWS Security Group Module

## Overview

This module creates AWS Security Groups and their associated ingress and egress rules.

It is designed to be reusable across multiple environments and applications.

Rather than defining Security Groups directly inside every environment, this module centralizes all Security Group creation into a reusable component.

---

# Purpose

Security Groups act as virtual firewalls for AWS resources.

This module provides a consistent way to create Security Groups while keeping the Root Modules clean.

The same module is used by both:

- DEV
- PROD

Only the input variables change.

---

# Resources Created

Typical resources created by this module include:

```
aws_security_group

aws_vpc_security_group_ingress_rule

aws_vpc_security_group_egress_rule
```

Depending on the module implementation, inline rules or separate rule resources may be used.

---

# Module Architecture

```
Root Module

↓

Security Group Module

↓

Security Group

↓

Ingress Rules

↓

Egress Rules

↓

Outputs
```

The module only manages Security Groups.

It does not create EC2 instances or attach them to interfaces.

---

# Inputs

Typical inputs include:

| Variable | Description |
|----------|-------------|
| `vpc_id` | VPC where the Security Group will be created |
| `name` | Security Group name |
| `description` | Description of the Security Group |
| `ingress_rules` | List or map of ingress rules |
| `egress_rules` | List or map of egress rules |
| `tags` | Resource tags |

The Root Module supplies these values.

---

# Outputs

Typical outputs include:

```hcl
output "security_group_id"

output "security_group_arn"

output "security_group_name"
```

These outputs allow other modules to reference the Security Group without querying AWS.

---

# Example Usage

```hcl
module "sg" {

  source = "../../modules/sg"

  vpc_id = module.vpc.vpc_id

  name = "web-sg"

  ingress_rules = var.ingress_rules

  egress_rules = var.egress_rules

}
```

The EC2 module can then consume the output:

```hcl
vpc_security_group_ids = [
  module.sg.security_group_id
]
```

---

# Data Flow

```
Variables

↓

Security Group Module

↓

AWS Security Group

↓

Outputs

↓

EC2 Module
```

The module becomes the source of truth for Security Group IDs.

---

# Design Decisions

## Single Responsibility

This module only manages Security Groups.

It does not manage:

- EC2
- Load Balancers
- IAM
- Route Tables

Those belong in separate modules.

---

## Reusable

The module contains no DEV- or PROD-specific logic.

The same module can be used for:

- Web Servers
- Application Servers
- Databases
- Bastion Hosts

Only the variables change.

---

## Root Module Controls Relationships

The Security Group module only creates Security Groups.

The Root Module decides which EC2 instances, Load Balancers or other resources use them.

This keeps the module generic and reusable.

---

# Common Mistakes

## Hardcoding VPC IDs

Wrong

```hcl
vpc_id = "vpc-123456"
```

Correct

```hcl
vpc_id = module.vpc.vpc_id
```

---

## Mixing Responsibilities

Avoid creating EC2 instances inside this module.

Security Groups and EC2 instances should remain separate modules.

---

## Overly Permissive Rules

Avoid rules such as:

```
0.0.0.0/0

↓

All Ports
```

unless there is a clear business requirement.

Follow the principle of least privilege whenever possible.

---

# Lessons Learned

While building this project I learned:

- Security Groups belong in their own reusable module.
- Other modules should consume the Security Group ID through outputs.
- Keeping networking and compute separate makes the repository easier to understand.
- The Root Module is responsible for wiring Security Groups to EC2 instances.

---

# Future Improvements

Possible enhancements include:

- IPv6 support
- Prefix Lists
- Managed Prefix Lists
- Self-referencing rules
- Security Group rule validation
- Optional rule templates

---

# Related Documentation

For additional background, see:

- `docs/01-AWS-Architecture.md`
- `docs/06-Root-Module-vs-Child-Module.md`
- `docs/11-Routing.md`
- `docs/13-Terraform-Patterns.md`
