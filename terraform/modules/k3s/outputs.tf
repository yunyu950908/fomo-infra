# K3s 模块输出

output "node_ip" {
  description = "K3s 节点 IP 地址"
  value       = data.external.cluster_info.result.node_ip
}

output "kubeconfig_path" {
  description = "kubeconfig 文件路径"
  value       = "/etc/rancher/k3s/k3s.yaml"
}

output "storage_class" {
  description = "默认存储类名称"
  value       = "local-path"
}

output "storage_path" {
  description = "本地存储路径"
  value       = var.storage_path
}

output "cluster_cidr" {
  description = "集群 Pod CIDR"
  value       = var.cluster_cidr
}

output "service_cidr" {
  description = "集群 Service CIDR"
  value       = var.service_cidr
}

output "cluster_dns" {
  description = "集群 DNS 地址"
  value       = var.cluster_dns
}

output "k3s_version" {
  description = "K3s 版本"
  value       = var.k3s_version
}

output "uninstall_script" {
  description = "卸载脚本路径"
  value       = "/usr/local/bin/k3s-fomo-uninstall.sh"
}