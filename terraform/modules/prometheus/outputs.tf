# Prometheus 模块输出

output "namespace" {
  description = "Prometheus 命名空间"
  value       = kubernetes_namespace.prometheus.metadata[0].name
}

output "release_name" {
  description = "Prometheus Helm 发布名称"
  value       = helm_release.prometheus.name
}

output "prometheus_url_internal" {
  description = "Prometheus 内部访问地址"
  value       = "http://${var.release_name}.${var.namespace}.svc.cluster.local:9090"
}

output "prometheus_url_external" {
  description = "Prometheus 外部访问地址"
  value       = "http://NODE_IP:${var.external_port}"
}

output "connection_info_file" {
  description = "连接信息文件路径"
  value       = local_file.connection_info.filename
}