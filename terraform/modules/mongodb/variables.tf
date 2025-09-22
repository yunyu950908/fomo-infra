# MongoDB 模块变量定义

variable "namespace" {
  description = "MongoDB 部署的命名空间"
  type        = string
  default     = "infra"
}

variable "release_name" {
  description = "MongoDB Helm 发布名称"
  type        = string
  default     = "mongodb"
}

variable "chart_version" {
  description = "Bitnami MongoDB Helm Chart 版本"
  type        = string
  default     = "15.1.0"
}

variable "mongodb_version" {
  description = "MongoDB 版本"
  type        = string
  default     = "7.0"
}

variable "architecture" {
  description = "MongoDB 架构 (standalone 或 replicaset) - 4C8G 单节点推荐 standalone"
  type        = string
  default     = "standalone"
  validation {
    condition     = contains(["standalone", "replicaset"], var.architecture)
    error_message = "架构必须是 standalone 或 replicaset。"
  }
}

variable "replica_count" {
  description = "副本集节点数量（单节点模式）"
  type        = number
  default     = 1
}

variable "external_port" {
  description = "外部访问的 NodePort 端口"
  type        = number
  default     = 30017
}

variable "auth" {
  description = "认证配置"
  type = object({
    root_user     = string
    root_password = string
    usernames     = list(string)
    passwords     = list(string)
    databases     = list(string)
  })
  default = {
    root_user     = "admin"
    root_password = "MongoAdmin2024!"
    usernames     = ["appuser"]
    passwords     = ["AppUser2024!"]
    databases     = ["app_database"]
  }
}

variable "storage" {
  description = "存储配置（4C8G 优化，支持扩展到 8C16G）"
  type = object({
    class = string
    size  = string
  })
  default = {
    class = "local-path"
    size  = "20Gi"
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
      cpu    = "250m"
    }
    limits = {
      memory = "2Gi"
      cpu    = "1000m"
    }
  }
}

variable "arbiter" {
  description = "仲裁者配置（单节点模式下禁用）"
  type = object({
    enabled = bool
    resources = object({
      requests = object({
        memory = string
        cpu    = string
      })
      limits = object({
        memory = string
        cpu    = string
      })
    })
  })
  default = {
    enabled = false
    resources = {
      requests = {
        memory = "128Mi"
        cpu    = "50m"
      }
      limits = {
        memory = "256Mi"
        cpu    = "100m"
      }
    }
  }
}

variable "metrics" {
  description = "指标收集配置（单节点资源优化）"
  type = object({
    enabled = bool
    resources = object({
      requests = object({
        memory = string
        cpu    = string
      })
      limits = object({
        memory = string
        cpu    = string
      })
    })
  })
  default = {
    enabled = false
    resources = {
      requests = {
        memory = "64Mi"
        cpu    = "50m"
      }
      limits = {
        memory = "128Mi"
        cpu    = "100m"
      }
    }
  }
}

variable "backup" {
  description = "备份配置"
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
  description = "Pod 中断预算配置"
  type = object({
    enabled       = bool
    min_available = number
  })
  default = {
    enabled       = true
    min_available = 1
  }
}