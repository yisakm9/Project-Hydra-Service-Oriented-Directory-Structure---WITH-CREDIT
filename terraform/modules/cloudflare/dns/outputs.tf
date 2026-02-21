output "tunnel_id" {
  value = cloudflare_tunnel.local_bridge.id
}

output "tunnel_cname" {
  value = cloudflare_tunnel.local_bridge.cname
}

output "tunnel_token" {
  description = "The token required to start the tunnel on your local PC"
  value       = cloudflare_tunnel.local_bridge.tunnel_token
  sensitive   = true
}