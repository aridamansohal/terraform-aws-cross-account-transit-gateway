# AWS Transit Gateway Attachment Module

## Overview

This module creates a **Transit Gateway VPC Attachment**.

The attachment connects a VPC to an existing AWS Transit Gateway.

Without an attachment, a VPC cannot communicate through the Transit Gateway.

Think of it this way:

```
Transit Gateway

↓

Network Hub
```

```
TGW Attachment

↓

Network Cable
```

The Transit Gateway provides the hub.

The attachment connects the VPC to that hub.

---

# Purpose

Creating a Transit Gateway does NOT automatically connect VPCs.

Every VPC must create its own attachment.

Example

```
DEV VPC

↓

TGW Attachment

↓

Transit Gateway
```

```
PROD VPC

↓

TGW Attachment

↓

Transit Gateway
```

Only after both attachments exist can the Transit Gateway forward traffic.

---

# Resources Created

This module creates:

```
aws_ec2_transit_gateway_vpc_attachment
```

The attachment connects:

- One VPC
- One Transit Gateway
- One or more subnets

into a single network connection. Terraform requires the VPC ID, Transit Gateway ID, and subnet IDs for the attachment. :contentReference[oaicite:1]{index=1}

---

# Module Architecture

```
              Transit Gateway

                     ▲

                     │

         TGW Attachment

                     │

                     ▼

                   VPC
```

The attachment is the bridge between the VPC and the Transit Gateway.

---

# Why Does the Attachment Need Subnets?

One question I had while building this project was:

> "Why doesn't Terraform just need the VPC ID?"

Because AWS places attachment ENIs inside specific subnets.

Terraform therefore requires:

```
Transit Gateway

+

VPC

+

Subnet IDs
```

The attachment is anchored in the selected subnets. :contentReference[oaicite:2]{index=2}

---

# Why Private Subnets?

In this project we selected:

```
Private Subnets
```

instead of

```
Public Subnets
```

Reason:

Application traffic travels through private networking.

Keeping the attachment inside private subnets aligns with the architecture used throughout this repository.

---

# Inputs

Typical inputs include:

| Variable | Description |
|----------|-------------|
| `transit_gateway_id` | Shared Transit Gateway ID |
| `vpc_id` | VPC ID |
| `subnet_ids` | Private subnet IDs |
| `tags` | Resource tags |

Example

```hcl
module "tgw_attachment" {

  transit_gateway_id =
    data.terraform_remote_state.dev.outputs.transit_gateway_id

  vpc_id =
    module.vpc.vpc_id

  subnet_ids =
    values(module.vpc.private_subnets_ids)

}
```

---

# Outputs

Typical outputs include:

```hcl
output "attachment_id"

output "attachment_arn"

output "attachment_owner"
```

These outputs can be useful for troubleshooting or future automation.

---

# How This Module Works

Deployment flow:

```
DEV

↓

Transit Gateway

↓

AWS RAM

↓

Remote State

↓

PROD

↓

Reads TGW ID

↓

Creates Attachment
```

Notice

The attachment is created **after**:

- Transit Gateway
- RAM Share
- RAM Acceptance

---

# Why Remote State Is Required

The PROD account did not create the Transit Gateway.

Therefore

```
module.transit_gateway.transit_gateway_id
```

does not exist inside the PROD Root Module.

Instead we use

```hcl
data.terraform_remote_state.dev.outputs.transit_gateway_id
```

Remote State provides the Transit Gateway ID created by the DEV environment.

---

# Data Flow

```
DEV Root Module

↓

Transit Gateway Output

↓

Remote State

↓

PROD Root Module

↓

TGW Attachment Module

↓

AWS Attachment
```

This is one of the best examples of Root Modules communicating through Remote State.

---

# Association and Propagation

Our Transit Gateway was configured with:

```hcl
default_route_table_association = "enable"

default_route_table_propagation = "enable"
```

Because of that,

every new attachment automatically:

```
Associated

↓

Default TGW Route Table
```

and

```
Propagated

↓

VPC CIDR

↓

Default TGW Route Table
```

No additional Terraform resources were required for the default TGW Route Table in this project. :contentReference[oaicite:3]{index=3}

---

# Design Decisions

## Single Responsibility

This module creates only:

```
TGW Attachment
```

It does not create:

- Transit Gateway
- RAM Share
- Routes
- VPC

Those belong in separate modules.

---

## Reusable

The same module can attach:

- DEV
- PROD
- QA
- Shared Services

Only the input variables change.

---

## Root Module Handles Dependencies

The Root Module ensures:

```
Transit Gateway Exists

↓

RAM Share Accepted

↓

Remote State Available

↓

Attachment Created
```

The attachment module simply consumes those values.

---

# Common Mistakes

## Mistake 1

Trying to create an attachment before accepting the RAM Share.

Result

```
Transit Gateway

↓

Not Visible

↓

Attachment Fails
```

Always accept the share first.

---

## Mistake 2

Using Public Subnets unnecessarily.

Use the subnets that match your network design.

For this project,

private subnets were appropriate.

---

## Mistake 3

Hardcoding the Transit Gateway ID.

Wrong

```hcl
transit_gateway_id = "tgw-123456"
```

Correct

```hcl
transit_gateway_id =
data.terraform_remote_state.dev.outputs.transit_gateway_id
```

---

## Mistake 4

Thinking the attachment creates routes.

Wrong.

The attachment only establishes the connection.

Routing is handled separately by:

```
modules/transit-gateway-routes
```

---

# Lessons Learned

While building this project I learned:

- A Transit Gateway alone provides no connectivity.
- Every VPC requires its own attachment.
- Attachments are created by the VPC owner.
- Remote State allows the PROD environment to discover the shared Transit Gateway ID.
- Attachments and routing are two different concepts.

---

# Future Improvements

Possible enhancements include:

- Appliance Mode Support
- IPv6 Attachments
- Custom TGW Route Table Associations
- Custom TGW Route Table Propagations
- Multi-Region Transit Gateway Peering

---

# Related Documentation

- `modules/transit-gateway/README.md`
- `modules/ram-share/README.md`
- `modules/ram-share-accepter/README.md`
- `modules/transit-gateway-routes/README.md`
- `docs/08-Transit-Gateway.md`
- `docs/10-Cross-Account-TGW.md`
