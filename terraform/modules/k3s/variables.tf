# K3s 模块变量定义

variable "k3s_version" {
  description = "K3s 版本"
  type        = string
  default     = "v1.32.0+k3s1"
}

variable "cluster_cidr" {
  description = "集群 Pod CIDR 网络段"
  type        = string
  default     = "10.42.0.0/16"
}

variable "service_cidr" {
  description = "集群 Service CIDR 网络段"
  type        = string
  default     = "10.43.0.0/16"
}

variable "cluster_dns" {
  description = "集群 DNS 服务地址"
  type        = string
  default     = "10.43.0.10"
}

variable "disabled_addons" {
  description = "要禁用的 K3s 插件列表"
  type        = list(string)
  default     = ["traefik", "servicelb", "metrics-server"]
}

variable "flannel_backend" {
  description = "Flannel 网络后端类型"
  type        = string
  default     = "vxlan"
}

variable "storage_path" {
  description = "本地路径存储的存储目录"
  type        = string
  default     = "/opt/local-path-provisioner"
}

variable "max_pods" {
  description = "每个节点最大 Pod 数量"
  type        = number
  default     = 110
}

variable "memory_threshold" {
  description = "内存驱逐阈值"
  type        = string
  default     = "200Mi"
}

variable "disk_threshold" {
  description = "磁盘空间驱逐阈值"
  type        = string
  default     = "10%"
}

variable "inode_threshold" {
  description = "inode 驱逐阈值"
  type        = string
  default     = "5%"
}

variable "imagefs_threshold" {
  description = "镜像文件系统驱逐阈值"
  type        = string
  default     = "15%"
}