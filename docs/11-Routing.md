# Chapter 11 – Understanding Routing

## Purpose

During this project, routing was the most confusing topic.

Initially I thought:

> "If the Transit Gateway already knows about both VPCs, why do I still need aws_route?"

Later I understood there are **two completely different routing layers**.

- VPC Route Tables
- Transit Gateway Route Tables

Once I understood the difference, the entire network made sense.

---

# The Two Routing Layers

```
+-------------------------+
|     VPC Route Table     |
+-------------------------+

            |

            v

+-------------------------+
|   Transit Gateway RT    |
+-------------------------+
```

Both are required.

Neither replaces the other.

---

# Layer 1 – VPC Route Table

Every VPC has one or more route tables.

Their job is simple:

> Decide where traffic should leave the VPC.

Example

```
Destination

10.1.0.0/16

↓

Transit Gateway
```

This is exactly what Terraform created.

```hcl
resource "aws_route" "this" {

  for_each = var.private_route_table_ids

  route_table_id = each.value

  destination_cidr_block = var.destination_cidr_block

  transit_gateway_id = var.transit_gateway_id

}
```

---

# Why Did We Use for_each?

Our VPC had multiple private route tables.

Terraform output

```hcl
{
  private_subnet-a = "rtb-111"
  private_subnet-b = "rtb-222"
}
```

Terraform loops.

Iteration 1

```
route_table_id

↓

rtb-111
```

Iteration 2

```
route_table_id

↓

rtb-222
```

Every private route table receives the same destination CIDR pointing to the Transit Gateway.

---

# Layer 2 – Transit Gateway Route Table

The Transit Gateway has its own routing table.

Its responsibility is completely different.

It answers:

```
Traffic has arrived.

↓

Which attachment should receive it?
```

The TGW Route Table never tells an EC2 instance where to send traffic.

It only decides where to forward traffic **after it reaches the Transit Gateway**. :contentReference[oaicite:1]{index=1}

---

# Packet Journey

Imagine an EC2 in DEV.

Destination

```
10.1.0.10
```

Flow

```
EC2

↓

VPC Route Table

↓

TGW Attachment

↓

Transit Gateway

↓

TGW Route Table

↓

PROD Attachment

↓

PROD VPC

↓

EC2
```

Notice

Traffic must pass BOTH routing layers.

---

# Why Didn't We Create TGW Routes?

This question confused me during the lab.

I expected Terraform to create routes inside the Transit Gateway.

It didn't.

Why?

Because our Transit Gateway was created with

```hcl
default_route_table_association = "enable"

default_route_table_propagation = "enable"
```

AWS automatically:

- Associated new attachments with the default TGW Route Table.
- Propagated VPC CIDRs into that route table.

Therefore we didn't need separate Terraform resources to manage the default TGW Route Table. :contentReference[oaicite:2]{index=2}

---

# Association

Association answers one question.

```
Which TGW Route Table
should this attachment use?
```

Think of association as:

```
Attachment

↓

Assigned

↓

Route Table
```

One attachment can be associated with only **one** Transit Gateway Route Table. :contentReference[oaicite:3]{index=3}

---

# Propagation

Propagation answers another question.

```
Which CIDRs
should appear
inside the TGW Route Table?
```

Example

DEV VPC

```
10.0.0.0/16

↓

Propagate

↓

TGW Route Table
```

PROD VPC

```
10.1.0.0/16

↓

Propagate

↓

TGW Route Table
```

Now the Transit Gateway knows where both networks are located. :contentReference[oaicite:4]{index=4}

---

# Our Configuration

DEV

```
10.0.0.0/16
```

PROD

```
10.1.0.0/16
```

Terraform created

DEV Route Table

```
Destination

10.1.0.0/16

↓

Transit Gateway
```

Terraform created

PROD Route Table

```
Destination

10.0.0.0/16

↓

Transit Gateway
```

AWS automatically created

TGW Route Table

```
10.0.0.0/16

↓

DEV Attachment

10.1.0.0/16

↓

PROD Attachment
```

---

# Why aws_route Was Still Required

One of the biggest lessons.

Some people think

```
Propagation Enabled

↓

Done
```

Wrong.

Propagation updates

```
Transit Gateway Route Table
```

It does NOT update

```
VPC Route Tables
```

Terraform still had to create

```hcl
resource "aws_route"
```

inside every VPC Route Table.

AWS documentation makes this distinction very clear: VPC subnet route tables must contain routes pointing to the Transit Gateway, while TGW route tables determine forwarding between attachments. :contentReference[oaicite:5]{index=5}

---

# Mental Model

Think of a courier service.

```
EC2

↓

Local Reception

(VPC Route Table)

↓

Delivery Hub

(TGW)

↓

Sorting Center

(TGW Route Table)

↓

Delivery Van

(TGW Attachment)

↓

Destination Office

↓

EC2
```

Each component has a different responsibility.

---

# Common Mistakes

## Mistake 1

Thought VPC Route Tables and TGW Route Tables were the same.

Wrong.

They solve different problems.

---

## Mistake 2

Expected Propagation to update VPC Route Tables.

Wrong.

Propagation only affects the TGW Route Table.

---

## Mistake 3

Forgot VPC Route Table entries.

Result

```
EC2

↓

Drops Traffic

↓

Never Reaches TGW
```

---

## Mistake 4

Thought TGW Route Table controls traffic leaving the VPC.

Wrong.

The VPC Route Table decides how traffic leaves the VPC.

The TGW Route Table decides where traffic goes after it reaches the TGW.

---

# Lessons Learned

- Every VPC has its own Route Tables.
- Every Transit Gateway has its own Route Tables.
- VPC Route Tables send traffic to the TGW.
- TGW Route Tables forward traffic between attachments.
- Association chooses which TGW Route Table an attachment uses.
- Propagation advertises VPC CIDRs into the TGW Route Table.
- `aws_route` updates VPC Route Tables, not TGW Route Tables.
- Automatic propagation does not eliminate the need for VPC routes.

---

# Key Takeaway

Think of routing as two decisions.

Decision 1

```
Should traffic leave my VPC?

↓

VPC Route Table
```

Decision 2

```
Which VPC should receive it?

↓

Transit Gateway Route Table
```

If either decision is missing, communication fails.

Understanding these two routing layers was one of the biggest breakthroughs in this project.
