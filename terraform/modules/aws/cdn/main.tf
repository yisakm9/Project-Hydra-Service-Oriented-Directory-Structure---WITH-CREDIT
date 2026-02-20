locals {
  origin_id = "HydraALBOrigin"
}

resource "aws_cloudfront_distribution" "c2_cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Hydra C2 Ops"
  price_class         = "PriceClass_100" # Use only US/EU/Canada (Cheapest)

  # --- 1. The Origin (Where traffic goes) ---
  origin {
    domain_name = var.origin_domain_name
    origin_id   = local.origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # Talk to ALB over HTTP (No Domain/Cert on ALB)
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # --- 2. Default Cache Behavior ---
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id

    # Do not cache C2 traffic (Forward everything)
    forwarded_values {
      query_string = true
      headers      = ["*"] # Forward all headers (Cookies, User-Agent, etc.)

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https" # Force HTTPS for victims
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  # --- 3. Restrictions (Geo-Blocking) ---
  # Optional: Block traffic from countries you are NOT targeting to reduce noise
  restrictions {
    geo_restriction {
      restriction_type = "none"
      # Example to whitelist only US:
      # restriction_type = "whitelist"
      # locations        = ["US"]
    }
  }

  # --- 4. SSL Certificate ---
  # Uses the default CloudFront cert (*.cloudfront.net)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "Hydra-CDN"
  }
}