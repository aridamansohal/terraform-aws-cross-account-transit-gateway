# Chapter 05 – Maps, Lookups and Outputs

## Purpose

This chapter explains the Terraform concepts that confused me the most while building this project:

- Why do modules return maps?
- Why did I write `k => v.id`?
- Why do I use `module.vpc.private_subnets_ids[var.subnet_key]`?
- When should I use `lookup()`?
- Why was Design B better than Design A?

Once I understood these concepts, everything about `for_each` and module communication became much easier.

---

# The Big Picture

Terraform modules communicate using:

```
Variables

↓

Resources

↓

Outputs

↓

Another Module
```

Think of a module as a function.

```
Inputs

↓

Module

↓

Outputs
```

Exactly like programming.

---

# What is a Map?

A map stores data as:

```
Key

↓

Value
```

Example:

```hcl
{
    public_subnet-a  = "subnet-111"

    public_subnet-b  = "subnet-222"

    private_subnet-a = "subnet-333"

    private_subnet-b = "subnet-444"
}
```

Notice something important.

The subnet ID has a **name** attached to it.

That name is the key.

Terraform uses maps extensively because they preserve the relationship between a logical name and its value. :contentReference[oaicite:0]{index=0}

---

# Why Didn't We Return a List?

Suppose our VPC module returned:

```hcl
[
  "subnet-111",

  "subnet-222"
]
```

Question:

Which subnet belongs to AZ-a?

Which subnet belongs to AZ-b?

You don't know.

The relationship is lost.

Now look at a map.

```hcl
{

private_subnet-a = subnet-111

private_subnet-b = subnet-222

}
```

Now the relationship is preserved.

That is why outputs in this project return maps instead of lists.

---

# Our Actual Output

Inside the VPC module we wrote:

```hcl
output "private_subnets_ids" {

  value = {

    for k, v in aws_subnet.private :

    k => v.id

  }

}
```

This returns:

```hcl
{

private_subnet-a = subnet-111

private_subnet-b = subnet-222

}
```

---

# Understanding

```hcl
for k, v in aws_subnet.private :

k => v.id
```

This confused me for a long time.

Let's break it down.

Terraform loops over every subnet resource.

Iteration 1

```
k

↓

private_subnet-a

v

↓

Subnet Object
```

Terraform returns

```
private_subnet-a

↓

subnet-111
```

Iteration 2

```
private_subnet-b

↓

subnet-222
```

Finally

```hcl
{

private_subnet-a = subnet-111

private_subnet-b = subnet-222

}
```

This is a **for expression**, which is Terraform's way of transforming one collection into another. :contentReference[oaicite:1]{index=1}

---

# Why We Did This

Our EC2 module needs

```
Subnet ID
```

NOT

```
private_subnet-a
```

But we still want humans to configure using names.

So we keep both.

```
Key

↓

Human Friendly

private_subnet-a

↓

Value

↓

AWS ID

subnet-111
```

---

# Design A (The One We Didn't Use)

```hcl
module "ec2" {

    subnet_id = module.vpc.private_subnets_ids["private_subnet-a"]

}
```

Problem

Every EC2 module call must know

```
private_subnet-a
```

Hardcoded.

If tomorrow we rename the subnet

Everything breaks.

---

# Design B (Our Final Design)

We stored

```hcl
subnet_key = "private_subnet-a"
```

inside the EC2 object.

Example

```hcl
ec2_instances = {

network = {

subnet_key = "private_subnet-a"

}

}
```

Now Root Module does

```hcl
subnet_id = module.vpc.private_subnets_ids[each.value.subnet_key]
```

This is much cleaner.

---

# Let's Read It Slowly

Terraform first evaluates

```hcl
each.value.subnet_key
```

Suppose

```hcl
subnet_key = "private_subnet-a"
```

Now expression becomes

```hcl
module.vpc.private_subnets_ids["private_subnet-a"]
```

Terraform looks inside

```hcl
{

private_subnet-a = subnet-111

private_subnet-b = subnet-222

}
```

Returns

```
subnet-111
```

Finally AWS receives

```hcl
subnet_id = subnet-111
```

That is exactly what AWS expects.

---

# Why Not Pass the Subnet ID Directly?

Because subnet IDs change.

Names usually don't.

```
Good

private_subnet-a

↓

Lookup

↓

subnet-111
```

Instead of

```
Hardcode

↓

subnet-111
```

Design B keeps the configuration independent of AWS-generated IDs.

---

# What is lookup()?

Terraform also provides

```hcl
lookup(map, key, default)
```

Example

```hcl
lookup(var.ami_map, "us-west-2", null)
```

If

```hcl
var.ami_map = {

us-east-1 = ami-111

us-west-2 = ami-222

}
```

Terraform returns

```
ami-222
```

If the key does not exist

Terraform returns the default value instead of failing. :contentReference[oaicite:2]{index=2}

---

# Direct Index vs lookup()

Direct indexing:

```hcl
var.ami_map["us-west-2"]
```

If key exists

Works.

If key doesn't exist

Terraform throws an error.

lookup()

```hcl
lookup(var.ami_map,"us-west-2","default")
```

If key doesn't exist

Returns

```
default
```

Use direct indexing when the key **must** exist.

Use `lookup()` when the key is optional or you want a fallback value. :contentReference[oaicite:3]{index=3}

---

# Why Didn't We Use lookup()?

Our subnet key

```
private_subnet-a
```

must always exist.

If it doesn't

I WANT Terraform to fail.

That means my configuration is wrong.

Therefore

```hcl
module.vpc.private_subnets_ids[var.subnet_key]
```

is better than

```hcl
lookup(...)
```

---

# Data Flow

```
VPC Module

↓

Creates

↓

Subnets

↓

Outputs Map

↓

Root Module

↓

Uses subnet_key

↓

Looks up subnet ID

↓

Passes ID

↓

EC2 Module

↓

AWS
```

This is the complete journey of the subnet ID.

---

# Mental Model

Think of a map as a dictionary.

```
Word

↓

Meaning
```

Example

```
private_subnet-a

↓

subnet-111
```

Terraform simply asks

"Give me the value for this key."

---

# Lessons Learned

- Maps preserve relationships.
- Outputs should expose useful data structures.
- Human-friendly names are better than hardcoded AWS IDs.
- `k => v.id` transforms resources into a reusable map.
- Design B is more reusable than hardcoding subnet IDs.
- Use direct indexing when the key must exist.
- Use `lookup()` only when a default value makes sense.
- The root module should translate logical names into AWS resource IDs before passing them to child modules.

---

# Key Takeaway

The biggest lesson from this chapter is:

Don't think about IDs.

Think about **relationships**.

```
Logical Name

↓

Lookup

↓

AWS ID

↓

Resource
```

Once you understand that Terraform is constantly translating **logical names** into **real infrastructure IDs**, outputs, maps, lookups, and module inputs all fit together naturally.
