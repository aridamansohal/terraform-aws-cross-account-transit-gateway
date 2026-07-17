# AWS RAM Share Accepter Module

## Overview

This module accepts an AWS Resource Access Manager (RAM) resource share invitation.

It is deployed in the **receiving AWS account**.

In this project:

- DEV creates the Transit Gateway
- DEV creates the RAM Share
- PROD accepts the RAM Share

Only after the invitation is accepted can the shared Transit Gateway be used by the PROD account.

---

# Purpose

Sharing a resource does **not** automatically make it available.

AWS first creates an invitation.

```
DEV

↓

Create RAM Share

↓

Invitation

↓

PROD

↓

Accept Invitation

↓

Shared Resource Available
```

This module performs that acceptance.

---

# Resources Created

This module creates:

```
aws_ram_resource_share_accepter
```

Its responsibility is very small but extremely important.

Without it, the receiving account cannot use the shared Transit Gateway (unless your AWS Organization is configured to auto-share without invitations).

---

# Module Architecture

```
              DEV Account

                   │

                   ▼

          Resource Share

                   │

                   ▼

           RAM Invitation

                   │

                   ▼

             PROD Account

                   │

                   ▼

    Resource Share Accepter

                   │

                   ▼

      Transit Gateway Visible
```

---

# Deployment Order

This module always runs **after**:

```
Transit Gateway Module

↓

RAM Share Module

↓

Invitation Created

↓

RAM Share Accepter Module
```

Only then can the attachment module begin.

---

# Inputs

Typical inputs include:

| Variable | Description |
|----------|-------------|
| `share_arn` | ARN of the RAM Resource Share |

Example:

```hcl
module "ram_share_accepter" {

  share_arn =
    data.aws_ram_resource_share.shared.arn

}
```

The required input is the Resource Share ARN. :contentReference[oaicite:1]{index=1}

---

# Outputs

Typical outputs include:

```hcl
output "share_id"

output "status"

output "receiver_account_id"

output "sender_account_id"
```

These outputs are useful when troubleshooting cross-account sharing.

---

# Data Flow

```
DEV

↓

Create Resource Share

↓

Invitation

↓

PROD

↓

Accept Invitation

↓

Transit Gateway Visible
```

Notice

No networking exists yet.

Only visibility.

---

# What Happens After Acceptance?

Many engineers think

```
Accepted

↓

Networking Works
```

Wrong.

Acceptance only gives the receiving account access to the shared resource.

The remaining steps are:

```
Accept Invitation

↓

Create TGW Attachment

↓

Create VPC Routes

↓

Traffic Flows
```

---

# Design Decisions

## Single Responsibility

This module performs exactly one action:

```
Accept RAM Invitation
```

It does not:

- Create Transit Gateway
- Create Resource Share
- Create TGW Attachment
- Create Routes

Each responsibility has its own module.

---

## Separate From RAM Share

Why not combine both modules?

Because they run in different AWS accounts.

```
DEV

↓

Creates Share
```

```
PROD

↓

Accepts Share
```

Keeping them separate mirrors the real AWS ownership model.

---

# Common Mistakes

## Mistake 1

Thinking the invitation is accepted automatically.

Not always.

Outside of AWS Organizations (or when Organization sharing is not enabled), the receiving account must explicitly accept the invitation. :contentReference[oaicite:2]{index=2}

---

## Mistake 2

Trying to create a TGW Attachment before acceptance.

Result

```
Transit Gateway

↓

Not Visible

↓

Attachment Fails
```

Always accept first.

---

## Mistake 3

Confusing RAM acceptance with TGW attachment.

RAM

↓

Shares Resource

TGW Attachment

↓

Connects Network

These are two completely different operations.

---

## Mistake 4

Thinking ownership changes.

Even after acceptance:

```
DEV

↓

Owns Transit Gateway

PROD

↓

Uses Transit Gateway
```

Ownership never changes.

---

# Lessons Learned

While building this project I learned:

- Sharing and accepting are separate AWS operations.
- Accepting a RAM Share only makes the resource visible.
- Networking begins only after creating the TGW Attachment.
- Separating sender and receiver modules keeps the project easier to understand.

---

# Future Improvements

Possible enhancements include:

- Conditional acceptance for AWS Organizations
- Validation that the share exists before accepting
- Automatic tagging of accepted shares
- Support for additional shared resource types

---

# Related Documentation

- `modules/transit-gateway/README.md`
- `modules/ram-share/README.md`
- `modules/tgw-attachment/README.md`
- `docs/09-AWS-RAM.md`
- `docs/10-Cross-Account-TGW.md`
