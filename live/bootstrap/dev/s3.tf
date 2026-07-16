resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = var.state_bucket_name

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_lock" {

  name = var.lock_table_name

  billing_mode = "PAY_PER_REQUEST"

  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

data "aws_iam_policy_document" "allow_prod_role" {

  statement {

    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        var.prod_terraform_role_arn
      ]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.terraform_state.arn,
      "${aws_s3_bucket.terraform_state.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "terraform_state" {

  bucket = aws_s3_bucket.terraform_state.id

  policy = data.aws_iam_policy_document.allow_prod_role.json
}