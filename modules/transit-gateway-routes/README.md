# AWS Transit Gateway Routes Module

## Overview

This module creates **VPC Route Table entries** that send traffic to the Transit Gateway.

It does **not** create Transit Gateway Route Tables.

Instead, it updates the VPC Route Tables so EC2 instances know how to reach remote VPCs.

This was one of the biggest learning points during this project.

---

# Purpose

Creating a Transit Gateway Attachment is not enough.

The VPC must also know:

> "Where should traffic go?"

This module answers that question.

Example

```
Destination

10.1.0.0/16

↓

Transit Gateway
```

Without this route,

traffic never leaves the VPC.

---

# Resources Created

This module creates

```
aws_route
```

One route is created for every private Route Table.

Terraform manages the VPC routing layer.

It does not manage the Transit Gateway Route Table in this project because AWS automatically handled that through default association and propagation. :contentReference[oaicite:1]{index=1}

---

# Module Architecture

```
EC2

↓

Private Route Table

↓

Transit Gateway

↓

Remote VPC
```

This module manages only

```
Private Route Table

↓

Transit Gateway
```

---

# Why Is This Module Needed?

Initially I thought

```
Transit Gateway Attachment

↓

Done
```

Wrong.

The attachment creates the connection.

The route tells traffic to use that connection.

Both are required.

---

# Inputs

Typical inputs include:

| Variable | Description |
|----------|-------------|
| `private_route_table_ids` | Map of private Route Table IDs |
| `destination_cidr_block` | Remote VPC CIDR |
| `transit_gateway_id` | Transit Gateway ID |
| `tags` | Optional tags |

---

# Outputs

This module typically creates routes only.

Useful outputs can include:

```hcl
output "route_ids"
```

or

```hcl
output "route_table_ids"
```

if required for future automation.

---

# How This Module Works

Example

```hcl
resource "aws_route" "private_routes" {

  for_each = var.private_route_table_ids

  route_table_id = each.value

  destination_cidr_block = var.destination_cidr_block

  transit_gateway_id = var.transit_gateway_id

}
```

Terraform loops over every Route Table.

Example input

```hcl
{

private_subnet-a = "rtb-111"

private_subnet-b = "rtb-222"

}
```

Terraform creates

```
Route 1

↓

rtb-111

Route 2

↓

rtb-222
```

No copy-paste required.

---

# Why each.value?

This confused me for a long time.

Initially I assumed

```
each.key

↓

Route Table ID
```

Wrong.

Reality

```
each.key

↓

private_subnet-a

each.value

↓

rtb-111
```

AWS requires

```
Route Table ID
```

Therefore

```hcl
route_table_id = each.value
```

---

# Why for_each?

Imagine four private Route Tables.

Without

```
for_each
```

we would need

```
Route A

Route B

Route C

Route D
```

With Terraform

```hcl
for_each = var.private_route_table_ids
```

Terraform generates every route automatically.

This makes the module scalable and reusable.

---

# Data Flow

```
VPC Module

↓

Outputs

↓

private_route_table_ids

↓

Root Module

↓

TGW Routes Module

↓

aws_route
```

The VPC module provides the Route Table IDs.

The Routes module consumes them.

---

# VPC Route Tables vs TGW Route Tables

One of the biggest lessons from this project.

## VPC Route Table

Answers

```
Where should traffic leave the VPC?
```

Example

```
10.1.0.0/16

↓

Transit Gateway
```

Terraform manages these routes.

---

## Transit Gateway Route Table

Answers

```
Traffic has arrived.

↓

Which attachment should receive it?
```

AWS managed these automatically in this project because we enabled:

```hcl
default_route_table_association = "enable"

default_route_table_propagation = "enable"
```

As a result, new attachments were automatically associated with the default TGW route table and their CIDRs were propagated into it. :contentReference[oaicite:2]{index=2}

---

# Packet Flow

```
EC2

↓

Private Route Table

↓

Transit Gateway

↓

TGW Route Table

↓

Remote Attachment

↓

Remote VPC

↓

Remote EC2
```

Notice

Traffic passes through two routing layers.

---

# Design Decisions

## Single Responsibility

This module creates only:

```
aws_route
```

It does not create:

- VPC
- Transit Gateway
- Attachments
- RAM Shares

Each responsibility belongs to its own module.

---

## Reusable

The same module works for:

- DEV → PROD
- PROD → DEV
- QA → Shared Services
- Any future VPC

Only the CIDR and Route Table IDs change.

---

## Map-Based Design

Instead of hardcoding Route Table IDs,

the module consumes

```hcl
private_route_table_ids
```

from the VPC module.

This keeps the module independent of any specific VPC.

---

# Common Mistakes

## Mistake 1

Using

```hcl
route_table_id = each.key
```

Wrong.

Use

```hcl
route_table_id = each.value
```

because AWS expects the Route Table ID.

---

## Mistake 2

Thinking Propagation updates VPC Route Tables.

Wrong.

Propagation updates the Transit Gateway Route Table.

Terraform still creates VPC routes.

---

## Mistake 3

Hardcoding Route Table IDs.

Wrong

```hcl
route_table_id = "rtb-123456"
```

Correct

```hcl
route_table_id = each.value
```

---

## Mistake 4

Thinking the Transit Gateway creates VPC routes.

It does not.

Terraform must explicitly create the `aws_route` resources.

---

# Lessons Learned

While building this project I learned:

- Attachments and routing are different concepts.
- VPC Route Tables and TGW Route Tables have different responsibilities.
- `for_each` eliminates repetitive Terraform code.
- `each.value` contains the AWS Route Table ID.
- Automatic TGW propagation does not remove the need for VPC routes.

---

# Future Improvements

Possible enhancements include:

- Support multiple destination CIDRs
- Prefix List support
- Blackhole route support
- Conditional route creation
- Custom Transit Gateway Route Tables
- Inspection VPC routing

---

# Related Documentation

- `modules/vpc/README.md`
- `modules/transit-gateway/README.md`
- `modules/tgw-attachment/README.md`
- `docs/11-Routing.md`
- `docs/13-Terraform-Patterns.md`
