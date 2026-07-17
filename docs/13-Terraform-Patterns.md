# Chapter 13 – Terraform Design Patterns

## Purpose

One of the biggest lessons from this project wasn't learning AWS.

It was learning **how to design Terraform**.

Good Terraform isn't about writing resources.

It's about designing reusable patterns.

This chapter documents every important Terraform pattern used in this project.

---

# Pattern 1 – Root Module Orchestrates Everything

## Problem

Many beginners try putting every resource into one folder.

Eventually the project becomes:

```
main.tf

↓

3000+ lines
```

Very difficult to maintain.

---

## Our Solution

```
live/dev

↓

Root Module

↓

Calls

↓

VPC

↓

Security Groups

↓

Transit Gateway

↓

RAM

↓

EC2

↓

VPC Endpoints
```

The Root Module coordinates everything.

Child Modules perform the work.

---

# Pattern 2 – Single Responsibility Modules

Every module should perform ONE job.

Example

```
VPC Module

↓

Only VPC Resources
```

NOT

```
VPC

+

EC2

+

IAM

+

TGW
```

Good modules are small.

Good modules are reusable.

HashiCorp recommends creating modules that have a narrow scope instead of trying to solve every use case in one module. :contentReference[oaicite:1]{index=1}

---

# Pattern 3 – Variables In

Every module receives inputs.

Example

```hcl
variable "vpc_id" {}
```

Think of variables as function parameters.

```
Caller

↓

Input Variables

↓

Module
```

Never hardcode values that change between environments.

---

# Pattern 4 – Outputs Out

Every module returns useful information.

Example

```hcl
output "vpc_id" {

    value = aws_vpc.main.id

}
```

Outputs become inputs for another module.

```
Module

↓

Outputs

↓

Root Module

↓

Another Module
```

Outputs are the official way for child modules to expose resource attributes to parent modules. :contentReference[oaicite:2]{index=2}

---

# Pattern 5 – Map Outputs

One of the best decisions in this project.

Instead of returning

```hcl
[
subnet-111,
subnet-222
]
```

We returned

```hcl
{

private_subnet-a = subnet-111

private_subnet-b = subnet-222

}
```

Why?

Relationships are preserved.

Maps are much easier to use later.

---

# Pattern 6 – Transform Resources into Maps

Inside the VPC module

```hcl
output "private_route_table_ids" {

  value = {

    for k, v in aws_route_table.private :

    k => v.id

  }

}
```

This converts

```
Terraform Resources

↓

Reusable Map

↓

Outputs
```

This pattern appears throughout Terraform projects.

---

# Pattern 7 – Root Module Performs Lookups

Instead of passing

```
Subnet ID
```

we passed

```
subnet_key
```

Example

```hcl
network = {

    subnet_key = "private_subnet-a"

}
```

Root Module

```hcl
module.vpc.private_subnets_ids[each.value.subnet_key]
```

This converts

```
Logical Name

↓

AWS Resource ID
```

The EC2 module never needs to know HOW the lookup works.

---

# Pattern 8 – Keep Modules Generic

Wrong

```
DEV VPC Module
```

Correct

```
Reusable VPC Module
```

The same module works for

- DEV

- PROD

- QA

- TEST

Only variables change.

---

# Pattern 9 – Remote State Between Root Modules

DEV

↓

Creates TGW

↓

Outputs TGW ID

↓

Remote State

↓

PROD Reads Output

Instead of

```
Hardcoded TGW ID
```

we used

```
terraform_remote_state
```

This keeps Root Modules independent while still allowing controlled sharing of data. :contentReference[oaicite:3]{index=3}

---

# Pattern 10 – Use for_each Instead of Copy/Paste

Instead of

```
Route A

Route B

Route C

Route D
```

We wrote

```hcl
for_each = var.private_route_table_ids
```

Terraform generated

```
Route A

Route B

Route C

Route D
```

automatically.

`for_each` is designed for creating multiple similar resources from maps or sets. :contentReference[oaicite:4]{index=4}

---

# Pattern 11 – Stable Keys

Terraform stores

```
aws_route.this["private_subnet-a"]
```

Notice

Terraform uses

```
private_subnet-a
```

NOT

```
rtb-123
```

Stable keys make infrastructure easier to manage.

---

# Pattern 12 – Explicit Outputs

Every important resource should expose useful outputs.

Example

```
VPC ID

Subnet IDs

Route Table IDs

Transit Gateway ID

Transit Gateway ARN
```

HashiCorp recommends exposing useful outputs so modules can be composed together. :contentReference[oaicite:5]{index=5}

---

# Pattern 13 – Module Composition

Instead of creating one huge module

we composed multiple modules.

```
Root Module

↓

Calls

↓

VPC

↓

TGW

↓

RAM

↓

EC2

↓

Routes
```

Every module solves one problem.

Together they solve the complete infrastructure.

---

# Pattern 14 – Implicit Dependencies

Example

```hcl
module "tgw_attachment" {

    vpc_id = module.vpc.vpc_id

}
```

Terraform automatically understands

```
VPC

↓

Must Exist

↓

TGW Attachment
```

No manual ordering required.

Terraform builds a dependency graph automatically from references between resources and modules. :contentReference[oaicite:6]{index=6}

---

# Pattern 15 – Environment Separation

Instead of

```
DEV

+

PROD

↓

Same State File
```

We used

```
DEV

↓

Own State

PROD

↓

Own State
```

Each environment is isolated.

Communication happens only through Remote State.

---

# Pattern 16 – DRY (Don't Repeat Yourself)

Whenever I noticed duplicated code,

I asked:

```
Can this become a module?
```

If yes,

I moved it into

```
modules/
```

This kept the Root Modules clean.

DRY is one of the core principles HashiCorp recommends when designing modules. :contentReference[oaicite:7]{index=7}

---

# Complete Design Flow

```
Variables

↓

Root Module

↓

Child Modules

↓

Resources

↓

Outputs

↓

Remote State

↓

Another Root Module
```

This is the complete Terraform architecture used in this project.

---

# Best Practices Learned

✅ One responsibility per module

✅ Variables for configuration

✅ Outputs for communication

✅ Maps instead of hardcoded IDs

✅ Root Module performs orchestration

✅ Child Modules stay generic

✅ Use Remote State instead of hardcoded values

✅ Prefer for_each for uniquely identified resources

✅ Separate environments with separate state files

✅ Build reusable modules

---

# Anti-Patterns to Avoid

❌ Hardcoding AWS IDs

❌ One giant main.tf

❌ Copy/Paste resources

❌ Environment-specific modules

❌ Modules communicating directly

❌ Sharing one state file across environments

❌ Returning incomplete outputs

---

# My Biggest Lessons

While building this project I realized:

Initially I focused on:

```
Terraform Syntax
```

Later I focused on:

```
Terraform Design
```

That changed everything.

Once I understood the design patterns,

writing Terraform became much easier.

---

# Key Takeaway

Good Terraform isn't measured by:

```
Number of Resources
```

Good Terraform is measured by:

```
Reusable Modules

↓

Clear Inputs

↓

Useful Outputs

↓

Simple Data Flow

↓

Easy Maintenance
```

If a new engineer can understand your repository without asking you questions,

you have designed it well.
