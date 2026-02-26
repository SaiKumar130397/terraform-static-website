output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}

output "bucket_name" {
  value = aws_s3_bucket.website.id
}