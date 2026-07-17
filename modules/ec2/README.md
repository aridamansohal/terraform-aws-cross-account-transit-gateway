# AWS EC2 Module

## Overview

This module provisions Amazon EC2 instances.

Unlike the VPC module, this module does not create networking resources.

Instead, it consumes networking information from other modules.

This keeps the module reusable and focused on compute resources.

---

# Purpose

The purpose of this module is to provision EC2 instances using infrastructure created elsewhere.

Instead of creating everything itself, the EC2 module receives:

- VPC information
- Subnet ID
- Security Group ID
- IAM Instance Profile
- User Data (optional)

from the Root Module.

---

# Resources Created

Typical resources include:

```
aws_instance
```

Depending on your implementation, the module may also support:

```
aws_eip

aws_volume_attachment

aws_ebs_volume
```

---

# Module Architecture

```
             Root Module

                   │

      ┌────────────┼────────────┐

      │            │            │

      ▼            ▼            ▼

    VPC          SG          IAM

      │            │            │

      └────────────┼────────────┘

                   │

                   ▼

              EC2 Module

                   │

                   ▼

             EC2 Instance
```

The EC2 module consumes outputs from other modules.

It does not create those resources itself.

---

# Inputs

Typical inputs include:

| Variable | Description |
|----------|-------------|
| `ami_id` | AMI ID |
| `instance_type` | EC2 instance type |
| `subnet_id` | Target subnet |
| `security_group_ids` | Security Groups |
| `iam_instance_profile` | IAM Instance Profile |
| `key_name` | SSH Key Pair |
| `user_data` | Startup script |
| `tags` | Resource tags |

---

# Outputs

Typical outputs include:

```hcl
output "instance_id"

output "private_ip"

output "public_ip"

output "private_dns"

output "availability_zone"
```

These outputs allow other modules or automation workflows to reference the EC2 instance. :contentReference[oaicite:1]{index=1}

---

# How This Module Works

The Root Module first creates:

```
VPC

↓

Subnets

↓

Security Groups

↓

IAM Instance Profile
```

The outputs are then passed into the EC2 module.

Example:

```hcl
module "ec2" {

  subnet_id = module.vpc.private_subnets_ids[var.subnet_key]

  security_group_ids = [
    module.sg.security_group_id
  ]

  iam_instance_profile =
    module.iam.instance_profile_name

}
```

The EC2 module simply consumes those values.

---

# Data Flow

```
Variables

↓

Root Module

↓

VPC Module

↓

Subnet ID

↓

Root Module

↓

EC2 Module

↓

EC2 Instance
```

The same pattern applies to Security Groups and IAM Instance Profiles.

---

# Why Doesn't the EC2 Module Create Subnets?

A common mistake is putting networking inside the EC2 module.

That would tightly couple compute and networking.

Instead:

```
VPC Module

↓

Networking
```

```
EC2 Module

↓

Compute
```

This separation makes both modules reusable.

---

# Security Group Flow

Security Groups are created by the Security Group module.

```
Security Group Module

↓

Output

↓

Root Module

↓

EC2 Module

↓

EC2 Instance
```

The EC2 module never creates Security Groups.

---

# IAM Flow

The IAM module creates:

```
IAM Role

↓

IAM Instance Profile
```

The Root Module passes:

```
Instance Profile

↓

EC2 Module

↓

EC2 Instance
```

This follows AWS best practices by using temporary credentials instead of long-lived access keys. :contentReference[oaicite:2]{index=2}

---

# Network Flow

```
EC2

↓

Subnet

↓

Route Table

↓

Transit Gateway

↓

Remote VPC
```

Notice that routing is outside the EC2 module.

The EC2 module only launches the instance.

---

# Design Decisions

## Single Responsibility

The module creates only EC2 instances.

It does not create:

- VPC
- Subnets
- Security Groups
- IAM Roles
- Transit Gateway
- Route Tables

---

## Reusable

The same module works for:

- Web Servers
- Application Servers
- Bastion Hosts
- Monitoring Servers
- Utility Hosts

Only the input variables change.

---

## Infrastructure Composition

The Root Module composes multiple child modules.

```
VPC

↓

Security Group

↓

IAM

↓

EC2
```

This design is much easier to maintain than putting everything into one module. :contentReference[oaicite:3]{index=3}

---

# Common Mistakes

## Hardcoding Subnet IDs

Wrong

```hcl
subnet_id = "subnet-123456"
```

Correct

```hcl
subnet_id =
module.vpc.private_subnets_ids[var.subnet_key]
```

---

## Hardcoding Security Groups

Wrong

```hcl
vpc_security_group_ids = ["sg-123456"]
```

Correct

```hcl
vpc_security_group_ids = [
  module.sg.security_group_id
]
```

---

## Using IAM Role Instead of Instance Profile

Wrong

```hcl
iam_role = aws_iam_role.ec2.name
```

Correct

```hcl
iam_instance_profile =
module.iam.instance_profile_name
```

EC2 instances attach an IAM Instance Profile, not an IAM Role directly. :contentReference[oaicite:4]{index=4}

---

## Mixing Responsibilities

Avoid creating:

- VPC
- Security Groups
- IAM

inside the EC2 module.

Keep compute separate from networking and identity.

---

# Lessons Learned

While building this project I learned:

- EC2 modules should only manage compute.
- Infrastructure should be composed using module outputs.
- The Root Module connects child modules together.
- Avoid hardcoded AWS resource IDs.
- Reusable modules make projects easier to maintain.

---

# Future Improvements

Possible enhancements include:

- Launch Templates
- Auto Scaling Groups
- Spot Instances
- Multiple Network Interfaces
- Elastic IP Support
- EBS Encryption
- IMDSv2 Enforcement
- Detailed Monitoring
- Termination Protection

---

# Related Documentation

- `modules/vpc/README.md`
- `modules/sg/README.md`
- `modules/iam-instance-profile/README.md`
- `docs/06-Root-Module-vs-Child-Module.md`
- `docs/13-Terraform-Patterns.md`
