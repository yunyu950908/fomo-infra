# RabbitMQ 模块变量定义（4C8G 单节点优化）

variable "namespace" {
  description = "RabbitMQ 部署的命名空间"
  type        = string
  default     = "infra"
}

variable "release_name" {
  description = "RabbitMQ Helm 发布名称"
  type        = string
  default     = "rabbitmq"
}

variable "chart_version" {
  description = "Bitnami RabbitMQ Helm Chart 版本"
  type        = string
  default     = "14.0.0"
}

variable "rabbitmq_version" {
  description = "RabbitMQ 版本"
  type        = string
  default     = "3.13"
}

variable "replica_count" {
  description = "副本数量（单节点模式）"
  type        = number
  default     = 1
}

variable "auth" {
  description = "认证配置"
  type = object({
    username      = string
    password      = string
    erlang_cookie = string
  })
  default = {
    username      = "admin"
    password      = "RabbitAdmin2024!"
    erlang_cookie = "secreterlangcookie2024"
  }
}

variable "clustering" {
  description = "集群配置（单节点关闭）"
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

variable "external_ports" {
  description = "外部访问端口配置"
  type = object({
    amqp       = number
    management = number
  })
  default = {
    amqp       = 30672
    management = 31672
  }
}

variable "default_vhost" {
  description = "默认虚拟主机"
  type        = string
  default     = "/"
}

variable "plugins" {
  description = "启用的插件列表"
  type        = string
  default     = "rabbitmq_management"
}

variable "storage" {
  description = "存储配置（4C8G 单节点优化）"
  type = object({
    class = string
    size  = string
  })
  default = {
    class = "local-path"
    size  = "8Gi"
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
      memory = "512Mi"
      cpu    = "200m"
    }
    limits = {
      memory = "1.5Gi"
      cpu    = "750m"
    }
  }
}

variable "memory_high_watermark" {
  description = "内存高水位阈值（单节点优化）"
  type        = number
  default     = 0.4
}

variable "metrics" {
  description = "指标收集配置（单节点关闭以节省资源）"
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
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

variable "pdb" {
  description = "Pod 中断预算配置（单节点关闭）"
  type = object({
    enabled       = bool
    min_available = number
  })
  default = {
    enabled       = false
    min_available = 1
  }
}