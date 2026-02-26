resource "aws_s3_bucket" "website" {
    bucket = var.bucket_name
}

/*
To block public access in any form.
Block and limit public access control limits.
Prevent adding any public bucket policies.
*/

resource "aws_s3_bucket_public_access_block" "block" {
    bucket = aws_s3_bucket.website.id

    block_public_acls = true
    ignore_public_acls = true
    block_public_policy = true
    restrict_public_buckets = true
}

resource "aws_s3_object" "index" {
    bucket = aws_s3_bucket.website.id
    key = "index.html"
    source = "website/index.html"
    content_type = "text/html"
}

/*
We have blocked the public access to S3 bucket. 
Instead we use CloudFront as a CDN and secure entry point by giving oac to access the bucket.
User sends request to CloudFront, it checks cache, if cached, returned immediately.
*/

resource "aws_cloudfront_origin_access_control" "oac" {
    name = "website-oac"
    origin_access_control_origin_type = "s3"
    signing_behavior = "always"         # always sign requests to S3
    signing_protocol = "sigv4"          # Uses AWS Signature Version 4
}

# To create Content Delivery Network (CDN) 

resource "aws_cloudfront_distribution" "cdn" {
    enabled = true
    default_root_object = "index.html"     # If user visits https://domain.com/ CloudFront loads index.html
    
    origin {
        domain_name = aws_s3_bucket.website.bucket_regional_domain_name
        origin_id = "s3-origin"            # Internal identifier used in cache behavior
        origin_access_control_id = aws_cloudfront_origin_access_control.oac.id      # Attaches OAC to origin.
    }

    default_cache_behavior {
        allowed_methods = ["GET", "HEAD"] 
        cached_methods = ["GET", "HEAD"]   # allow only read operations
        target_origin_id = "s3-origin"
        viewer_protocol_policy = "redirect-to-https"

        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }
    }

    viewer_certificate {
        cloudfront_default_certificate = true   # Uses default AWS CloudFront SSL
    }

    restrictions {
        geo_restriction {
            restriction_type = "none"           # No country restrictions
        }
    }
}

resource "aws_s3_bucket_policy" "policy" {
    bucket = aws_s3_bucket.website.id
    policy = jsonencode({                        # IAM policy to allow only CloudFront service
        Version = "2012-10-17"
        Statement = [
        {
            Effect = "Allow"
            Principal = {
                Service = "cloudfront.amazonaws.com"
            }
            Action = "s3:GetObject"
            Resource = "${aws_s3_bucket.website.arn}/*"
            Condition = {                                   # To allow only this CloudFront (not any CloudFront)
                StringEquals = {
                    "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
                }
            }
        }
        ]
    })
}
