# Deployment SOP – AWS Cross-Account Transit Gateway using Terraform

## Purpose

This document describes the deployment order for the complete Cross-Account Transit Gateway environment.

The order is important because several resources depend on infrastructure created in previous steps.

---

# Prerequisites

Before deploying the infrastructure, ensure the following:

- AWS CLI installed
- Terraform installed
- Git installed
- AWS credentials configured
- Remote backend bucket created
- DynamoDB lock table created

---

# Deployment Flow

```
Bootstrap

↓

DEV Infrastructure

↓

Transit Gateway

↓

RAM Share

↓

PROD Infrastructure

↓

RAM Acceptance

↓

TGW Attachment

↓

Routes

↓

Connectivity Test
```

---

# Phase 1 – Bootstrap

## Objective

Create the Terraform backend infrastructure.

Resources:

- S3 Bucket
- DynamoDB Lock Table

Directory:

```
live/bootstrap/dev
```

Run:

```bash
terraform init
terraform plan
terraform apply
```

Repeat for:

```
live/bootstrap/prod
```

At the end of this phase both environments have their own remote backend.

---

# Phase 2 – Deploy DEV Environment

Directory

```
live/dev
```

Run

```bash
terraform init
terraform plan
terraform apply
```

Resources created:

- VPC
- Public Subnets
- Private Subnets
- Internet Gateway
- Route Tables
- Security Groups
- IAM Instance Profile
- EC2
- VPC Endpoints
- Transit Gateway
- TGW Attachment
- RAM Share

At this point the DEV environment owns the Transit Gateway.

---

# Phase 3 – Verify Transit Gateway

Verify TGW exists.

```bash
aws ec2 describe-transit-gateways \
--region us-west-2
```

Expected:

```
State

available
```

---

# Phase 4 – Verify RAM Share

Verify Resource Share.

```bash
aws ram get-resource-shares \
--resource-owner SELF
```

Expected:

```
ACTIVE
```

---

# Phase 5 – Deploy PROD

Directory

```
live/prod
```

Run

```bash
terraform init
terraform plan
terraform apply
```

Resources created

- VPC
- Public Subnets
- Private Subnets
- Security Groups
- EC2

The Transit Gateway is **not** created here.

Instead, the configuration reads the TGW ID from the DEV remote state and uses the shared Transit Gateway.

---

# Phase 6 – Accept RAM Share

If the Transit Gateway is shared manually, accept the RAM invitation.

If

```hcl
auto_accept_shared_attachments = "enable"
```

is configured on the Transit Gateway, **new** shared attachments are accepted automatically.

> Note: Enabling Auto Accept later does **not** change existing attachments. Existing `PendingAcceptance` attachments must be deleted and recreated.

---

# Phase 7 – Create TGW Attachment

Terraform creates the VPC attachment.

```
PROD VPC

↓

Transit Gateway Attachment

↓

Shared Transit Gateway
```

Verify:

```bash
aws ec2 describe-transit-gateway-vpc-attachments \
--region us-west-2
```

Expected:

```
State

available
```

---

# Phase 8 – Create Routes

## DEV

Terraform updates the private route tables.

```
Destination

PROD VPC CIDR

↓

Transit Gateway
```

## PROD

Terraform updates the private route tables.

```
Destination

DEV VPC CIDR

↓

Transit Gateway
```

Example resource:

```hcl
resource "aws_route" "this" {

  for_each = var.private_route_table_ids

  route_table_id = each.value

  destination_cidr_block = var.destination_cidr_block

  transit_gateway_id = var.transit_gateway_id

}
```

### Why `each.value`?

`private_route_table_ids` is a map.

Example:

```hcl
{
  private_subnet-a = "rtb-123"
  private_subnet-b = "rtb-456"
}
```

Terraform loops over each element:

```
each.key

private_subnet-a

↓

Logical Name
```

```
each.value

rtb-123

↓

Actual Route Table ID
```

AWS requires the Route Table ID, therefore:

```hcl
route_table_id = each.value
```

---

# Phase 9 – Verify Routes

DEV

```bash
aws ec2 describe-route-tables
```

Verify route:

```
Destination

PROD CIDR

↓

Transit Gateway
```

PROD

Verify route:

```
Destination

DEV CIDR

↓

Transit Gateway
```

---

# Phase 10 – Verify TGW Route Table

Check:

```bash
aws ec2 search-transit-gateway-routes \
--transit-gateway-route-table-id <tgw-rtb-id>
```

Expected:

- DEV VPC propagated
- PROD VPC propagated

Because the Transit Gateway was created with:

```hcl
default_route_table_association = "enable"

default_route_table_propagation = "enable"
```

AWS automatically associates new attachments with the default TGW route table and propagates their routes. This affects the TGW route table only; it does **not** add routes to your VPC route tables, which Terraform manages separately. :contentReference[oaicite:0]{index=0}

---

# Phase 11 – Connectivity Test

SSH into DEV EC2.

Ping PROD.

SSH into PROD EC2.

Ping DEV.

Verify:

- ICMP
- Security Groups
- Route Tables
- TGW Attachment
- TGW Route Table

---

# Common Issues

## Attachment PendingAcceptance

Cause:

Auto Accept disabled when attachment was created.

Solution:

Delete attachment.

Recreate attachment.

---

## InvalidTransitGatewayID.NotFound

Cause:

Attachment not created.

Wrong region.

Wrong account.

Solution:

Verify TGW ID from remote state.

Verify attachment exists.

---

## No Connectivity

Check:

- Security Groups
- NACLs
- Route Tables
- TGW Attachment
- Route Propagation

---

## Mental Model

Think of the deployment as building a highway.

```
Step 1

Build the highway

↓

Transit Gateway

Step 2

Connect cities

↓

TGW Attachments

Step 3

Install road signs

↓

Route Tables

Step 4

Drive

↓

EC2 Communication
```

Without any one of these steps, traffic cannot reach the destination.

---

# Lessons Learned

- Bootstrap before everything else.
- Deploy the TGW owner account first.
- Share the Transit Gateway before attaching from another account.
- Create VPC routes after attachments exist.
- Understand the difference between VPC route tables and TGW route tables.
- `for_each` with `each.value` is used because AWS expects resource IDs, not logical names.
