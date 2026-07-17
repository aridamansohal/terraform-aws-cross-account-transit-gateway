# Chapter 09 – AWS Resource Access Manager (RAM)

## Purpose

One of the most confusing parts of this project was AWS Resource Access Manager (RAM).

Initially I thought:

> "I only want to share my Transit Gateway."

So why do I need four Terraform resources?

- aws_ram_resource_share
- aws_ram_resource_association
- aws_ram_principal_association
- aws_ram_resource_share_accepter

After implementing the project, I realized each resource has one specific responsibility.

This chapter explains the complete flow.

---

# What is AWS RAM?

AWS Resource Access Manager (RAM) allows one AWS account to share supported AWS resources with another AWS account without transferring ownership.

Examples of resources that can be shared:

- Transit Gateway
- Subnets
- License Manager resources
- Route 53 Resolver Rules
- Many other supported AWS resources

The important point is:

Sharing a resource does NOT transfer ownership.

The owner always remains the account that created the resource. :contentReference[oaicite:0]{index=0}

---

# Why Did We Need RAM?

Our project has two AWS accounts.

```
DEV

↓

Creates Transit Gateway

↓

Owner
```

```
PROD

↓

Needs to use Transit Gateway
```

Without RAM

```
DEV

↓

Transit Gateway

↓

Visible only inside DEV
```

PROD cannot even see it.

RAM solves this problem.

---

# Complete Flow

```
DEV

↓

Create Transit Gateway

↓

Create Resource Share

↓

Add Transit Gateway

↓

Add PROD Account

↓

Invitation

↓

PROD

↓

Accept

↓

Transit Gateway becomes visible
```

This is exactly what happened in our lab.

---

# Step 1

## aws_ram_resource_share

Terraform

```hcl
resource "aws_ram_resource_share" "main" {

    name = "cross-account-tgw"

}
```

Think of this resource as an empty sharing container.

Initially

```
Share

↓

Contains Nothing

↓

Shared With Nobody
```

At this point nothing is actually shared.

---

# Step 2

## aws_ram_resource_association

Terraform

```hcl
resource "aws_ram_resource_association" "main" {

    resource_share_arn = ...

    resource_arn = ...

}
```

This resource places the Transit Gateway into the sharing container.

Think of it like putting a file into a shared folder.

Before

```
Share

↓

Empty
```

After

```
Share

↓

Transit Gateway
```

The share now knows WHAT resource is being shared. :contentReference[oaicite:1]{index=1}

---

# Step 3

## aws_ram_principal_association

Terraform

```hcl
resource "aws_ram_principal_association" "main" {

    principal = "PROD Account"

}
```

This tells AWS WHO can access the share.

Notice something important.

Previously

```
Share

↓

Contains TGW

↓

Nobody can use it
```

Now

```
Share

↓

Transit Gateway

↓

PROD Account
```

The share now knows WHO should receive access. :contentReference[oaicite:2]{index=2}

---

# Step 4

## aws_ram_resource_share_accepter

This resource exists in the receiving account.

Terraform

```hcl
resource "aws_ram_resource_share_accepter" "prod" {

}
```

Its only job is

```
Invitation

↓

Accept
```

After acceptance

```
Transit Gateway

↓

Visible inside PROD
```

When the accounts are outside the same AWS Organization, a resource share invitation must be accepted before the shared resource becomes usable. :contentReference[oaicite:3]{index=3}

---

# Why Four Resources?

Initially I thought

```
Share TGW
```

should be enough.

Actually AWS needs four separate questions answered.

Question 1

```
Create Share?

↓

aws_ram_resource_share
```

Question 2

```
Share WHAT?

↓

aws_ram_resource_association
```

Question 3

```
Share WITH WHOM?

↓

aws_ram_principal_association
```

Question 4

```
Receiver Accepts?

↓

aws_ram_resource_share_accepter
```

Once I understood these four questions,

RAM suddenly became very easy.

---

# Our Project

DEV

Created

```
Transit Gateway
```

DEV

Created

```
RAM Share
```

DEV

Added

```
Transit Gateway
```

DEV

Added

```
PROD Account
```

PROD

Accepted

```
Resource Share
```

PROD

Created

```
TGW Attachment
```

This is the exact order used in this repository.

---

# What Happens After Acceptance?

Many people think

```
Accepted

↓

Done
```

No.

Acceptance only makes the Transit Gateway visible.

You STILL need

```
TGW Attachment
```

Without an attachment

there is still no connectivity.

---

# Auto Accept

Our Transit Gateway was configured with

```hcl
auto_accept_shared_attachments = "enable"
```

This setting applies to

```
TGW Attachments
```

NOT

```
RAM Share
```

This confused me initially.

RAM Invitation

and

TGW Attachment

are two different things.

---

# Visual Flow

```
DEV

↓

Create TGW

↓

Create RAM Share

↓

Add TGW

↓

Add PROD Account

↓

Invitation

↓

PROD Accepts

↓

TGW Visible

↓

Create TGW Attachment

↓

Available

↓

Routing

↓

Communication
```

This is the complete lifecycle.

---

# Mental Model

Think of AWS RAM like sharing a Google Drive folder.

Step 1

Create Folder

↓

Resource Share

Step 2

Put File Inside

↓

Resource Association

Step 3

Share With Someone

↓

Principal Association

Step 4

Receiver Accepts Invitation

↓

Resource Share Accepter

Only then can the other person see the file.

---

# Common Mistakes

## Mistake 1

Thought Resource Share alone shared the TGW.

Wrong.

It only creates the sharing container.

---

## Mistake 2

Forgot Resource Association.

Result

```
Share

↓

Empty
```

---

## Mistake 3

Forgot Principal Association.

Result

```
Nobody receives access
```

---

## Mistake 4

Thought Accepting RAM automatically created a TGW Attachment.

Wrong.

Acceptance only makes the TGW visible.

Terraform must still create

```
aws_ec2_transit_gateway_vpc_attachment
```

---

# Lessons Learned

- A Resource Share is only a container.
- Resource Association decides WHAT is shared.
- Principal Association decides WHO receives access.
- Resource Share Accepter accepts the invitation.
- RAM never transfers ownership.
- DEV always owns the Transit Gateway.
- PROD only consumes the shared Transit Gateway.
- RAM sharing and TGW attachments are separate processes.

---

# Key Takeaway

Remember these four questions whenever using AWS RAM:

```
Create Share?

↓

Share WHAT?

↓

Share WITH WHOM?

↓

Accept Invitation?
```

If you can answer those four questions, you already understand almost everything about AWS RAM.

```
DEV

↓

Resource Share

↓

Resource Association

↓

Principal Association

↓

Invitation

↓

PROD

↓

Resource Share Accepter

↓

Transit Gateway Visible

↓

TGW Attachment

↓

Network Connectivity
```
