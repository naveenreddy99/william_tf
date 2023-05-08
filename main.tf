data "aws_ami" "amzn_lnx" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["amazon"]
}

data "template_file" "userdata" {
  template = file("userdata.sh")
}

resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.amzn_lnx.id
  instance_type               = var.ec2_settings["instance_type"]
  associate_public_ip_address = var.ec2_settings["associate_public_ip_address"]
  key_name                    = var.ec2_settings["key_name"]
  subnet_id                   = var.ec2_settings["subnet_id"]
  vpc_security_group_ids      = var.ec2_settings["vpc_security_groups"]
  user_data                   = data.template_file.userdata.rendered
  availability_zone           = var.ec2_settings["availability_zone"]
  root_block_device {
    delete_on_termination = true
    volume_size           = var.ec2_settings["root_block_volume_size"]
  }

  dynamic "ebs_block_device" {
    for_each = var.ec2_settings["ebs_block_device"]
    content {
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = lookup(ebs_block_device.value, "encrypted", null)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      kms_key_id            = lookup(ebs_block_device.value, "kms_key_id", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
      throughput            = lookup(ebs_block_device.value, "throughput", null)
    }
  }
  tags = var.ec2_settings["tags"]
}

# data "aws_iam_policy_document" "assume_role" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["s3.amazonaws.com"]
#     }

#     actions = ["sts:AssumeRole"]
#   }
# }

## ROLE & POLICY FOR S3 REPLICATION

resource "aws_iam_role" "replication" {
  name               = "tf-iam-role-replication-12345"
  assume_role_policy = data.aws_iam_policy_document.replication.json
}

data "aws_iam_policy_document" "replication" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = [aws_s3_bucket.source_bucket.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = ["${aws_s3_bucket.source_bucket.arn}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]

    resources = ["${aws_s3_bucket.replica_bucket.arn}/*"]
  }
}


### SQS #####
resource "aws_sqs_queue" "queue" {
  name                      = var.sqs_name
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  tags = var.sqs_tags
}

/* Lambda Execution Role Creation */
resource "aws_iam_role" "LambdaExecutionRole" {
  name = var.lambda_execution_role_name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

/* LAMBDA FUNCTION */
data "archive_file" "lambda_zip_file" {
  type            = "zip"
  source_file     = "./lambda_function.py"
  output_path     = "./lambda_function.py.zip"
}

resource "aws_lambda_function" "lambda" {
  #filename = "lambda_function.py.zip"
  filename          = "lambda_function.py.zip"
  source_code_hash  = filebase64sha256(data.archive_file.lambda_zip_file.output_path)
  function_name     = var.function_name
  role              = aws_iam_role.LambdaExecutionRole.arn
  handler           = "lambda_function.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  #source_code_hash = filebase64sha256("lambda_function_payload.zip")

  runtime = "python3.9"
  memory_size = 128
  timeout = 120
}
