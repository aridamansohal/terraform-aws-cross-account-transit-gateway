resource "aws_instance" "main" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  iam_instance_profile   = var.iam_instance_profile_name
  vpc_security_group_ids = [var.security_group_id]
  subnet_id              = var.subnet_id

  tags = {
    Name = "${var.instance_name}-instance"

  }
}






