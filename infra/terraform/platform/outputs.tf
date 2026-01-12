output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}
output "jenkins_admin_user" {
  value = "admin"
}
output "jenkins_admin_password" {
  value     = random_password.jenkins_admin.result
  sensitive = true
}
output "eks_cluster_name" {
  value = module.eks.cluster_name
}
output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
