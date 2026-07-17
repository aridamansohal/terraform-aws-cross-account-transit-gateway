# Chapter 06 – Root Module vs Child Module

## Purpose

When I first started learning Terraform, I thought every folder containing `.tf` files was the same.

Later I realized Terraform has two very different concepts:

- Root Module
- Child Module

Understanding this completely changed how I design Terraform projects.

This chapter explains the difference using the exact project structure from this repository.

---

# Every Terraform Directory is a Module

Terraform treats every directory containing `.tf` files as a module.

Example

```
live/dev

↓

Module
```

```
modules/vpc

↓

Module
```

```
modules/ec2

↓

Module
```

A module is simply a collection of Terraform configuration files stored together in one directory. :contentReference[oaicite:0]{index=0}

---

# What is a Root Module?

The Root Module is the directory where you execute Terraform.

Example

```bash
cd live/dev

terraform init
terraform plan
terraform apply
```

Because Terraform is executed inside

```
live/dev
```

Terraform considers this directory to be the Root Module. :contentReference[oaicite:1]{index=1}

---

# In Our Project

We actually have multiple Root Modules.

```
live/

├── bootstrap/dev
├── bootstrap/prod
├── dev
└── prod
```

Each directory has its own:

- Backend
- State File
- Variables
- Outputs
- Providers

Each one can be executed independently.

---

# What is a Child Module?

A Child Module is a reusable module called by another module.

Example

```hcl
module "vpc" {

  source = "../../modules/vpc"

}
```

Terraform loads

```
modules/vpc
```

creates everything inside it

then returns the outputs.

The root module calls child modules using `module` blocks. Child modules are reusable building blocks. :contentReference[oaicite:2]{index=2}

---

# Our Repository

```
live/dev

↓

Calls

↓

modules/vpc

↓

Creates

↓

VPC
```

```
live/dev

↓

Calls

↓

modules/transit-gateway

↓

Creates

↓

Transit Gateway
```

```
live/dev

↓

Calls

↓

modules/ec2

↓

Creates

↓

EC2
```

The Root Module orchestrates everything.

The Child Modules perform the work.

---

# Why Use Child Modules?

Imagine writing everything inside one file.

```
main.tf

5000 lines
```

Impossible to maintain.

Instead we divide responsibilities.

```
VPC

↓

One Module
```

```
EC2

↓

One Module
```

```
Security Groups

↓

One Module
```

```
Transit Gateway

↓

One Module
```

Now every module has one responsibility.

---

# Real Example

Root Module

```hcl
module "vpc" {

  source = "../../modules/vpc"

}
```

Terraform loads

```
modules/vpc
```

Inside

```
modules/vpc/main.tf
```

Terraform creates

```
aws_vpc

aws_subnet

aws_route_table

aws_internet_gateway
```

Then returns outputs.

---

# Data Flow

One of the biggest things I learned.

```
Root Module

↓

Input Variables

↓

Child Module

↓

Creates Resources

↓

Outputs

↓

Root Module
```

The Root Module is responsible for connecting modules together.

Child Modules never directly communicate with each other. They exchange information through the Root Module using variables and outputs. :contentReference[oaicite:3]{index=3}

---

# Why Modules Cannot Talk Directly

Initially I thought

```
VPC Module

↓

TGW Module
```

could directly exchange data.

Wrong.

Correct flow

```
VPC Module

↓

Outputs

↓

Root Module

↓

Input Variables

↓

TGW Module
```

Terraform intentionally isolates modules.

---

# Our VPC Example

VPC Module returns

```hcl
output "vpc_id" {

    value = aws_vpc.main.id

}
```

Root Module receives

```hcl
module.vpc.vpc_id
```

Then passes it

```hcl
module "tgw-attachment" {

  vpc_id = module.vpc.vpc_id

}
```

Nothing magical.

The Root Module simply connects both modules.

---

# Remote State

Another important lesson.

```
live/dev

↓

State File
```

```
live/prod

↓

Different State File
```

Since these are different Root Modules

they cannot directly access each other's resources.

Instead

```
DEV

↓

Outputs

↓

Remote State

↓

PROD
```

Only Root Module outputs are available through Remote State. :contentReference[oaicite:4]{index=4}

---

# Child Modules Should Be Reusable

Notice our VPC module never says

```
DEV
```

or

```
PROD
```

It only receives

```
Variables
```

That makes it reusable.

The same module works for

- DEV

- PROD

- QA

- TEST

No code changes.

---

# Why Did We Create So Many Modules?

Our project contains

```
modules/

vpc/

ec2/

sg/

transit-gateway/

ram-share/

tgw-attachment/

vpc-endpoint/
```

Every module has one responsibility.

This follows the principle of modular infrastructure design.

---

# Mental Model

Think of the Root Module as a Project Manager.

```
Project Manager

↓

Assigns Work

↓

VPC Team

↓

EC2 Team

↓

TGW Team

↓

Security Team
```

Each team performs one job.

The Project Manager coordinates everything.

---

# Repository Structure

```
terraform-tgw-lab

│

├── live

│   ├── dev

│   ├── prod

│   └── bootstrap

│

└── modules

    ├── vpc

    ├── ec2

    ├── sg

    ├── transit-gateway

    ├── tgw-attachment

    └── ...
```

This structure follows Terraform's recommended separation between environment-specific root modules and reusable child modules. :contentReference[oaicite:5]{index=5}

---

# Common Mistakes

## Mistake 1

Trying to access a resource directly from another module.

Wrong

```
module.ec2

↓

module.vpc.resource
```

Correct

```
module.vpc

↓

Output

↓

Root Module

↓

Input Variable

↓

module.ec2
```

---

## Mistake 2

Hardcoding values.

Wrong

```
subnet_id = "subnet-123"
```

Correct

```
subnet_id = module.vpc.private_subnets_ids[var.subnet_key]
```

---

## Mistake 3

Thinking every folder shares the same state.

Wrong.

Each Root Module has its own independent state.

---

# Lessons Learned

- Every directory containing `.tf` files is a module.
- The directory where Terraform is executed is the Root Module.
- Child Modules are reusable building blocks.
- Child Modules never communicate directly.
- Outputs return data from Child Modules.
- Variables send data into Child Modules.
- Root Modules connect Child Modules together.
- Separate Root Modules communicate through Remote State.
- Good Terraform projects keep reusable logic inside modules.

---

# Key Takeaway

The biggest lesson from this chapter is:

```
Root Module

↓

Coordinates

↓

Child Modules

↓

Create Infrastructure

↓

Return Outputs

↓

Root Module

↓

Passes Outputs

↓

Another Child Module
```

Once you understand this flow, large Terraform projects become much easier to design and maintain.
