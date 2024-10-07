resource "aws_s3_bucket" "web_bucket" {
  bucket_prefix = "izanna-web-bucket"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.web_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_crypto_conf" {
  bucket = aws_s3_bucket.web_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "izanna_upload_object" {
  bucket                 = aws_s3_bucket.web_bucket.id
  key                    = "sample_index.html"
  source                 = "./sample_index.html"
  server_side_encryption = "AES256"

  tags = {
    Name = "Upload to bucket"
  }
}

