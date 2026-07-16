# Terraform Thinking

## Purpose

When I first started this project, I kept asking questions like:

- Why do we need outputs?
- Why are we using `each.value`?
- Why can't one module directly use another module's resources?
- Why do we use Remote State?
- Why does Terraform know which resource to create first?

I eventually realized that I wasn't struggling with Terraform syntax—I was struggling with **how Terraform thinks**.

This document explains Terraform's execution model using examples from this project.

---

# How Terraform Thinks

Terraform does **not** execute files from top to bottom.

Instead, Terraform reads **every `.tf` file in the current directory**, combines them into a single configuration (the **root module**), builds a dependency graph, and determines the correct order to create resources. :contentReference[oaicite:0]{index=0}

Think of Terraform like this:

```
Read All Files

↓

Understand Relationships

↓

Build Dependency Graph

↓

Create Resources

↓

Save State
```

The order of files such as `main.tf`, `outputs.tf`, or `variables.tf` does not matter.

---

# Root Module

The directory where you run:

```bash
terraform init
terraform plan
terraform apply
```

is called the **Root Module**. :contentReference[oaicite:1]{index=1}

Example:

```
live/dev
```

When Terraform starts here, it treats **everything inside this directory** as one configuration.

```
backend.tf

+

providers.tf

+

locals.tf

+

main.tf

+

outputs.tf

+

variables.tf

↓

Root Module
```

---

# Child Modules

A child module is a reusable Terraform module called by the root module.

Example:

```hcl
module "vpc" {
  source = "../../modules/vpc"
}
```

Terraform loads the module, creates its resources, and returns only the values exposed through outputs. :contentReference[oaicite:2]{index=2}

```
Root Module

↓

Calls

↓

VPC Module

↓

Creates

↓

VPC

Subnets

Route Tables
```

---

# Why Modules Cannot See Each Other

This was one of my biggest questions.

Example:

```
VPC Module

Transit Gateway Module
```

Can the Transit Gateway module directly access the VPC?

**No.**

Modules are isolated.

They communicate only through **inputs** and **outputs**. :contentReference[oaicite:3]{index=3}

Correct flow:

```
VPC Module

↓

Output

↓

Root Module

↓

Input Variable

↓

TGW Module
```

---

# Variables

Variables are inputs.

Example:

```hcl
variable "vpc_id" {}
```

Think of them as parameters passed into a function.

```
Caller

↓

Input

↓

Module
```

---

# Outputs

Outputs are values returned from a module.

Example:

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}
```

Think of outputs as a function's return value. Child modules expose values to the parent through outputs, and root module outputs can also be consumed through remote state. :contentReference[oaicite:4]{index=4}

```
Module

↓

Returns

↓

VPC ID
```

---

# Our Project Flow

```
VPC Module

↓

Creates

↓

VPC

↓

Outputs

↓

vpc_id

↓

Root Module

↓

Passes

↓

TGW Attachment Module
```

That is why the attachment module never creates or searches for the VPC.

It simply receives the VPC ID as an input.

---

# Remote State

A module can only access resources within the same Terraform configuration.

Our DEV and PROD environments use different state files.

So PROD cannot directly reference:

```
module.transit-gateway.transit_gateway_id
```

Instead, it reads the output from the DEV root module using `terraform_remote_state`. Only root module outputs are available through remote state. :contentReference[oaicite:5]{index=5}

```
DEV State

↓

Outputs

↓

Remote State

↓

PROD
```

---

# Why We Created Outputs

Inside the VPC module:

```hcl
output "private_route_table_ids" {
  value = {
    for k, v in aws_route_table.private :
    k => v.id
  }
}
```

This returns:

```hcl
{
  private_subnet-a = "rtb-123"
  private_subnet-b = "rtb-456"
}
```

Why a map?

Because Terraform preserves the logical relationship between the subnet name and its route table ID.

---

# Understanding for_each

Terraform sees:

```hcl
{
  private_subnet-a = "rtb-123"
  private_subnet-b = "rtb-456"
}
```

Then:

```hcl
for_each = var.private_route_table_ids
```

becomes:

Iteration 1

```
each.key

private_subnet-a

each.value

rtb-123
```

Iteration 2

```
each.key

private_subnet-b

each.value

rtb-456
```

Terraform's `for_each` creates one resource instance for every map element, and each instance receives its own `each.key` and `each.value`. :contentReference[oaicite:6]{index=6}

---

# Why each.value?

AWS Route API requires:

```
Route Table ID
```

not

```
private_subnet-a
```

Therefore:

```hcl
route_table_id = each.value
```

This was one of the biggest "aha!" moments in this project.

---

# Dependency Graph

Terraform automatically understands dependencies.

Example:

```hcl
module "tgw_attachment" {

  vpc_id = module.vpc.vpc_id

}
```

Terraform knows:

```
VPC

↓

Must Exist

↓

TGW Attachment
```

No manual ordering is needed because the reference creates an implicit dependency. Explicit `depends_on` is generally only needed when no reference exists. :contentReference[oaicite:7]{index=7}

---

# Mental Model

Think of Terraform as a factory.

```
Raw Materials

↓

Variables

↓

Factory

↓

Modules

↓

Finished Products

↓

Outputs
```

Every module receives inputs.

Every module performs work.

Every module returns outputs.

The root module connects all the modules together.

---

# Lessons Learned

- Terraform reads the entire directory as one root module.
- Child modules cannot directly communicate.
- Variables send data **into** a module.
- Outputs return data **out of** a module.
- Remote State shares outputs between independent Terraform configurations.
- `for_each` loops over maps and creates one resource per element.
- `each.key` is the logical name.
- `each.value` is the actual value used by AWS.
- Terraform builds a dependency graph automatically from references.
- Understanding the execution model is more valuable than memorizing syntax.

---

# Key Takeaway

The biggest lesson from this project was:

> Don't memorize Terraform syntax.

Instead, understand how Terraform **moves data**:

```
Variables

↓

Modules

↓

Resources

↓

Outputs

↓

Other Modules

↓

Remote State

↓

Another Environment
```

Once you understand that flow, concepts like outputs, `for_each`, maps, and remote state become much easier to reason about.
