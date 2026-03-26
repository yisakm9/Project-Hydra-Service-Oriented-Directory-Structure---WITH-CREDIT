output "service_account_email" {
  description = "Email of the C2 service account"
  value       = google_service_account.c2_sa.email
}
