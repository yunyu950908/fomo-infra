# Grafana 可视化模块变量定义（4C8G 单节点优化）

variable "namespace" {
  description = "Grafana 部署的命名空间"
  type        = string
  default     = "infra"
}

variable "release_name" {
  description = "Grafana Helm 发布名称"
  type        = string
  default     = "grafana"
}

variable "chart_version" {
  description = "Bitnami Grafana Helm Chart 版本"
  type        = string
  default     = "11.0.0"
}

variable "grafana_version" {
  description = "Grafana 版本"
  type        = string
  default     = "10.2.2"
}

variable "external_port" {
  description = "外部访问的 NodePort 端口"
  type        = number
  default     = 30030
}

variable "admin_credentials" {
  description = "管理员认证配置"
  type = object({
    username = string
    password = string
  })
  default = {
    username = "admin"
    password = "GrafanaAdmin2024!"
  }
  sensitive = true
}

variable "storage" {
  description = "存储配置（4C8G 单节点优化）"
  type = object({
    class = string
    size  = string
  })
  default = {
    class = "local-path"
    size  = "5Gi"
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
      memory = "128Mi"
      cpu    = "50m"
    }
    limits = {
      memory = "512Mi"
      cpu    = "250m"
    }
  }
}

variable "prometheus_url" {
  description = "Prometheus 数据源地址"
  type        = string
  default     = "http://prometheus.infra.svc.cluster.local:9090"
}

variable "plugins" {
  description = "需要安装的插件列表"
  type        = list(string)
  default = [
    "grafana-piechart-panel",
    "grafana-worldmap-panel",
    "grafana-clock-panel"
  ]
}

variable "dashboards" {
  description = "预装仪表板配置"
  type = object({
    enabled = bool
  })
  default = {
    enabled = true
  }
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

variable "smtp" {
  description = "SMTP 邮件配置（用于告警通知）"
  type = object({
    enabled   = bool
    host      = string
    port      = number
    user      = string
    password  = string
    from_name = string
    from_email = string
  })
  default = {
    enabled    = false
    host       = ""
    port       = 587
    user       = ""
    password   = ""
    from_name  = "Grafana"
    from_email = "grafana@example.com"
  }
  sensitive = true
}