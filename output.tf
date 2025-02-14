output "bucket_name" {
  value = aws_s3_bucket.Site_Origin.bucket
}

output "cloudfront_domain-name"{
    value = aws_cloudfront_distribution.Site_Access.domain_name
}
