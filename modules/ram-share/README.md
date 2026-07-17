# AWS RAM Share Module

## Overview

This module shares AWS resources with another AWS account using **AWS Resource Access Manager (RAM)**.

In this project, the resource being shared is the **AWS Transit Gateway**.

The Transit Gateway is created in the DEV account and shared with the PROD account.

Ownership remains in DEV.

---

# Purpose

Creating a Transit Gateway is not enough.

By default

```
DEV

↓

Transit Gateway

↓

Visible only inside DEV
```

The PROD account cannot see it.

AWS RAM solves this problem.

```
DEV

↓

Transit Gateway

↓

RAM Share

↓

PROD
```

After the share is accepted, the Transit Gateway becomes visible in the receiving account.

---

# Resources Created

This module creates:

```
aws_ram_resource_share

aws_ram_resource_association

aws_ram_principal_association
```

Notice

This module does NOT accept the invitation.

That responsibility belongs to

```
modules/ram-share-accepter
```

---

# Module Architecture

```
             DEV Account

                   │

                   ▼

        Transit Gateway

                   │

                   ▼

      Resource Share

                   │

        ┌──────────┴──────────┐

        ▼                     ▼

 Resource Association   Principal Association

        │                     │

        └──────────┬──────────┘

                   ▼

             RAM Invitation

                   ▼

             PROD Account
```

---

# Why Three Resources?

Initially I thought:

```
Share Transit Gateway
```

should be one Terraform resource.

Actually AWS needs three separate steps.

---

## Step 1

### Resource Share

```hcl
aws_ram_resource_share
```

Creates an empty sharing container.

Initially

```
Share

↓

Empty
```

No resources.

No accounts.

---

## Step 2

### Resource Association

```hcl
aws_ram_resource_association
```

Adds the Transit Gateway.

```
Share

↓

Transit Gateway
```

Now AWS knows

**WHAT**

is being shared. :contentReference[oaicite:1]{index=1}

---

## Step 3

### Principal Association

```hcl
aws_ram_principal_association
```

Adds

```
PROD Account
```

Now AWS knows

**WHO**

receives access.

Without this step,

nobody receives the share. :contentReference[oaicite:2]{index=2}

---

# Inputs

Typical inputs include:

| Variable | Description |
|----------|-------------|
| `resource_share_name` | RAM Share name |
| `transit_gateway_arn` | Transit Gateway ARN |
| `receiver_account_ids` | Accounts receiving the share |
| `allow_external_principals` | Allow external accounts |
| `tags` | Resource tags |

---

# Outputs

Typical outputs include:

```hcl
output "resource_share_arn"

output "resource_share_id"
```

These outputs are useful for troubleshooting and auditing.

---

# Data Flow

```
Variables

↓

RAM Share Module

↓

Resource Share

↓

Transit Gateway Added

↓

Receiver Account Added

↓

Invitation Generated
```

The receiving account then accepts the invitation using the RAM Share Accepter module.

---

# Module Dependencies

This module depends on

```
Transit Gateway Module
```

because it requires

```
Transit Gateway ARN
```

Example

```hcl
module "ram_share" {

    transit_gateway_arn =
    module.transit_gateway.transit_gateway_arn

}
```

The Transit Gateway must already exist before it can be shared.

---

# Design Decisions

## Single Responsibility

This module only creates the share.

It does not:

- Accept invitations
- Create attachments
- Create routes

Those belong in separate modules.

---

## Reusable

This module can share many AWS resources, not just Transit Gateways.

Examples:

- Transit Gateway
- Subnets
- Route53 Resolver Rules
- License Manager resources

Only the resource ARN changes.

---

## Separation of Responsibilities

The module answers three questions:

```
Create Share?

↓

Share WHAT?

↓

Share WITH WHOM?
```

Acceptance happens elsewhere.

---

# Common Mistakes

## Mistake 1

Thinking the Resource Share automatically shares the resource.

Wrong.

You must also create:

```
Resource Association
```

---

## Mistake 2

Forgetting Principal Association.

Result

```
Nobody receives access.
```

---

## Mistake 3

Thinking ownership changes.

Wrong.

```
DEV

↓

Owns TGW

↓

Shares TGW

↓

PROD Uses TGW
```

Ownership never changes. :contentReference[oaicite:3]{index=3}

---

## Mistake 4

Expecting networking to work immediately.

Sharing only makes the Transit Gateway visible.

You still need:

```
RAM Acceptance

↓

TGW Attachment

↓

VPC Routes
```

before traffic can flow.

---

# Lessons Learned

While building this project I learned:

- A Resource Share is only a container.
- Resource Association decides WHAT is shared.
- Principal Association decides WHO receives access.
- Sharing does not transfer ownership.
- RAM sharing is only one step in cross-account networking.

---

# Future Improvements

Possible enhancements include:

- AWS Organizations sharing
- Organizational Unit (OU) sharing
- Multiple receiver accounts
- Customer-managed RAM permissions
- Cross-Region sharing (where supported)

---

# Related Documentation

- `modules/transit-gateway/README.md`
- `modules/ram-share-accepter/README.md`
- `modules/tgw-attachment/README.md`
- `docs/09-AWS-RAM.md`
- `docs/10-Cross-Account-TGW.md`
