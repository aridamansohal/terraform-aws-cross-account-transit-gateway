# Chapter 10 – Cross-Account Transit Gateway Implementation

## Purpose

This chapter brings together everything covered so far.

Instead of learning Transit Gateway, AWS RAM, Remote State and Routing separately, this chapter explains how they work together to build a complete Cross-Account AWS network.

This is the exact architecture implemented in this repository.

---

# Project Architecture

```
                    AWS Organization

         +-----------------------------------+
         |          DEV ACCOUNT              |
         |-----------------------------------|
         |                                   |
         |  VPC                              |
         |  EC2                              |
         |  Transit Gateway (Owner)          |
         |  AWS RAM Share                    |
         |                                   |
         +----------------+------------------+
                          |
                          |
                    AWS RAM Share
                          |
                          |
         +----------------v------------------+
         |          PROD ACCOUNT             |
         |-----------------------------------|
         |                                   |
         |  VPC                              |
         |  EC2                              |
         |  TGW Attachment                   |
         |                                   |
         +-----------------------------------+
```

The DEV account owns the Transit Gateway.

The PROD account consumes the shared Transit Gateway.

Ownership never changes. :contentReference[oaicite:0]{index=0}

---

# Why Build It This Way?

Many beginners ask:

> Why didn't we create one Transit Gateway in DEV and another one in PROD?

Because that creates two isolated networks.

Instead we created one central networking hub.

```
One TGW

↓

Multiple Accounts

↓

Multiple VPCs

↓

Centralized Routing
```

This is the recommended hub-and-spoke architecture for AWS Transit Gateway. :contentReference[oaicite:1]{index=1}

---

# Complete Deployment Flow

```
Bootstrap

↓

DEV Infrastructure

↓

Transit Gateway

↓

RAM Share

↓

Remote State

↓

PROD Infrastructure

↓

Read Remote State

↓

Accept RAM Share

↓

Create TGW Attachment

↓

Create Routes

↓

Connectivity Test
```

Notice something important.

Every step depends on the previous one.

---

# Step 1 – Bootstrap

Before any infrastructure exists

Terraform needs somewhere to store state.

We created

```
S3

↓

Terraform State

+

DynamoDB

↓

State Lock
```

Without this, DEV and PROD cannot safely manage their own infrastructure.

---

# Step 2 – Deploy DEV

Terraform creates

```
VPC

↓

Subnets

↓

Route Tables

↓

Security Groups

↓

EC2

↓

Transit Gateway
```

At this point

DEV owns everything.

---

# Step 3 – Create Transit Gateway

Terraform executes

```
aws_ec2_transit_gateway
```

This creates

```
TGW

↓

Owner = DEV
```

Important

Only the account that creates the Transit Gateway becomes its owner. :contentReference[oaicite:2]{index=2}

---

# Step 4 – Share the Transit Gateway

Terraform creates

```
aws_ram_resource_share
```

↓

Adds

```
Transit Gateway
```

↓

Shares With

```
PROD Account
```

↓

Invitation

↓

Acceptance
```

The Transit Gateway is now visible inside the PROD account.

It is still owned by DEV.

---

# Step 5 – Export Outputs

DEV exports

```hcl
output "transit_gateway_id" {

  value = module.transit-gateway.transit_gateway_id

}
```

This value becomes available through Remote State.

---

# Step 6 – Read Remote State

Inside PROD

Terraform reads

```
DEV State

↓

Outputs

↓

Transit Gateway ID
```

using

```hcl
data "terraform_remote_state"
```

PROD now knows

```
tgw-xxxxxxxx
```

without hardcoding anything.

---

# Step 7 – Deploy PROD

Terraform creates

```
VPC

↓

Subnets

↓

Route Tables

↓

Security Groups

↓

EC2
```

Notice

There is

NO

Transit Gateway resource.

Because the Transit Gateway already exists in DEV.

---

# Step 8 – Create TGW Attachment

Terraform executes

```
aws_ec2_transit_gateway_vpc_attachment
```

Inputs

```
Transit Gateway ID

