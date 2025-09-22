# RabbitMQ 模块输出

output "namespace" {
  description = "RabbitMQ 部署的命名空间"
  value       = kubernetes_namespace.rabbitmq.metadata[0].name
}

output "release_name" {
  description = "RabbitMQ Helm 发布名称"
  value       = helm_release.rabbitmq.name
}

output "service_name" {
  description = "RabbitMQ 服务名称"
  value       = var.release_name
}

output "amqp_port" {
  description = "AMQP 外部访问端口"
  value       = var.external_ports.amqp
}

output "management_port" {
  description = "管理界面外部访问端口"
  value       = var.external_ports.management
}

output "username" {
  description = "RabbitMQ 用户名"
  value       = var.auth.username
  sensitive   = false
}

output "password" {
  description = "RabbitMQ 密码"
  value       = var.auth.password
  sensitive   = true
}

output "storage_class" {
  description = "使用的存储类"
  value       = var.storage.class
}

output "storage_size" {
  description = "分配的存储大小"
  value       = var.storage.size
}

output "version" {
  description = "RabbitMQ 版本"
  value       = var.rabbitmq_version
}

locals {
  access_urls = {
    management = "http://NODE_IP:${var.external_ports.management}"
    amqp       = "amqp://${var.auth.username}:${var.auth.password}@NODE_IP:${var.external_ports.amqp}${var.default_vhost}"
    internal   = "amqp://${var.auth.username}:${var.auth.password}@${var.release_name}.${kubernetes_namespace.rabbitmq.metadata[0].name}.svc.cluster.local:5672${var.default_vhost}"
  }
}

output "access_urls" {
  description = "RabbitMQ 访问地址"
  value       = local.access_urls
  sensitive   = true
}