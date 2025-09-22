# Portainer 模块输出

output "namespace" {
  description = "Portainer 部署的命名空间"
  value       = kubernetes_namespace.portainer.metadata[0].name
}

output "service_name" {
  description = "Portainer 服务名称"
  value       = kubernetes_service.portainer.metadata[0].name
}

output "http_port" {
  description = "HTTP 访问端口"
  value       = var.http_node_port
}

output "edge_port" {
  description = "Edge 代理端口"
  value       = var.edge_node_port
}

output "storage_class" {
  description = "使用的存储类"
  value       = var.storage_class
}

output "storage_size" {
  description = "分配的存储大小"
  value       = var.storage_size
}

output "image" {
  description = "使用的镜像"
  value       = "${var.image_repository}:${var.image_tag}"
}

locals {
  # 这个值将在应用后从外部数据源获取
  access_urls = {
    http = "http://NODE_IP:${var.http_node_port}"
    edge = "http://NODE_IP:${var.edge_node_port}"
  }
}

output "access_urls" {
  description = "Portainer 访问地址"
  value       = local.access_urls
}