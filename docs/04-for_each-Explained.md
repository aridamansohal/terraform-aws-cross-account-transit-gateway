# Chapter 04 – Understanding `for_each`

## Purpose

During this project, the biggest Terraform concept I struggled with was `for_each`.

At first, I thought it was simply a loop.

Later I realized it is much more than that.

`for_each` creates **multiple Terraform resources from a single resource block**, where each resource is identified by a unique key from a **map** or a **set**. :contentReference[oaicite:0]{index=0}

This chapter explains `for_each` using the exact examples from this project.

---

# Why do we need `for_each`?

Imagine you have two private route tables.

Without `for_each`:

```hcl
resource "aws_route" "private_a" {

  route_table_id = "rtb-111"

}

resource "aws_route" "private_b" {

  route_table_id = "rtb-222"

}
```

This works.

But what if tomorrow you have:

- 4 route tables
- 8 route tables
- 20 route tables

You would keep copying the same code.

Terraform solves this problem with `for_each`. :contentReference[oaicite:1]{index=1}

---

# Our Example

Inside the VPC module we created this output.

```hcl
output "private_route_table_ids" {

  value = {

    for k, v in aws_route_table.private :

    k => v.id

  }

}
```

Terraform returns:

```hcl
{
    private_subnet-a = "rtb-111"

    private_subnet-b = "rtb-222"
}
```

Notice something important.

This is **not a list**.

This is a **map**.

```
Key

↓

private_subnet-a

↓

Value

↓

rtb-111
```

---

# Why Return a Map?

Many beginners ask:

> Why not return a list?

Example list:

```hcl
[
    "rtb-111",

    "rtb-222"
]
```

Problem:

Which route table belongs to which subnet?

You don't know.

Now look at the map.

```hcl
{

private_subnet-a = "rtb-111"

private_subnet-b = "rtb-222"

}
```

Now Terraform knows exactly which Route Table belongs to which subnet.

This is why we used a map instead of a list.

---

# Passing the Output

The Root Module receives the output.

```hcl
module.vpc.private_route_table_ids
```

This value becomes the input for another module.

```hcl
module "transit-gateway-routes" {

  private_route_table_ids = module.vpc.private_route_table_ids

}
```

Nothing magical happened.

Terraform simply passed the map from one module to another.

---

# What does `for_each` do?

Inside our module:

```hcl
resource "aws_route" "this" {

    for_each = var.private_route_table_ids

}
```

Terraform sees:

```hcl
{

private_subnet-a = "rtb-111"

private_subnet-b = "rtb-222"

}
```

Then Terraform says:

"I need one Route resource for every element in this map."

:contentReference[oaicite:2]{index=2}

---

# Iteration 1

Terraform picks:

```
private_subnet-a

↓

rtb-111
```

Creates

```
aws_route.this["private_subnet-a"]
```

---

# Iteration 2

Terraform picks

```
private_subnet-b

↓

rtb-222
```

Creates

```
aws_route.this["private_subnet-b"]
```

Now you have TWO resources.

Although your code contains only ONE resource block.

---

# Understanding each.key

Terraform exposes

```
each.key
```

For iteration 1

```
private_subnet-a
```

Iteration 2

```
private_subnet-b
```

Think of it as the **label**.

---

# Understanding each.value

Terraform also exposes

```
each.value
```

Iteration 1

```
rtb-111
```

Iteration 2

```
rtb-222
```

Think of it as the **actual AWS value**.

---

# Why did we use each.value?

Our code:

```hcl
resource "aws_route" "this" {

  for_each = var.private_route_table_ids

  route_table_id = each.value

}
```

AWS expects

```
Route Table ID
```

AWS does NOT expect

```
private_subnet-a
```

Therefore

```hcl
route_table_id = each.value
```

This was one of the biggest "aha!" moments of the project.

---

# Visual Mental Model

```
Terraform receives

{

private_subnet-a = rtb-111

private_subnet-b = rtb-222

}

↓

Loop Starts

↓

Iteration 1

Key

private_subnet-a

Value

rtb-111

↓

Create Route

↓

Iteration 2

Key

private_subnet-b

Value

rtb-222

↓

Create Route
```

---

# Common Mistake

I originally thought:

```
each.key

↓

Route Table ID
```

Wrong.

The key is only the logical name.

```
private_subnet-a
```

The Route Table ID is

```
each.value
```

---

# How Terraform Stores Resources

Terraform State

```
aws_route.this["private_subnet-a"]

aws_route.this["private_subnet-b"]
```

Notice

Terraform stores them using the key.

Not the value.

This is one reason maps are preferred for `for_each`, because the key becomes the stable identity of each resource. :contentReference[oaicite:3]{index=3}

---

# When should I use `for_each`?

Use `for_each` when:

✅ Every resource has a unique name

✅ You already have a map

✅ You want stable resource addresses

Examples

- Route Tables
- Subnets
- Security Groups
- IAM Users
- VPC Endpoints
- EC2 instances keyed by name

---

# When should I NOT use `for_each`?

Avoid it when resources don't have meaningful keys.

Example:

```
Need exactly 3 EC2

Server1

Server2

Server3
```

Sometimes `count` is simpler.

But if each instance has a unique identity (like your subnets), `for_each` is generally the better choice because adding or removing one key does not renumber the others. :contentReference[oaicite:4]{index=4}

---

# My Learning Journey

Initially I memorized:

```hcl
route_table_id = each.value
```

Later I understood WHY.

The map looked like:

```hcl
{

private_subnet-a = rtb-111

private_subnet-b = rtb-222

}
```

Terraform iterated over every element.

AWS required

```
rtb-111
```

Therefore

```
each.value
```

Everything suddenly made sense.

---

# Key Takeaways

- `for_each` works with maps and sets. :contentReference[oaicite:5]{index=5}
- A map has a **key** and a **value**.
- `each.key` is the logical identifier.
- `each.value` is the actual value.
- AWS APIs usually require the value (ID), not the logical key.
- Maps preserve relationships between names and IDs.
- `for_each` creates one Terraform resource for every element in the map.

---

# Remember This

Don't memorize:

```hcl
each.value
```

Instead ask yourself:

> **What data am I looping over?**

If you're looping over:

```hcl
{

private_subnet-a = rtb-111

private_subnet-b = rtb-222

}
```

Then the answer becomes obvious.

```
each.key

↓

private_subnet-a

each.value

↓

rtb-111
```

Once you understand the data structure, `for_each` becomes easy.
