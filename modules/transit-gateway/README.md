# AWS Transit Gateway Module

## Overview

This module creates the AWS Transit Gateway (TGW), which serves as the central networking hub for this project.

Instead of creating multiple VPC Peering connections, every VPC connects to a single Transit Gateway.

The Transit Gateway then forwards traffic between attached VPCs.

This module is deployed only once, in the **DEV account**, which owns the Transit Gateway.

---

# Purpose

The purpose of this module is to centralize network connectivity.

Instead of

```
DEV ↔ PROD

DEV ↔ QA

PROD ↔ QA
```

we create

```
          Transit Gateway

             /    |    \

          DEV   PROD   QA
```

Every VPC needs only one attachment.

This architecture scales much better than VPC peering.

---

# Resources Created

This module creates:

```
aws_ec2_transit_gateway
```

Depending on future enhancements, additional resources could include:

```
aws_ec2_transit_gateway_route_table

aws_ec2_transit_gateway_route

aws_ec2_transit_gateway_route_table_association

aws_ec2_transit_gateway_route_table_propagation
```

In this project we rely on the default Transit Gateway Route Table instead of creating custom route tables.

---

# Module Architecture

```
                   Transit Gateway

              +-------------------+

              |                   |

              |       TGW         |

              |                   |

              +---------+---------+

                        |

          Shared with AWS RAM

                        |

            Multiple AWS Accounts
```

The module creates only the Transit Gateway.

It does not create:

- RAM Shares
- TGW Attachments
- Routes

Those responsibilities belong to separate modules.

---

# Inputs

Typical inputs include:

| Variable | Description |
|----------|-------------|
| `name` | Transit Gateway name |
| `description` | Description |
| `amazon_side_asn` | Amazon ASN |
| `auto_accept_shared_attachments` | Auto accept shared attachments |
| `default_route_table_association` | Default association behavior |
| `default_route_table_propagation` | Default propagation behavior |
| `tags` | Resource tags |

---

# Outputs

Typical outputs include:

```hcl
output "transit_gateway_id"

output "transit_gateway_arn"

output "transit_gateway_owner_id"
```

These outputs are later consumed by:

- RAM Share Module
- Root Module
- Remote State
- PROD Environment

---

# How This Module Works

Deployment order:

```
Terraform Apply

↓

Transit Gateway Created

↓

Outputs Generated

↓

Root Module

↓

Remote State

↓

PROD Environment
```

The Transit Gateway ID becomes one of the most important outputs in the project.

---

# Why Is The TGW Created Only In DEV?

One question I had during this project was:

> Why don't we create a Transit Gateway in both accounts?

Because a Transit Gateway has a single owner.

Our design is:

```
DEV

↓

Creates TGW

↓

Owns TGW

↓

Shares TGW

↓

PROD Uses TGW
```

Ownership never changes.

The PROD account consumes the shared resource instead of creating another TGW.

---

# Auto Accept Shared Attachments

Our configuration enables:

```hcl
auto_accept_shared_attachments = "enable"
```

Meaning:

```
New Shared Attachment

↓

Automatically Accepted
```

This removes the need for manual acceptance of newly created shared VPC attachments.

Important:

Changing this setting later does not update existing attachments.

Attachments already in `PendingAcceptance` must be recreated.

---

# Default Association

We enabled:

```hcl
default_route_table_association = "enable"
```

This means every new attachment is automatically associated with the default Transit Gateway Route Table.

Without this setting:

```
Attachment

↓

No Route Table Association

↓

Manual Configuration Required
```

---

# Default Propagation

We also enabled:

```hcl
default_route_table_propagation = "enable"
```

This automatically propagates attached VPC CIDRs into the default Transit Gateway Route Table.

Example:

```
DEV VPC

10.0.0.0/16

↓

Propagation

↓

TGW Route Table
```

The same happens for the PROD VPC.

This reduced the amount of Terraform code we needed.

---

# Data Flow

```
Variables

↓

Transit Gateway Module

↓

Transit Gateway

↓

Outputs

↓

Root Module

↓

Remote State

↓

PROD Root Module
```

The TGW module becomes the source of truth for the Transit Gateway ID.

---

# Design Decisions

## Single Responsibility

This module creates only:

```
Transit Gateway
```

It does not create:

- RAM Shares
- TGW Attachments
- Routes
- VPCs

Each responsibility has its own module.

---

## Reusable

The module contains no environment-specific logic.

It can be used in:

- DEV
- Shared Services
- Network Hub
- Production Hub

Only variables change.

---

## Automatic Route Management

Instead of manually creating TGW route table associations and propagations, we rely on AWS defaults.

This simplifies deployment while still allowing custom route tables in the future if required.

---

# Common Mistakes

## Creating Multiple Transit Gateways

Wrong

```
DEV

↓

TGW

PROD

↓

TGW
```

Correct

```
One Transit Gateway

↓

Shared

↓

Multiple Accounts
```

---

## Confusing Ownership

Sharing a Transit Gateway through AWS RAM does not transfer ownership.

DEV remains the owner.

---

## Expecting Routes to Appear in VPC Route Tables

The Transit Gateway module manages the Transit Gateway only.

Terraform still needs:

```
aws_route
```

inside each VPC Route Table.

---

## Thinking Attachments Are Created Here

No.

Attachments belong in:

```
modules/tgw-attachment
```

Keeping them separate improves module reuse.

---

# Lessons Learned

While building this project I learned:

- Transit Gateway is a central networking hub.
- One account owns the Transit Gateway.
- Other accounts consume it through AWS RAM.
- Default association and propagation simplify configuration.
- Outputs allow other modules and environments to discover the Transit Gateway.

---

# Future Improvements

Possible enhancements include:

- Multiple Transit Gateway Route Tables
- Network Segmentation
- Inspection VPC
- Direct Connect Gateway
- VPN Attachments
- Multicast Domains
- Cross-Region Peering

---

# Related Documentation

- `docs/08-Transit-Gateway.md`
- `docs/09-AWS-RAM.md`
- `docs/10-Cross-Account-TGW.md`
- `docs/11-Routing.md`
- `modules/tgw-attachment/README.md`
- `modules/ram-share/README.md`
