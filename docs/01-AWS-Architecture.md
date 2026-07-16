# AWS Architecture

## Purpose

This document explains the AWS architecture used in this project and the reasoning behind every design decision.

The objective is not only to understand **what** was deployed but also **why** each AWS resource exists.

---

# High Level Architecture

```
                     AWS Organization

              +--------------------------+
              |       DEV ACCOUNT        |
              |--------------------------|
              |                          |
              |  VPC                     |
              |  Transit Gateway (Owner) |
              |  AWS RAM Share           |
              |                          |
              +------------+-------------+
                           |
                           |
                    AWS RAM Share
                           |
                           |
              +------------v-------------+
              |      PROD ACCOUNT        |
              |--------------------------|
              |                          |
              |  VPC                     |
              |  TGW Attachment          |
              |                          |
              +--------------------------+
```

---

# Architecture Components

## DEV Account

The DEV account is responsible for creating and owning the networking hub.

Resources created in DEV:

- VPC
- Public Subnets
- Private Subnets
- Route Tables
- Internet Gateway
- Transit Gateway
- AWS RAM Share
- EC2
- Security Groups
- IAM Instance Profile
- VPC Endpoints

The Transit Gateway exists only in this account.

---

## PROD Account

The PROD account consumes the shared Transit Gateway.

Resources created in PROD:

- VPC
- Public Subnets
- Private Subnets
- Route Tables
- Transit Gateway Attachment
- EC2
- Security Groups

The PROD account **does not own** the Transit Gateway.

It only attaches its VPC to the Transit Gateway shared from DEV.

---

# Why is the Transit Gateway created only in DEV?

AWS Transit Gateway can only have one owner.

That owner is the AWS account that creates it.

```
DEV

↓

Creates TGW

↓

Owns TGW

↓

Shares TGW

↓

PROD
```

Even though PROD can use the Transit Gateway, ownership never changes.

---

# Why do we need AWS RAM?

AWS resources are private to the AWS account that creates them.

Without AWS RAM:

```
DEV TGW

↓

Visible only inside DEV
```

With AWS RAM:

```
DEV TGW

↓

AWS RAM Share

↓

PROD can attach its VPC
```

AWS Resource Access Manager allows one AWS account to securely share supported resources, such as a Transit Gateway, with another account without transferring ownership. :contentReference[oaicite:0]{index=0}

---

# Cross Account Connectivity

Traffic Flow

```
EC2

↓

Private Route Table

↓

Transit Gateway Attachment

↓

Transit Gateway

↓

Transit Gateway Attachment

↓

Private Route Table

↓

Destination EC2
```

Every packet follows this path.

---

# Terraform Modules Used

The architecture is implemented using reusable Terraform modules.

```
Root Module

↓

Calls

↓

Child Modules
```

Modules:

- vpc
- transit-gateway
- tgw-attachment
- ram-share
- ram-share-accepter
- transit-gateway-routes
- ec2
- sg
- iam-instance-profile
- vpc-endpoint

Terraform root modules call reusable child modules to organize infrastructure into logical components and improve maintainability. :contentReference[oaicite:1]{index=1}

---

# Route Tables

Both AWS accounts maintain their own route tables.

## DEV

Destination

```
PROD VPC CIDR

↓

Transit Gateway
```

## PROD

Destination

```
DEV VPC CIDR

↓

Transit Gateway
```

Without these routes the Transit Gateway would never receive the traffic.

---

# Transit Gateway Route Table

AWS automatically maintains the Transit Gateway route table when:

- Route propagation is enabled
- Attachments are associated

In this project:

```hcl
default_route_table_association = "enable"

default_route_table_propagation = "enable"
```

Because these options were enabled during Transit Gateway creation, new attachments automatically associate with and propagate routes into the default Transit Gateway route table. :contentReference[oaicite:2]{index=2}

Terraform still creates the VPC route table entries because AWS does **not** automatically add routes to VPC route tables.

---

# Auto Accept Shared Attachments

Configured as:

```hcl
auto_accept_shared_attachments = "enable"
```

Meaning:

```
New Attachment

↓

Automatically Accepted
```

Important:

Changing this setting later does **not** change existing attachments.

Existing attachments must be deleted and recreated if they were created before Auto Accept was enabled.

---

# Ownership Summary

| Resource | DEV | PROD |
|----------|:---:|:----:|
| Transit Gateway | ✅ Owner | ❌ |
| AWS RAM Share | ✅ | ❌ |
| TGW Attachment | ✅ | ✅ |
| VPC | ✅ | ✅ |
| Route Tables | ✅ | ✅ |
| EC2 | ✅ | ✅ |

---

# Mental Model

Think of the Transit Gateway as a **network hub**.

```
               Transit Gateway

                    ▲

         +----------+----------+

         |                     |

      DEV VPC              PROD VPC
```

Every VPC connects to the hub.

The hub itself belongs to only **one AWS account**.

Other AWS accounts **connect** to it—they do not own it.

---

# Common Mistakes

## Mistake 1

Created Transit Gateway.

Forgot to share it.

Result:

```
PROD

Cannot See TGW
```

---

## Mistake 2

Shared Transit Gateway.

Forgot TGW Attachment.

Result:

```
No Connectivity
```

---

## Mistake 3

Attachment existed.

Forgot Route Tables.

Result:

```
Traffic Dropped
```

---

## Mistake 4

Enabled Auto Accept after creating the attachment.

Result:

```
Attachment remained PendingAcceptance
```

Solution:

Delete and recreate the attachment.

---

# Key Takeaways

- One AWS account owns the Transit Gateway.
- AWS RAM shares the Transit Gateway with other accounts.
- Each participating VPC requires its own TGW attachment.
- VPC route tables must explicitly point remote CIDRs to the Transit Gateway.
- Route propagation updates the TGW route table; it does not update VPC route tables.
- Auto Accept applies only to newly created shared attachments.

