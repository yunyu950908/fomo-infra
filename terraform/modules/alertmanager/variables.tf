# Alertmanager 告警模块变量定义（4C8G 单节点优化）

variable "namespace" {
  description = "Alertmanager 部署的命名空间"
  type        = string
  default     = "infra"
}

variable "release_name" {
  description = "Alertmanager Helm 发布名称"
  type        = string
  default     = "alertmanager"
}

variable "chart_version" {
  description = "Bitnami Alertmanager Helm Chart 版本"
  type        = string
  default     = "0.3.0"
}

variable "alertmanager_version" {
  description = "Alertmanager 版本"
  type        = string
  default     = "0.26.0"
}

variable "external_port" {
  description = "外部访问的 NodePort 端口"
  type        = number
  default     = 30093
}

variable "storage" {
  description = "存储配置（4C8G 单节点优化）"
  type = object({
    class = string
    size  = string
  })
  default = {
    class = "local-path"
    size  = "2Gi"
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
      memory = "64Mi"
      cpu    = "25m"
    }
    limits = {
      memory = "256Mi"
      cpu    = "100m"
    }
  }
}

variable "retention" {
  description = "告警数据保留时间"
  type        = string
  default     = "120h"
}

variable "smtp" {
  description = "SMTP 邮件配置"
  type = object({
    enabled      = bool
    smarthost    = string
    from         = string
    auth_username = string
    auth_password = string
    require_tls  = bool
  })
  default = {
    enabled      = false
    smarthost    = "localhost:587"
    from         = "alertmanager@example.com"
    auth_username = ""
    auth_password = ""
    require_tls  = true
  }
  sensitive = true
}

variable "webhook" {
  description = "Webhook 通知配置"
  type = object({
    enabled = bool
    url     = string
  })
  default = {
    enabled = false
    url     = ""
  }
}

variable "slack" {
  description = "Slack 通知配置"
  type = object({
    enabled    = bool
    api_url    = string
    channel    = string
    username   = string
    icon_emoji = string
  })
  default = {
    enabled    = false
    api_url    = ""
    channel    = "#alerts"
    username   = "alertmanager"
    icon_emoji = ":warning:"
  }
  sensitive = true
}

variable "wechat" {
  description = "企业微信通知配置"
  type = object({
    enabled   = bool
    corp_id   = string
    corp_secret = string
    agent_id  = string
    to_user   = string
    to_party  = string
    to_tag    = string
  })
  default = {
    enabled   = false
    corp_id   = ""
    corp_secret = ""
    agent_id  = ""
    to_user   = "@all"
    to_party  = ""
    to_tag    = ""
  }
  sensitive = true
}

variable "routes" {
  description = "告警路由配置"
  type = object({
    group_by = list(string)
    group_wait = string
    group_interval = string
    repeat_interval = string
  })
  default = {
    group_by       = ["alertname", "cluster", "service"]
    group_wait     = "10s"
    group_interval = "10s"
    repeat_interval = "1h"
  }
}

variable "inhibit_rules" {
  description = "告警抑制规则配置"
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