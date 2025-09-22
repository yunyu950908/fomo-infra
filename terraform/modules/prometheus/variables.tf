# Prometheus 监控模块变量定义（4C8G 单节点优化）

variable "namespace" {
  description = "Prometheus 部署的命名空间"
  type        = string
  default     = "infra"
}

variable "release_name" {
  description = "Prometheus Helm 发布名称"
  type        = string
  default     = "prometheus"
}

variable "chart_version" {
  description = "Bitnami Prometheus Helm Chart 版本"
  type        = string
  default     = "0.6.0"
}

variable "prometheus_version" {
  description = "Prometheus 版本"
  type        = string
  default     = "2.48.0"
}

variable "external_port" {
  description = "外部访问的 NodePort 端口"
  type        = number
  default     = 30090
}

variable "storage" {
  description = "存储配置（4C8G 单节点优化）"
  type = object({
    class = string
    size  = string
  })
  default = {
    class = "local-path"
    size  = "15Gi"
  }
}

variable "resources" {
  description = "资源限制和请求（4C8G 优化，支持扩展到 8C16G）"
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
      memory = "256Mi"
      cpu    = "100m"
    }
    limits = {
      memory = "1Gi"
      cpu    = "500m"
    }
  }
}

variable "retention" {
  description = "数据保留时间"
  type        = string
  default     = "15d"
}

variable "scrape_interval" {
  description = "全局抓取间隔"
  type        = string
  default     = "30s"
}

variable "evaluation_interval" {
  description = "规则评估间隔"
  type        = string
  default     = "30s"
}

variable "alertmanager_url" {
  description = "Alertmanager 服务地址"
  type        = string
  default     = "http://alertmanager.infra.svc.cluster.local:9093"
}

variable "network_policy" {
  description = "网络策略配置"
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

variable "service_monitor" {
  description = "启用的 ServiceMonitor 配置"
  type = object({
    enabled = bool
  })
  default = {
    enabled = true
  }
}