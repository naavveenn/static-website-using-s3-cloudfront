## Create bucket and apply force destroy So, when going to destroy it won't throw error 'Bucket is not empty'
resource "aws_s3_bucket" "Site_Origin" {
  bucket = var.bucket_name
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }
  tags = {
    Environment = "${var.env}"
  }
}

/*
## Enable AWS S3 file versioning
resource "aws_s3_bucket_versioning" "Site_Origin" {
  bucket = aws_s3_bucket.Site_Origin.bucket
  versioning_configuration {
    status = "Enabled"
  }
}*/

# Using null resource to push all the files in one time instead of sending one by one
resource "null_resource" "upload-to-S3" {
  provisioner "local-exec" {
    command = "aws s3 sync ${path.module}/2109_the_card s3://${aws_s3_bucket.Site_Origin.id}"
  }
}

/*
## Upload file to S3 bucket
resource "aws_s3_object" "content" {
  depends_on = [
    aws_s3_bucket.Site_Origin
  ]
  bucket                 = aws_s3_bucket.Site_Origin.bucket
  key                    = "index.html"
  source                 = "./index.html"
  server_side_encryption = "AES256"

  content_type = "text/html"
}
*/

## Assign policy to allow CloudFront to reach S3 bucket
resource "aws_s3_bucket_policy" "origin" {
  depends_on = [
    aws_cloudfront_distribution.Site_Access
  ]
  bucket = aws_s3_bucket.Site_Origin.id
  policy = data.aws_iam_policy_document.origin.json
}

## Create policy to allow CloudFront to reach S3 bucket
data "aws_iam_policy_document" "origin" {
  depends_on = [
    aws_cloudfront_distribution.Site_Access,
    aws_s3_bucket.Site_Origin
  ]
  statement {
    sid    = "3"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.Site_Origin.bucket}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"

      values = [
        aws_cloudfront_distribution.Site_Access.arn
      ]
    }
  }
}
