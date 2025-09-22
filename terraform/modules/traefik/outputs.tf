# Traefik 模块输出

output "namespace" {
  description = "Traefik 部署的命名空间"
  value       = kubernetes_namespace.traefik.metadata[0].name
}

output "service_name" {
  description = "Traefik 服务名称"
  value       = kubernetes_service.traefik.metadata[0].name
}

output "web_port" {
  description = "HTTP 访问端口"
  value       = var.web_node_port
}

output "websecure_port" {
  description = "HTTPS 访问端口"
  value       = var.websecure_node_port
}

output "dashboard_port" {
  description = "仪表板访问端口"
  value       = var.dashboard_node_port
}

output "ingress_class_name" {
  description = "入口类名称"
  value       = kubernetes_ingress_class_v1.traefik.metadata[0].name
}

output "version" {
  description = "Traefik 版本"
  value       = var.traefik_version
}

locals {
  access_urls = {
    dashboard  = "http://NODE_IP:${var.dashboard_node_port}/dashboard/"
    http       = "http://NODE_IP:${var.web_node_port}"
    https      = "https://NODE_IP:${var.websecure_node_port}"
  }
}

output "access_urls" {
  description = "Traefik 访问地址"
  value       = local.access_urls
}