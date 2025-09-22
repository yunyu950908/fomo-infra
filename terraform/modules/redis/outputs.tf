# Redis 模块输出

output "namespace" {
  description = "Redis 部署的命名空间"
  value       = kubernetes_namespace.redis.metadata[0].name
}

output "release_name" {
  description = "Redis Helm 发布名称"
  value       = helm_release.redis.name
}

output "service_name" {
  description = "Redis 服务名称"
  value       = var.release_name
}

output "redis_port" {
  description = "Redis 外部访问端口"
  value       = var.external_ports.redis
}

output "password" {
  description = "Redis 密码"
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
  description = "Redis 版本"
  value       = var.redis_version
}

output "architecture" {
  description = "Redis 架构"
  value       = var.architecture
}

output "max_memory_policy" {
  description = "最大内存策略"
  value       = var.max_memory_policy
}

locals {
  access_urls = {
    external_cli = "redis-cli -h NODE_IP -p ${var.external_ports.redis} -a ${var.auth.password}"
    external_url = "redis://:${var.auth.password}@NODE_IP:${var.external_ports.redis}"
    internal_url = "redis://:${var.auth.password}@${var.release_name}.${kubernetes_namespace.redis.metadata[0].name}.svc.cluster.local:6379"
  }
}

output "access_urls" {
  description = "Redis 访问地址和连接信息"
  value       = local.access_urls
  sensitive   = true
}