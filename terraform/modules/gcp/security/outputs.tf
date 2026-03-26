output "c2_node_tag" {
  description = "Network tag to apply to C2 instances"
  value       = "c2-node"
}

output "lb_target_tag" {
  description = "Network tag for LB-facing resources"
  value       = "lb-target"
}
