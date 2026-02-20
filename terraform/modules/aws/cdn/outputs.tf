output "cloudfront_domain_name" {
  description = "The C2 Callback URL (The 'Face' of the operation)"
  value       = aws_cloudfront_distribution.c2_cdn.domain_name
}

output "distribution_id" {
  value = aws_cloudfront_distribution.c2_cdn.id
}