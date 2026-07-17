# AWS VPC Module

## Overview

This module creates the complete networking foundation required for an AWS environment.

It provisions:

- VPC
- Public Subnets
- Private Subnets
- Internet Gateway
- Route Tables
- Route Table Associations
- NAT Gateway (optional if enabled)
- Outputs required by other modules

The module is designed to be reusable and is used by both the **DEV** and **PROD** environments.

---

# Why This Module Exists

Almost every AWS resource requires a VPC.

Instead of creating VPC resources separately for every environment, this module encapsulates all networking resources into a reusable component.

```
Root Module

↓

VPC Module

↓

Networking Infrastructure
```

The same code can be used for:

- DEV
- PROD
- QA
- UAT

Only the input variables change.

---

# Resources Created

This module creates:

```
aws_vpc

aws_subnet

aws_internet_gateway

aws_route_table

aws_route_table_association

aws_route

(Optional)

aws_nat_gateway

(Optional)

aws_eip
```

Exactly which resources are created depends on the variables passed by the Root Module.

---

# Module Architecture

```
                VPC

        +-------------------+

        |                   |

        |   10.0.0.0/16     |

        |                   |

        +-------------------+

          |             |

          |             |

     Public         Private

     Subnets        Subnets

          |             |

          |             |

     Route Tables   Route Tables
```

The VPC module only builds the network.

It does **not** create EC2 instances, Security Groups or Transit Gateway attachments.

---

# Inputs

Typical inputs include:

| Variable | Description |
|----------|-------------|
| `vpc_cidr` | CIDR block for the VPC |
| `public_subnets` | Public subnet definitions |
| `private_subnets` | Private subnet definitions |
| `availability_zones` | AZs to deploy into |
| `tags` | Resource tags |

The Root Module provides all environment-specific values.

---

# Outputs

This module exports information required by other modules.

Examples:

```hcl
output "vpc_id"

output "private_subnets_ids"

output "public_subnets_ids"

output "private_route_table_ids"

output "public_route_table_ids"
```

Other modules consume these outputs instead of querying AWS directly.

---

# Why Outputs Return Maps

One important design decision was returning maps instead of lists.

Example

```hcl
{
    private_subnet-a = "subnet-abc"

    private_subnet-b = "subnet-def"
}
```

instead of

```hcl
[
    "subnet-abc",

    "subnet-def"
]
```

Why?

Because maps preserve the relationship between the logical subnet name and the AWS subnet ID.

This makes later lookups much easier.

---

# Understanding k => v.id

The module uses Terraform for-expressions.

Example

```hcl
output "private_route_table_ids" {

  value = {

    for k, v in aws_route_table.private :

    k => v.id

  }

}
```

Terraform converts

```
Terraform Resources

↓

Map

↓

Outputs
```

Example output

```hcl
{

private_subnet-a = "rtb-111"

private_subnet-b = "rtb-222"

}
```

This output is later consumed by other modules.

---

# How Other Modules Use These Outputs

Example

```
Transit Gateway Routes Module

↓

Receives

↓

private_route_table_ids

↓

Loops

↓

Creates Routes
```

Example

```hcl
route_table_id = each.value
```

The VPC module therefore becomes the source of truth for networking information.

---

# Module Data Flow

```
Variables

↓

VPC Module

↓

AWS Resources

↓

Outputs

↓

Root Module

↓

Other Modules
```

Every module that needs networking information depends on these outputs.

---

# Used By

This module is called from:

```
live/dev

live/prod
```

The same module provisions networking in both environments.

No code duplication is required.

---

# Design Decisions

## Reusable

The module contains no environment-specific logic.

It never references:

```
DEV

PROD
```

Only variables.

---

## Stable Outputs

Maps are returned instead of lists to preserve logical names.

This allows Root Modules to perform lookups using:

```hcl
module.vpc.private_subnets_ids[var.subnet_key]
```

instead of hardcoded subnet IDs.

---

## Separation of Concerns

The module creates only networking resources.

It does **not** create:

- EC2
- Transit Gateway
- IAM
- Security Groups

Each responsibility belongs to a separate module.

---

# Common Mistakes

## Hardcoding Subnet IDs

Wrong

```hcl
subnet_id = "subnet-123"
```

Correct

```hcl
module.vpc.private_subnets_ids["private_subnet-a"]
```

---

## Returning Lists Instead of Maps

Lists lose the relationship between the subnet name and subnet ID.

Maps preserve that relationship.

---

## Adding EC2 Resources

The VPC module should remain focused on networking.

EC2 resources belong in the EC2 module.

---

# Lessons Learned

While building this project I learned:

- Modules should have a single responsibility.
- Outputs are just as important as resources.
- Maps are easier to consume than lists.
- The Root Module should perform lookups.
- Child Modules should remain reusable.

---

# Future Improvements

Possible enhancements include:

- IPv6 Support
- Multiple NAT Gateways
- NAT Gateway per Availability Zone
- VPC Flow Logs
- DHCP Options Sets
- Transit Gateway Route Table Associations
- VPC Endpoints
- Network ACL customization

---

# Related Documentation

For a deeper understanding of the concepts used in this module, see:

- `docs/04-for_each-Explained.md`
- `docs/05-Maps-Lookups-Outputs.md`
- `docs/06-Root-Module-vs-Child-Module.md`
- `docs/11-Routing.md`
