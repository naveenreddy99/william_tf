resource "aws_s3_bucket" "replica_bucket" {
  bucket = var.replica_bucket_name
}


resource "aws_s3_bucket_server_side_encryption_configuration" "replica_bucket_encryption" {
  bucket = aws_s3_bucket.replica_bucket.id

  rule {
        apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "replica_bucket_public_access_block" {
  bucket = aws_s3_bucket.replica_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_versioning" "replica_versioning" {
  bucket = aws_s3_bucket.replica_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}