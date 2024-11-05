resource "aws_iam_role" "bucket_access_role" {
  name = "s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    tag-key = "bucket-access-role"
  }
}

resource "aws_iam_role_policy" "s3_role_policy" {
  name = "s3-role-policy"
  role = aws_iam_role.bucket_access_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "s3:ListBucket",
        "s3:GetObject",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Effect = "Allow",
      Resource = [
        "arn:aws:s3:::izanna-web-bucket",
        "arn:aws:s3:::izanna-web-bucket/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance_profile"
  role = aws_iam_role.bucket_access_role.name
}

