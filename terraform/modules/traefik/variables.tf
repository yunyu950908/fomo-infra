# Traefik 模块变量定义

variable "namespace" {
  description = "Traefik 部署的命名空间"
  type        = string
  default     = "infra"
}

variable "release_name" {
  description = "Traefik 发布名称"
  type        = string
  default     = "traefik"
}

variable "traefik_version" {
  description = "Traefik 版本"
  type        = string
  default     = "3.5"

variable "image_repository" {
  description = "Traefik 镜像仓库"
  type        = string
  default     = "traefik"
}

variable "replicas" {
  description = "副本数量"
  type        = number
  default     = 1
}

variable "web_node_port" {
  description = "HTTP 访问的 NodePort 端口"
  type        = number
  default     = 30080
}

variable "websecure_node_port" {
  description = "HTTPS 访问的 NodePort 端口"
  type        = number
  default     = 30443
}

variable "dashboard_node_port" {
  description = "仪表板访问的 NodePort 端口"
  type        = number
  default     = 30088
}

variable "log_level" {
  description = "日志级别"
  type        = string
  default     = "INFO"
  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.log_level)
    error_message = "日志级别必须是 DEBUG, INFO, WARN, 或 ERROR 之一。"
  }
}

variable "access_log_enabled" {
  description = "是否启用访问日志"
  type        = bool
  default     = true
}

variable "dashboard_enabled" {
  description = "是否启用仪表板"
  type        = bool
  default     = true
}

variable "metrics_enabled" {
  description = "是否启用 Prometheus 指标"
  type        = bool
  default     = true
}

variable "tls_enabled" {
  description = "是否启用 TLS"
  type        = bool
  default     = false
}

variable "set_as_default_ingress_class" {
  description = "是否设置为默认入口类"
  type        = bool
  default     = true
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
      memory = "100Mi"
      cpu    = "200m"
    }
  }
}