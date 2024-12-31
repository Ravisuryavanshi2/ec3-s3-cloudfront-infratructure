
resource "aws_instance" "my_instance" {
  ami           = "ami-0206f4f885421736f"  # Your specified AMI ID
  instance_type = "t2.micro"  # Adjust based on your needs
  
  key_name = "hello-server"  # Updated SSH key name for EC2 access

  tags = {
    Name = "hello-machine"  # EC2 instance name as per your specification
  }
}

provider "aws" {
  region = "ap-northeast-3"  # Set to your specified region
}

# S3 Bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "hello-bucket-hosting1"  # S3 bucket name
}

# Upload the index.html to the S3 bucket
resource "aws_s3_object" "website_index" {
  bucket       = aws_s3_bucket.my_bucket.bucket
  key          = "index.html"
  source       = "index.html"  # Path to your local index.html file
  content_type = "text/html"
}

# CloudFront Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "my_oac" {
  name                              = "hello-oac"
  description                       = "OAC for CloudFront to access S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "my_distribution" {
  origin {
    domain_name             = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_id               = "S3-hello-bucket-hosting1"
    origin_access_control_id = aws_cloudfront_origin_access_control.my_oac.id
  }

  # Default cache behavior configuration
  default_cache_behavior {
    target_origin_id       = "S3-hello-bucket-hosting1"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "My CloudFront Distribution"
  price_class         = "PriceClass_100"
  default_root_object = "index.html"

  # Viewer certificate
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# Automatically Attach Bucket Policy
resource "aws_s3_bucket_policy" "my_bucket_policy" {
  bucket = aws_s3_bucket.my_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccessWithOAC"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.my_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.my_distribution.arn
          }
        }
      }
    ]
  })
}
