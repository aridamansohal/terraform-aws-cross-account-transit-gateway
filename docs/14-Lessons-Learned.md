# Chapter 14 – Lessons Learned

## Purpose

This repository started as a simple goal:

> Build a Cross-Account AWS Transit Gateway using Terraform.

By the end of the project, I realized I had learned something much more valuable than just deploying AWS resources.

I learned how Terraform **thinks**.

This chapter summarizes the biggest lessons from the project.

---

# Lesson 1 – Don't Memorize Terraform

When I started, I tried to memorize things like:

```hcl
route_table_id = each.value
```

I could write the code.

But I didn't understand WHY it worked.

Later I realized the better question is:

> What data is Terraform looping over?

Once I understood the map structure, `each.value` became obvious.

---

# Lesson 2 – Everything Starts With Data

Terraform is really about moving data.

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

Another Module
```

Every chapter in this project follows this pattern.

---

# Lesson 3 – Root Modules Are Project Managers

Originally I thought every module should know everything.

Wrong.

The Root Module is responsible for connecting modules together.

Child Modules should only know:

- Their inputs
- Their own resources
- Their outputs

Nothing else.

This makes modules reusable.

---

# Lesson 4 – Outputs Are Contracts

At first I thought outputs were optional.

Later I realized:

Outputs define what another module is allowed to know.

Example

```
VPC Module

↓

Outputs

↓

VPC ID

↓

Root Module

↓

TGW Attachment Module
```

Outputs became the contract between modules.

---

# Lesson 5 – Maps Are Better Than Lists

Originally I wanted outputs like this:

```hcl
[
  "subnet-111",
  "subnet-222"
]
```

Then I realized:

```
Which subnet is which?
```

Impossible to know.

Maps solved this.

```hcl
{
  private_subnet-a = "subnet-111"
  private_subnet-b = "subnet-222"
}
```

Relationships are preserved.

---

# Lesson 6 – for_each Is About Identity

Initially I thought

```
for_each

↓

Loop
```

That's only partially true.

A better understanding is

```
Map

↓

Unique Keys

↓

Terraform Resources
```

Terraform creates one resource for each key.

The key becomes the identity of that resource.

---

# Lesson 7 – each.key vs each.value

This was my biggest breakthrough.

I originally believed

```
each.key

↓

AWS Resource ID
```

Wrong.

The reality is

```
each.key

↓

Logical Name

private_subnet-a

each.value

↓

AWS ID

rtb-xxxxxxxx
```

Once I understood this,

Terraform became much easier.

---

# Lesson 8 – IDs Should Never Be Hardcoded

Whenever I found myself writing

```
subnet-123

rtb-456

tgw-789
```

I stopped.

Instead I asked:

"Can Terraform discover this value?"

Usually the answer was

Yes.

Either through:

- Outputs
- Maps
- Remote State
- Data Sources

---

# Lesson 9 – Remote State Is Communication

Initially I thought Remote State existed only to read state files.

Now I think about it differently.

```
DEV

↓

Exports Knowledge

↓

Remote State

↓

PROD

↓

Consumes Knowledge
```

Remote State became the communication channel between independent Terraform environments.

---

# Lesson 10 – AWS RAM Doesn't Share Ownership

This confused me for a long time.

Sharing

does NOT mean

Ownership.

```
DEV

↓

Creates TGW

↓

Owns TGW

↓

Shares TGW

↓

PROD Uses It
```

Ownership never changes.

---

# Lesson 11 – Attachments Don't Mean Connectivity

Initially I thought

```
TGW Attachment

↓

Done
```

Wrong.

Networking still requires:

- VPC Route Tables
- TGW Route Tables
- Security Groups
- Network ACLs

Every layer matters.

---

# Lesson 12 – There Are Two Routing Layers

One of the biggest discoveries.

```
VPC Route Table

↓

Leave the VPC
```

```
Transit Gateway Route Table

↓

Forward Between Attachments
```

Understanding this solved most of my networking confusion.

---

# Lesson 13 – Build Reusable Modules

Instead of writing

```
DEV VPC

PROD VPC

QA VPC
```

I learned to write

```
Reusable VPC Module
```

Only the variables change.

The code stays the same.

Reusable modules are easier to maintain and follow Terraform best practices. :contentReference[oaicite:1]{index=1}

---

# Lesson 14 – Read the Plan Carefully

One habit I developed during this project:

Always read

```
terraform plan
```

before

```
terraform apply
```

The plan often explains exactly what Terraform intends to do.

---

# Lesson 15 – Troubleshoot One Layer at a Time

When networking failed,

I stopped guessing.

Instead I checked:

```
Terraform

↓

State

↓

Transit Gateway

↓

Attachment

↓

VPC Route Tables

↓

TGW Route Tables

↓

Security Groups

↓

EC2
```

This structured approach made debugging much easier.

---

# My Biggest Mindset Shift

At the beginning of the project, I focused on writing Terraform.

By the end of the project, I focused on designing Terraform.

That small change made a huge difference.

Instead of asking

> "How do I create this resource?"

I started asking

> "How should this module communicate with the rest of the project?"

---

# What This Project Taught Me

This project taught me much more than:

- Transit Gateway
- AWS RAM
- Remote State
- Routing

It taught me how to design Infrastructure as Code.

It taught me to think in terms of:

- Reusability
- Modularity
- Data Flow
- Dependencies
- Maintainability

Those principles are valuable in every Terraform project, regardless of the cloud provider.

---

# Final Architecture

```
Terraform Variables

↓

Root Module

↓

Child Modules

↓

AWS Resources

↓

Outputs

↓

Remote State

↓

Another Root Module

↓

Dependent Infrastructure
```

This diagram summarizes the entire project.

---

# Final Thoughts

When I started this project, I wanted to learn how to deploy a Cross-Account Transit Gateway.

By the end, I realized the Transit Gateway was only the vehicle.

The real lesson was learning how Terraform models infrastructure, how modules communicate, and how to design infrastructure that is easy to understand, maintain, and extend.

That is the knowledge I want to carry into future projects.

---

# What's Next?

This project is complete.

Possible future enhancements include:

- Multi-Region Transit Gateway
- Multiple TGW Route Tables
- Network Segmentation
- AWS Network Firewall
- Direct Connect Gateway
- Site-to-Site VPN
- Terraform CI/CD with GitHub Actions
- Automated Testing
- Policy as Code
- Multi-Account Landing Zone

Every new project will build on the same Terraform principles learned here.
