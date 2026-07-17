# Chapter 12 – Troubleshooting Guide

## Purpose

Every Terraform project eventually encounters issues.

The goal of this document is not just to list errors, but to explain:

- Why the error occurred
- How to identify it
- How to fix it
- How to avoid it next time

Every issue documented here was encountered during the implementation of this Cross-Account Transit Gateway project.

---

# Troubleshooting Mindset

Whenever something doesn't work, don't immediately change Terraform code.

Instead, ask these questions in order.

```
Terraform

↓

AWS Resources

↓

Networking

↓

Security

↓

Application
```

Most networking issues can be solved by following a structured approach instead of guessing.

---

# Problem 1

## TGW Attachment stuck in PendingAcceptance

### Symptom

```
State

↓

PendingAcceptance
```

### Root Cause

The attachment was created before

```hcl
auto_accept_shared_attachments = "enable"
```

was enabled on the Transit Gateway.

Auto Accept only applies to **newly created** shared attachments. Existing attachments remain in their original state. :contentReference[oaicite:0]{index=0}

### Solution

Delete the attachment.

Recreate it.

Terraform

```
Destroy

↓

Create

↓

Available
```

---

# Problem 2

## PROD Cannot See Transit Gateway

### Symptom

```
InvalidTransitGatewayID.NotFound
```

or

```
Transit Gateway not found
```

### Root Cause

One of the following:

- RAM Share not created
- Resource Association missing
- Principal Association missing
- RAM invitation not accepted

### Checklist

```
TGW Exists?

↓

RAM Share Exists?

↓

TGW Added to Share?

↓

PROD Account Added?

↓

Invitation Accepted?
```

---

# Problem 3

## EC2 Cannot Ping Remote VPC

### Symptom

```
Ping Timeout
```

### Troubleshooting Order

Step 1

Security Group

↓

Allow ICMP?

Step 2

VPC Route Table

↓

Correct CIDR?

↓

Transit Gateway Target?

Step 3

TGW Attachment

↓

Available?

Step 4

TGW Route Table

↓

Routes Propagated?

Step 5

Destination Security Group

↓

Allow ICMP?

The VPC route table must send traffic to the Transit Gateway, and the TGW route table must know which attachment should receive that traffic. Both layers must be correct. :contentReference[oaicite:1]{index=1}

---

# Problem 4

## Terraform Plan Shows No Changes

### Symptom

```
No changes.

Infrastructure matches configuration.
```

### Root Cause

Terraform state already matches AWS.

Nothing needs to be created.

### Verification

```
terraform state list
```

Compare with

```
terraform plan
```

If the resource exists in state and configuration hasn't changed, Terraform correctly reports no changes.

---

# Problem 5

## String vs map(string)

One of the biggest mistakes during this project.

Wrong

```hcl
receiver_account_ids = local.account_ids.prod
```

This returns

```
031679887831
```

A string.

Module expected

```
map(string)
```

Correct

```hcl
receiver_account_ids = local.tgw_share_receivers
```

Returns

```hcl
{

prod = "031679887831"

}
```

Lesson

Always verify variable types.

---

# Problem 6

## each.key vs each.value

Initially I thought

```
each.key

↓

Route Table ID
```

Wrong.

Reality

```
each.key

↓

private_subnet-a

each.value

↓

rtb-xxxxxxxx
```

AWS APIs require the Route Table ID.

Therefore

```hcl
route_table_id = each.value
```

---

# Problem 7

## Route Missing

Symptom

```
TGW Attachment

↓

Available

↓

Still No Connectivity
```

Root Cause

Forgot

```hcl
resource "aws_route"
```

inside the VPC Route Table.

Remember

Propagation updates only the TGW Route Table.

Terraform must still update the VPC Route Tables. :contentReference[oaicite:2]{index=2}

---

# Problem 8

## TGW Route Table Empty

Possible Causes

```
Propagation Disabled

OR

Attachment Not Associated

OR

Attachment Not Available
```

Check

```
Transit Gateway

↓

Route Table

↓

Propagations
```

AWS automatically propagates VPC CIDRs only when propagation is enabled for the attachment. :contentReference[oaicite:3]{index=3}

---

# Problem 9

## Remote State Output Not Found

Wrong

```hcl
module.transit-gateway.transit_gateway_id
```

inside PROD.

Correct

```hcl
data.terraform_remote_state.dev.outputs.transit_gateway_id
```

Reason

Different Root Modules

↓

Different State Files

↓

Need Remote State

---

# Problem 10

## lookup() vs Direct Index

Wrong Mental Model

```
Always Use lookup()
```

Correct

Use

```hcl
lookup(...)
```

only when the key may not exist.

Use

```hcl
map[key]
```

when the key must exist.

This project used direct indexing because missing subnet keys should fail fast.

---

# Problem 11

## for_each Confusion

Terraform

```hcl
for_each = {

private_subnet-a = rtb-111

private_subnet-b = rtb-222

}
```

Iteration 1

```
each.key

↓

private_subnet-a

each.value

↓

rtb-111
```

Iteration 2

```
each.key

↓

private_subnet-b

each.value

↓

rtb-222
```

Understanding the data structure solved most of the confusion.

---

# Problem 12

## Why Didn't Terraform Create TGW Routes?

Because

```hcl
default_route_table_association = "enable"

default_route_table_propagation = "enable"
```

AWS automatically associated the attachment with the default Transit Gateway Route Table and propagated the VPC CIDRs.

Terraform only managed

```
VPC Route Tables
```

This behavior is expected when default association and propagation are enabled. :contentReference[oaicite:4]{index=4}

---

# General Troubleshooting Checklist

Whenever networking fails

```
1.

Terraform Apply Successful?

↓

2.

TGW Exists?

↓

3.

RAM Shared?

↓

4.

Invitation Accepted?

↓

5.

TGW Attachment Available?

↓

6.

VPC Routes Correct?

↓

7.

TGW Routes Present?

↓

8.

Security Groups Allow Traffic?

↓

9.

NACLs Blocking?

↓

10.

Ping Again
```

Following the same checklist every time avoids random debugging.

---

# Best Practices Learned

- Always verify the Terraform state before making changes.
- Validate variable types (`string` vs `map(string)`).
- Prefer outputs over hardcoded resource IDs.
- Use Remote State for communication between Root Modules.
- Verify VPC Route Tables before checking TGW Route Tables.
- Understand that TGW propagation and VPC routing are separate responsibilities.
- Read Terraform plans carefully before applying.
- Test connectivity one layer at a time.

AWS recommends minimizing the number of Transit Gateway route tables unless segmentation is required and using a structured design to simplify troubleshooting. :contentReference[oaicite:5]{index=5}

---

# Final Troubleshooting Flow

```
Terraform

↓

State

↓

AWS Resources

↓

Transit Gateway

↓

Attachments

↓

VPC Route Tables

↓

TGW Route Tables

↓

Security Groups

↓

Network ACLs

↓

EC2 Communication
```

---

# Key Takeaway

The biggest lesson from this project was:

**Don't guess. Verify one layer at a time.**

Every networking problem has a cause.

If you check the infrastructure in a consistent order, you'll usually find the problem much faster than making random configuration changes.
