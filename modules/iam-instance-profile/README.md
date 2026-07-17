# AWS IAM Instance Profile Module

## Overview

This module creates an IAM Instance Profile for Amazon EC2.

The Instance Profile acts as the bridge between an EC2 instance and an IAM Role.

Without an Instance Profile, an EC2 instance cannot assume an IAM Role.

---

# Why This Module Exists

One of the biggest misconceptions when learning AWS is:

> "Attach an IAM Role to EC2."

That isn't technically correct.

The actual relationship is:

```
IAM Policy

↓

IAM Role

↓

IAM Instance Profile

↓

EC2 Instance
```

The EC2 instance receives temporary AWS credentials through the Instance Profile.

---

# Resources Created

Typical resources include:

```
aws_iam_role

aws_iam_role_policy_attachment

aws_iam_instance_profile
```

Depending on your implementation, IAM policies may already exist and only the role/profile are created.

---

# Module Architecture

```
                IAM Policy

                     │

                     ▼

               IAM Role

                     │

                     ▼

          IAM Instance Profile

                     │

                     ▼

               EC2 Instance
```

The EC2 instance never attaches directly to an IAM Role.

AWS requires an Instance Profile. :contentReference[oaicite:1]{index=1}

---

# Purpose

This module provides EC2 instances with temporary AWS credentials.

Instead of storing:

```
AWS_ACCESS_KEY_ID

AWS_SECRET_ACCESS_KEY
```

inside the instance,

AWS automatically provides temporary credentials through the Instance Profile.

This is AWS's recommended security model. :contentReference[oaicite:2]{index=2}

---

# Inputs

Typical inputs include:

| Variable | Description |
|----------|-------------|
| `role_name` | IAM Role name |
| `instance_profile_name` | IAM Instance Profile name |
| `policy_arns` | IAM policies to attach |
| `tags` | Resource tags |

---

# Outputs

Typical outputs include:

```hcl
output "instance_profile_name"

output "instance_profile_arn"

output "role_name"

output "role_arn"
```

These outputs are consumed by the EC2 module.

---

# How the EC2 Module Uses It

The Root Module creates the IAM resources first.

```
IAM Module

↓

Instance Profile

↓

Output

↓

Root Module

↓

EC2 Module
```

Example:

```hcl
module "ec2" {

  iam_instance_profile =
    module.iam.instance_profile_name

}
```

The EC2 resource then uses:

```hcl
iam_instance_profile = var.iam_instance_profile
```

---

# Data Flow

```
Variables

↓

IAM Module

↓

IAM Role

↓

Instance Profile

↓

Outputs

↓

Root Module

↓

EC2 Module

↓

EC2 Instance
```

---

# Why Use Temporary Credentials?

AWS automatically rotates credentials attached through an IAM Role.

Benefits:

- No hardcoded Access Keys
- Automatic credential rotation
- Better security
- Least-privilege access

This follows AWS security best practices. :contentReference[oaicite:3]{index=3}

---

# Common Mistakes

## Mistake 1

Trying to attach an IAM Role directly.

Wrong

```hcl
iam_role = aws_iam_role.ec2.name
```

Correct

```hcl
iam_instance_profile =
aws_iam_instance_profile.ec2.name
```

An EC2 instance expects an **Instance Profile**, not a Role. :contentReference[oaicite:4]{index=4}

---

## Mistake 2

Using Access Keys inside EC2.

Wrong

```
AWS_ACCESS_KEY_ID

AWS_SECRET_ACCESS_KEY
```

Correct

Use an IAM Role and Instance Profile.

AWS automatically supplies temporary credentials.

---

## Mistake 3

Giving AdministratorAccess

Avoid assigning broad permissions.

Instead:

```
EC2

↓

IAM Role

↓

Only Required Permissions
```

Follow the principle of least privilege. :contentReference[oaicite:5]{index=5}

---

# Design Decisions

## Single Responsibility

This module only creates IAM resources required for EC2.

It does not create:

- EC2
- VPC
- Security Groups
- Transit Gateway

Those are separate modules.

---

## Reusable

The module is generic.

It can be reused by:

- Bastion Hosts
- Application Servers
- Web Servers
- Monitoring Servers
- Utility Instances

Only the IAM policies change.

---

## Separation of Concerns

This module creates identity.

The EC2 module creates compute.

Keeping them separate makes both modules reusable.

---

# Lessons Learned

While building this project I learned:

- EC2 never attaches directly to an IAM Role.
- The IAM Instance Profile is the object attached to EC2.
- Temporary credentials are more secure than static access keys.
- IAM modules should remain independent from compute modules.

---

# Future Improvements

Possible enhancements include:

- Inline IAM Policies
- Customer Managed Policies
- Permission Boundaries
- IAM Path Support
- Cross-Account AssumeRole Policies
- IAM Role Validation

---

# Related Documentation

For more information, see:

- `docs/06-Root-Module-vs-Child-Module.md`
- `docs/13-Terraform-Patterns.md`
- `modules/ec2/README.md`
