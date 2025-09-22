# Grafana 模块输出

output "namespace" {
  description = "Grafana 命名空间"
  value       = var.namespace
}

output "release_name" {
  description = "Grafana Helm 发布名称"
  value       = helm_release.grafana.name
}

output "grafana_url_internal" {
  description = "Grafana 内部访问地址"
  value       = "http://${var.release_name}.${var.namespace}.svc.cluster.local:3000"
}

output "grafana_url_external" {
  description = "Grafana 外部访问地址"
  value       = "http://NODE_IP:${var.external_port}"
}

output "admin_credentials" {
  description = "管理员登录凭据"
  value = {
    username = var.admin_credentials.username
    password = var.admin_credentials.password
  }
  sensitive = true
}

output "connection_info_file" {
  description = "连接信息文件路径"
  value       = local_file.connection_info.filename
}