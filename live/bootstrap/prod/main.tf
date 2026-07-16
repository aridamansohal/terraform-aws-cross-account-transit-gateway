
locals {
  managed_policies = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}

data "aws_iam_policy_document" "assume_role" {

  statement {

    effect = "Allow"

    principals {

      type = "AWS"

      identifiers = [
        var.terraform_user_arn
      ]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "terraform_execution" {

  name = "TerraformExecutionRole"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "admin" {

  for_each = toset(local.managed_policies)
  role     = aws_iam_role.terraform_execution.name

  policy_arn = each.value
}