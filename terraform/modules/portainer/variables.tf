# Portainer 模块变量定义

variable "namespace" {
  description = "Portainer 部署的命名空间"
  type        = string
  default     = "infra"
}

variable "release_name" {
  description = "Portainer 发布名称"
  type        = string
  default     = "portainer"
}

variable "image_repository" {
  description = "Portainer 镜像仓库"
  type        = string
  default     = "portainer/portainer-ee"
}

variable "image_tag" {
  description = "Portainer 镜像标签"
  type        = string
  default     = "2.19.4"
}

variable "storage_class" {
  description = "存储类名称"
  type        = string
  default     = "local-path"
}

variable "storage_size" {
  description = "存储大小（单节点优化）"
  type        = string
  default     = "2Gi"
}

variable "http_node_port" {
  description = "HTTP 访问的 NodePort 端口"
  type        = number
  default     = 30777
}

variable "edge_node_port" {
  description = "Edge 代理的 NodePort 端口"
  type        = number
  default     = 30776
}

variable "log_level" {
  description = "日志级别"
  type        = string
  default     = "INFO"
}

variable "resources" {
  description = "资源限制和请求"
  type = object({
    requests = object({
      memory = string
      cpu    = string
    })
    limits = object({
      memory = string
      cpu    = string
    })
  })
  default = {
    requests = {
      memory = "32Mi"
      cpu    = "50m"
    }
    limits = {
      memory = "128Mi"
      cpu    = "200m"
    }
  }
}