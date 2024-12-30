provider "aws" {
  region = "ap-northeast-3"  # Set to your specified region
}

# S3 Bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "hello-bucket-hosting1"  # S3 bucket name as per your specification
}

# Upload the index.html to the S3 bucket
resource "aws_s3_object" "website_index" {
  bucket       = aws_s3_bucket.my_bucket.bucket
  key          = "index.html"
  source       = "index.html"  # Path to your local index.html file
  content_type = "text/html"
}

# EC2 Instance
resource "aws_instance" "my_instance" {
  ami           = "ami-0206f4f885421736f"  # Your specified AMI ID
  instance_type = "t2.micro"  # Adjust based on your needs
  
  key_name = "hello-server"  # Updated SSH key name for EC2 access

  tags = {
    Name = "hello-machine"  # EC2 instance name as per your specification
  }
}


resource "aws_cloudfront_distribution" "my_distribution" {
  origin {
    domain_name = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_id   = "S3-hello-bucket-hosting1"
  }

  # Default cache behavior configuration
  default_cache_behavior {
    target_origin_id       = "S3-hello-bucket-hosting1"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    allowed_methods = ["GET", "HEAD"]  # Allowed HTTP methods
    cached_methods  = ["GET", "HEAD"]  # Cached HTTP methods

    forwarded_values {
      query_string = false   # You can set this to true if you want to forward query strings
      cookies {
        forward = "none"      # Options: "none", "all", or "whitelist"
      }
      headers = []            # If you want to forward specific headers, you can list them here
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "My CloudFront Distribution"
  price_class         = "PriceClass_100"  # You can choose different pricing tiers
  default_root_object = "index.html"
  
  # Viewer certificate
  viewer_certificate {
    cloudfront_default_certificate = true  # Using default CloudFront certificate for HTTPS
  }

  # Restrictions (Optional but required in some cases)
  restrictions {
    geo_restriction {
      restriction_type = "none"  # No geographic restrictions
    }
  }
}
