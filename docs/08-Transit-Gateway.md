# Chapter 08 – AWS Transit Gateway

## Purpose

Transit Gateway (TGW) is the central networking component of this project.

Before learning Transit Gateway, connecting multiple VPCs required creating many individual VPC Peering connections.

As the number of VPCs increased, the network became difficult to manage.

AWS introduced Transit Gateway to solve this problem by acting as a **central network hub**. :contentReference[oaicite:0]{index=0}

---

# The Problem Before Transit Gateway

Imagine three VPCs.

```
DEV

PROD

QA
```

Without Transit Gateway:

```
DEV
 |\

 | \

 |  \

PROD ---- QA
```

Every VPC needs a direct peering connection.

For N VPCs:

```
Connections = N(N-1)/2
```

This quickly becomes difficult to manage.

---

# Transit Gateway Solution

Instead of connecting every VPC to every other VPC:

```
            Transit Gateway

             +-----------+

             |    TGW    |

             +-----------+

            /      |      \

          DEV    PROD     QA
```

Every VPC connects only once.

AWS routes traffic through the Transit Gateway.

This is called the **Hub-and-Spoke** architecture. :contentReference[oaicite:1]{index=1}

---

# Why We Used Transit Gateway

Our project has two AWS accounts.

```
DEV

↓

Owns TGW

↓

Shares TGW

↓

PROD
```

Instead of creating VPC Peering,

we created:

```
DEV VPC

↓

TGW

↓

PROD VPC
```

This design is much easier to expand.

If tomorrow you add QA:

```
QA

↓

Attach to TGW
```

No additional peering connections are required.

---

# Why Does DEV Own the Transit Gateway?

AWS Transit Gateway always has **one owner**.

The AWS account that creates the TGW owns it permanently.

In this project:

```
DEV

↓

Creates

↓

Transit Gateway

↓

Owner
```

PROD never owns the TGW.

It only connects to it.

---

# Why Use AWS RAM?

Resources created in one AWS account are private by default.

DEV created the Transit Gateway.

PROD cannot see it automatically.

AWS Resource Access Manager (RAM) solves this problem.

```
DEV

↓

Transit Gateway

↓

RAM Share

↓

PROD
```

RAM shares the TGW while ownership stays with DEV.

---

# What is a TGW Attachment?

A Transit Gateway cannot communicate with a VPC directly.

Every VPC must create an attachment.

```
VPC

↓

Attachment

↓

Transit Gateway
```

Think of the attachment as a network cable.

Without it,

the VPC is isolated.

---

# Our Architecture

```
             DEV ACCOUNT

      +------------------------+

      |        VPC             |

      +-----------+------------+

                  |

                  |

         TGW Attachment

                  |

                  |

      +-----------v------------+

      |    Transit Gateway     |

      +-----------+------------+

                  |

                  |

         TGW Attachment

                  |

                  |

      +-----------v------------+

      |       PROD VPC         |

      +------------------------+
```

Traffic flows through the attachments.

---

# Packet Flow

Suppose an EC2 instance in DEV wants to reach an EC2 instance in PROD.

```
EC2

↓

Private Route Table

↓

TGW Attachment

↓

Transit Gateway

↓

TGW Attachment

↓

Private Route Table

↓

EC2
```

Every packet follows this path.

---

# VPC Route Tables vs TGW Route Table

This confused me during the project.

There are **two different route tables**.

## 1. VPC Route Tables

Inside every VPC.

Terraform created these routes.

Example:

```
Destination

10.1.0.0/16

↓

Transit Gateway
```

We used:

```hcl
resource "aws_route" "this" {

  for_each = var.private_route_table_ids

  route_table_id = each.value

  destination_cidr_block = var.destination_cidr_block

  transit_gateway_id = var.transit_gateway_id

}
```

These routes tell the VPC:

> "If traffic is going to the remote VPC, send it to the Transit Gateway."

---

## 2. Transit Gateway Route Table

The Transit Gateway has its own route table.

It decides:

```
Traffic arrives

↓

Which attachment should receive it?
```

This is completely different from the VPC route table. TGW route tables determine how traffic moves between attachments, while VPC route tables determine when traffic should be sent to the TGW. :contentReference[oaicite:2]{index=2}

---

# Why Didn't We Create TGW Routes?

One of the biggest discoveries in this project.

When creating the Transit Gateway we enabled:

```hcl
resource "aws_ec2_transit_gateway" "main" {

  auto_accept_shared_attachments = "enable"

  default_route_table_association = "enable"

  default_route_table_propagation = "enable"

}
```

Because these settings were enabled:

- Every new attachment was automatically **associated** with the default TGW route table.
- Every new attachment automatically **propagated** its routes into the default TGW route table. :contentReference[oaicite:3]{index=3}

That is why we **did not** need Terraform resources to manually create TGW routes.

---

# Association vs Propagation

These two concepts confused me initially.

## Association

Association answers:

```
Which TGW Route Table
belongs to this attachment?
```

Think of it as assigning an attachment to a TGW route table.

---

## Propagation

Propagation answers:

```
Which CIDRs
should this attachment advertise
to the TGW Route Table?
```

Example:

```
DEV VPC

10.0.0.0/16

↓

Propagated

↓

TGW Route Table
```

PROD propagates:

```
10.1.0.0/16
```

The TGW Route Table learns both networks automatically.

---

# Why We Still Created aws_route

A common misunderstanding is:

> "If propagation is enabled, why did we create VPC routes?"

Answer:

Propagation updates **only the TGW Route Table**.

It does **not** modify VPC Route Tables.

Terraform still had to create:

```hcl
resource "aws_route"
```

inside each VPC.

Without those routes,

the EC2 instance would never send traffic to the Transit Gateway. This is a common point of confusion and is consistent with AWS networking behavior. :contentReference[oaicite:4]{index=4}

---

# Auto Accept Shared Attachments

We enabled:

```hcl
auto_accept_shared_attachments = "enable"
```

Meaning:

```
New Shared Attachment

↓

Automatically Accepted
```

Important lesson:

Changing this option later does **not** affect existing attachments.

Attachments already in `PendingAcceptance` must be deleted and recreated.

---

# Mental Model

Think of Transit Gateway as an airport.

```
VPC

↓

Flight

↓

Airport

↓

Flight

↓

Another VPC
```

The airport does not create passengers.

The airport simply moves them between flights.

Transit Gateway works exactly the same way.

---

# Common Mistakes

## Mistake 1

Thought TGW automatically updated VPC route tables.

Wrong.

Terraform still needed:

```hcl
aws_route
```

---

## Mistake 2

Confused TGW Route Table with VPC Route Table.

They are two completely different routing layers.

---

## Mistake 3

Enabled Auto Accept after creating attachments.

Existing attachments remained:

```
PendingAcceptance
```

Solution:

Delete

↓

Recreate

---

# Lessons Learned

- Transit Gateway is a network hub.
- Every VPC requires a TGW attachment.
- Only one AWS account owns the TGW.
- AWS RAM shares the TGW with other accounts.
- VPC Route Tables and TGW Route Tables have different responsibilities.
- Association and Propagation are different concepts.
- Propagation updates the TGW Route Table, not the VPC Route Tables.
- Terraform must still create VPC routes with `aws_route`.
- Auto Accept only affects newly created shared attachments.

---

# Key Takeaway

The biggest lesson from this chapter is:

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

TGW Attachment

↓

Destination VPC

↓

EC2
```

Once you understand these layers separately, Transit Gateway becomes much easier to troubleshoot and design.