+

VPC ID

+

Private Subnets
```

Output

```
Attachment
```

Think of this as plugging the PROD VPC into the shared Transit Gateway. Cross-account VPC attachments are created by the VPC owner after the TGW has been shared. :contentReference[oaicite:3]{index=3}

---

# Step 9 – Update VPC Route Tables

Terraform creates

```hcl
resource "aws_route"
```

Inside DEV

```
Destination

PROD CIDR

↓

Transit Gateway
```

Inside PROD

```
Destination

DEV CIDR

↓

Transit Gateway
```

Without these routes

the EC2 instances would never send traffic to the Transit Gateway.

---

# Step 10 – Transit Gateway Route Table

Unlike the VPC Route Tables

we did NOT manually create TGW routes.

Why?

Because we enabled

```hcl
default_route_table_association = "enable"

default_route_table_propagation = "enable"
```

AWS automatically

- Associated each attachment
- Propagated each VPC CIDR

into the default Transit Gateway Route Table. :contentReference[oaicite:4]{index=4}

---

# End-to-End Packet Flow

Suppose

DEV EC2

needs to reach

PROD EC2

```
EC2

↓

Private Route Table

↓

TGW Attachment

↓

Transit Gateway

↓

TGW Route Table

↓

TGW Attachment

↓

Private Route Table

↓

EC2
```

Every packet follows this exact path.

---

# Why Did We Use Modules?

Instead of writing one huge Terraform file

we divided responsibilities.

```
Root Module

↓

VPC Module

↓

TGW Module

↓

RAM Module

↓

Attachment Module

↓

Route Module
```

Each module has a single responsibility.

This makes the project easier to maintain and reuse.

---

# Data Flow

One of the biggest lessons from this project.

```
Variables

↓

Modules

↓

Resources

↓

Outputs

↓

Remote State

↓

Another Root Module

↓

More Resources
```

This is how Terraform moves information through the project.

---

# Where I Was Initially Confused

## Confusion 1

"I created the TGW.

Why can't PROD use it?"

Answer

Because AWS resources are private until shared through AWS RAM. :contentReference[oaicite:5]{index=5}

---

## Confusion 2

"I accepted the RAM share.

Why isn't networking working?"

Answer

Accepting the RAM share only makes the TGW visible.

You still need

```
TGW Attachment
```

---

## Confusion 3

"I created the attachment.

Why can't I ping?"

Answer

The VPC Route Tables still need routes pointing to the Transit Gateway.

---

## Confusion 4

"I don't see TGW routes created by Terraform."

Answer

AWS created them automatically because propagation and association were enabled.

Terraform only managed the VPC Route Tables.

---

# Mental Model

Imagine building a highway.

```
Step 1

Build Highway

↓

Transit Gateway

Step 2

Open Highway

↓

AWS RAM

Step 3

Connect Cities

↓

TGW Attachments

Step 4

Install Road Signs

↓

VPC Route Tables

Step 5

Cars Travel

↓

EC2 Communication
```

If any one of these steps is missing,

communication fails.

---

# Lessons Learned

- A Transit Gateway has only one owner.
- AWS RAM shares the Transit Gateway without transferring ownership.
- Remote State allows independent Terraform environments to exchange outputs.
- Every VPC requires its own TGW attachment.
- VPC Route Tables and TGW Route Tables have different responsibilities.
- Association and Propagation simplify TGW route management.
- Terraform still manages VPC routes explicitly.
- Breaking the solution into reusable modules makes the code easier to understand and maintain.

---

# Key Takeaway

This project can be summarized in one diagram.

```
DEV

↓

Create Transit Gateway

↓

Share via AWS RAM

↓

Export Output

↓

Remote State

↓

PROD

↓

Read Output

↓

Create Attachment

↓

Create Routes

↓

EC2 Communication
```

Once you understand this flow, you understand how a production-style Cross-Account Transit Gateway deployment works with Terraform.
