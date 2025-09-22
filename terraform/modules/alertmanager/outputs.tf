# Alertmanager 模块输出

output "namespace" {
  description = "Alertmanager 命名空间"
  value       = var.namespace
}

output "release_name" {
  description = "Alertmanager Helm 发布名称"
  value       = helm_release.alertmanager.name
}

output "alertmanager_url_internal" {
  description = "Alertmanager 内部访问地址"
  value       = "http://${var.release_name}.${var.namespace}.svc.cluster.local:9093"
}

output "alertmanager_url_external" {
  description = "Alertmanager 外部访问地址"
  value       = "http://NODE_IP:${var.external_port}"
}

output "connection_info_file" {
  description = "连接信息文件路径"
  value       = local_file.connection_info.filename
}