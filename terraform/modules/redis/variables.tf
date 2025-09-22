# Redis 模块变量定义（4C8G 单节点优化）

variable "namespace" {
  description = "Redis 部署的命名空间"
  type        = string
  default     = "infra"
}

variable "release_name" {
  description = "Redis Helm 发布名称"
  type        = string
  default     = "redis"
}

variable "chart_version" {
  description = "Bitnami Redis Helm Chart 版本"
  type        = string
  default     = "19.0.0"
}

variable "redis_version" {
  description = "Redis 版本"
  type        = string
  default     = "7.2"
}

variable "architecture" {
  description = "Redis 架构（单节点优化为 standalone）"
  type        = string
  default     = "standalone"
  validation {
    condition     = contains(["standalone", "replication"], var.architecture)
    error_message = "架构必须是 standalone 或 replication。"
  }
}

variable "auth" {
  description = "认证配置"
  type = object({
    enabled  = bool
    password = string
  })
  default = {
    enabled  = true
    password = "RedisSecure2024!"
  }
}

variable "external_ports" {
  description = "外部访问端口配置"
  type = object({
    redis = number
  })
  default = {
    redis = 30379
  }
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
      memory = "256Mi"
      cpu    = "100m"
    }
    limits = {
      memory = "1Gi"
      cpu    = "500m"
    }
  }
}

variable "replica" {
  description = "副本配置（单节点关闭）"
  type = object({
    enabled = bool
    count   = number
  })
  default = {
    enabled = false
    count   = 0
  }
}

variable "sentinel" {
  description = "哨兵配置（单节点关闭）"
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
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

variable "max_memory_policy" {
  description = "最大内存策略"
  type        = string
  default     = "allkeys-lru"
  validation {
    condition = contains([
      "noeviction", "allkeys-lru", "allkeys-lfu", "allkeys-random",
      "volatile-lru", "volatile-lfu", "volatile-random", "volatile-ttl"
    ], var.max_memory_policy)
    error_message = "内存策略必须是有效的 Redis maxmemory-policy 值。"
  }
}