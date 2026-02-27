output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}

output "image_url" {
  value =
    "https://${aws_cloudfront_distribution.cdn.domain_name}devops.svg"
}

output "bucket_name" {
  value = aws_s3_bucket.website.id
}

output "bucket_name" {
    value = aws_s3_bucket.assets.id
}