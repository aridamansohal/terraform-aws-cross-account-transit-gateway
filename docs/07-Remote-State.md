# Chapter 07 – Terraform Remote State

## Purpose

One of the biggest questions I had while building this project was:

> If the Transit Gateway is created in the DEV environment, how does the PROD environment know its ID?

The answer is **Terraform Remote State**.

This chapter explains why Remote State exists, how it works, and why it was required in this project.

---

# What is Terraform State?

Every time Terraform creates infrastructure, it records what it created in a **state file**.

Example:

```
terraform apply

↓

AWS Resources Created

↓

terraform.tfstate
```

The state file contains information such as:

- VPC IDs
- Subnet IDs
- Route Table IDs
- Transit Gateway IDs
- EC2 IDs

Terraform uses this information to understand what already exists.

Terraform stores infrastructure state and uses it to map configuration to real-world resources. :contentReference[oaicite:0]{index=0}

---

# Local State vs Remote State

## Local State

```
terraform.tfstate

↓

Stored on your laptop
```

Problems:

- Difficult to share with a team
- Easy to lose
- No state locking

---

## Remote State

```
Terraform

↓

S3 Bucket

↓

terraform.tfstate
```

Benefits:

- Shared by the team
- Durable
- State locking with DynamoDB
- Single source of truth

This is exactly why we created the bootstrap environment first.

Remote state allows multiple users and Terraform configurations to safely share state information. :contentReference[oaicite:1]{index=1}

---

# Why Did We Need Remote State?

Our project has **two independent Terraform environments**.

```
live/dev

↓

State A
```

```
live/prod

↓

State B
```

Each root module has its own state file.

Terraform does **not** automatically allow one state file to access another.

---

# Our Problem

DEV created:

```
Transit Gateway

↓

tgw-04e40978a8395fba5
```

PROD needed:

```
Transit Gateway ID
```

But PROD never created it.

So how can PROD know the ID?

Remote State.

---

# Solution

DEV exports the Transit Gateway ID.

```hcl
output "transit_gateway_id" {
  value = module.transit-gateway.transit_gateway_id
}
```

Notice something important.

This output exists in the **Root Module**, not only inside the child module.

Only **Root Module outputs** are accessible through `terraform_remote_state`. Child module outputs must be passed through the root module first. :contentReference[oaicite:2]{index=2}

---

# Reading Remote State

Inside PROD:

```hcl
data "terraform_remote_state" "dev" {

  backend = "s3"

  config = {
    bucket = "terraform-state-bucket"
    key    = "dev/terraform.tfstate"
    region = "us-west-2"
  }

}
```

Terraform downloads the latest DEV state.

---

# Accessing Outputs

Terraform exposes every Root Module output through:

```hcl
data.terraform_remote_state.dev.outputs
```

Example:

```hcl
data.terraform_remote_state.dev.outputs.transit_gateway_id
```

Returns

```
tgw-04e40978a8395fba5
```

Exactly the ID that DEV created.

---

# Complete Flow

```
DEV Root Module

↓

Creates TGW

↓

Output

↓

State File

↓

S3 Backend

↓

Remote State

↓

PROD Root Module

↓

Reads Output

↓

Uses TGW ID
```

This is the complete data flow.

---

# Our Project

Inside DEV

```
Transit Gateway

↓

Output

↓

Remote State
```

Inside PROD

```
Remote State

↓

Reads

↓

Transit Gateway ID

↓

Creates TGW Attachment
```

Without Remote State

PROD would never know which Transit Gateway to attach to.

---

# Why Not Hardcode the ID?

Bad

```hcl
transit_gateway_id = "tgw-04e40978a8395fba5"
```

Problems:

- Changes require manual updates
- Error-prone
- Not reusable

Good

```hcl
transit_gateway_id =
data.terraform_remote_state.dev.outputs.transit_gateway_id
```

Terraform always reads the latest value from the DEV state.

---

# What Can Remote State Read?

Remote State can read:

- VPC IDs
- Subnet IDs
- Security Group IDs
- TGW IDs
- Route Table IDs

Anything that is exposed as a **Root Module output**.

It **cannot** directly read resources or child module outputs unless those values are first exported by the root module. :contentReference[oaicite:3]{index=3}

---

# Common Mistake

I initially thought this would work:

```hcl
module.transit-gateway.transit_gateway_id
```

inside the PROD environment.

It doesn't.

Why?

Because the Transit Gateway module exists only in the DEV Root Module.

PROD has a different state file.

Different Root Modules cannot directly access each other's modules.

---

# Why Outputs Matter

Imagine this:

```
Child Module

↓

Creates TGW

↓

No Output
```

Can Remote State access it?

No.

Now:

```
Child Module

↓

Output

↓

Root Module Output

↓

Remote State

↓

PROD
```

Now it works.

Outputs are the bridge between Terraform configurations.

---

# Mental Model

Think of Remote State like a shared notebook.

```
DEV

↓

Writes Notes

↓

Notebook (S3)

↓

PROD

↓

Reads Notes
```

DEV writes.

PROD reads.

Nobody guesses.

Nobody hardcodes.

---

# Best Practices

✅ Keep separate state files for each environment.

✅ Export only useful Root Module outputs.

✅ Use Remote State instead of hardcoded IDs.

✅ Protect the S3 bucket storing state.

✅ Enable DynamoDB locking to avoid concurrent state changes.

---

# Lessons Learned

- Every Root Module has its own state.
- State files are independent.
- Remote State allows one Root Module to read outputs from another.
- Only Root Module outputs are available.
- Child Module outputs must first be passed through the Root Module.
- Remote State keeps configurations loosely coupled while avoiding hardcoded resource IDs.
- Remote State made the DEV → PROD Transit Gateway attachment possible in this project.

---

# Key Takeaway

The biggest lesson from this chapter is:

```
DEV

↓

Creates Infrastructure

↓

Exports Outputs

↓

Remote State

↓

PROD

↓

Consumes Outputs

↓

Creates Dependent Infrastructure
```

Once you understand this flow, you'll understand why Remote State is one of the most powerful features in Terraform for building modular, multi-environment infrastructure.
