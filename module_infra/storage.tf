# locals {
#   files = [for f in fileset(var.object_path, "**/*") : f if !is_dir("${var.object_path}/${f}")]
# }

resource "aws_s3_bucket" "web_bucket" {
  bucket        = var.bucket_name
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
  key                    = "barista_cafe_web.zip"
  source                 = "./barista_cafe_web.zip"
  server_side_encryption = "AES256"

  tags = {
    Name = "Upload to bucket"
  }
}

