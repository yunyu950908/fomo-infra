# FOMO Infrastructure 变量定义 - 4C8G 单节点部署

# ==============================================
# K3s 集群配置
# ==============================================

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
  description = "每个节点最大 Pod 数量（4C8G 优化）"
  type        = number
  default     = 110
}

variable "memory_threshold" {
  description = "内存驱逐阈值（4C8G 优化）"
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

variable "storage_class" {
  description = "存储类名称"
  type        = string
  default     = "local-path"
}

# ==============================================
# Portainer 配置
# ==============================================

variable "portainer_namespace" {
  description = "Portainer 命名空间"
  type        = string
  default     = "infra"
}

variable "portainer_release_name" {
  description = "Portainer Helm 发布名称"
  type        = string
  default     = "portainer"
}

variable "portainer_image_tag" {
  description = "Portainer 镜像版本"
  type        = string
  default     = "2.19.4"
}

variable "portainer_external_port" {
  description = "Portainer 外部端口"
  type        = number
  default     = 30777
}

# ==============================================
# Traefik 配置
# ==============================================

variable "traefik_namespace" {
  description = "Traefik 命名空间"
  type        = string
  default     = "infra"
}

variable "traefik_release_name" {
  description = "Traefik Helm 发布名称"
  type        = string
  default     = "traefik"
}

variable "traefik_chart_version" {
  description = "Traefik Helm Chart 版本"
  type        = string
  default     = "28.0.0"
}

variable "traefik_external_port" {
  description = "Traefik 外部端口"
  type        = number
  default     = 30080
}

# ==============================================
# 监控系统配置
# ==============================================

variable "monitoring_namespace" {
  description = "监控系统命名空间"
  type        = string
  default     = "infra"
}

# Prometheus 配置
variable "prometheus_chart_version" {
  description = "Prometheus Helm Chart 版本"
  type        = string
  default     = "0.6.0"
}

variable "prometheus_version" {
  description = "Prometheus 版本"
  type        = string
  default     = "2.48.0"
}

variable "prometheus_external_port" {
  description = "Prometheus 外部端口"
  type        = number
  default     = 30090
}

variable "prometheus_storage_size" {
  description = "Prometheus 存储大小"
  type        = string
  default     = "15Gi"
}

variable "prometheus_memory_request" {
  description = "Prometheus 内存请求"
  type        = string
  default     = "256Mi"
}

variable "prometheus_cpu_request" {
  description = "Prometheus CPU 请求"
  type        = string
  default     = "100m"
}

variable "prometheus_memory_limit" {
  description = "Prometheus 内存限制"
  type        = string
  default     = "1Gi"
}

variable "prometheus_cpu_limit" {
  description = "Prometheus CPU 限制"
  type        = string
  default     = "500m"
}

variable "prometheus_retention" {
  description = "Prometheus 数据保留时间"
  type        = string
  default     = "15d"
}

variable "prometheus_scrape_interval" {
  description = "Prometheus 抓取间隔"
  type        = string
  default     = "30s"
}

variable "prometheus_evaluation_interval" {
  description = "Prometheus 规则评估间隔"
  type        = string
  default     = "30s"
}

variable "prometheus_alertmanager_url" {
  description = "Alertmanager URL（可选，留空表示不配置告警）"
  type        = string
  default     = "http://alertmanager.infra.svc.cluster.local:9093"
}

# Grafana 配置
variable "grafana_chart_version" {
  description = "Grafana Helm Chart 版本"
  type        = string
  default     = "11.0.0"
}

variable "grafana_version" {
  description = "Grafana 版本"
  type        = string
  default     = "10.2.2"
}

variable "grafana_external_port" {
  description = "Grafana 外部端口"
  type        = number
  default     = 30030
}

variable "grafana_admin_username" {
  description = "Grafana 管理员用户名"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana 管理员密码"
  type        = string
  default     = "GrafanaAdmin2024!"
  sensitive   = true
}

variable "grafana_storage_size" {
  description = "Grafana 存储大小"
  type        = string
  default     = "5Gi"
}

variable "grafana_memory_request" {
  description = "Grafana 内存请求"
  type        = string
  default     = "128Mi"
}

variable "grafana_cpu_request" {
  description = "Grafana CPU 请求"
  type        = string
  default     = "50m"
}

variable "grafana_memory_limit" {
  description = "Grafana 内存限制"
  type        = string
  default     = "512Mi"
}

variable "grafana_cpu_limit" {
  description = "Grafana CPU 限制"
  type        = string
  default     = "250m"
}

variable "grafana_prometheus_url" {
  description = "Prometheus URL（可选，留空表示不自动配置）"
  type        = string
  default     = "http://prometheus.infra.svc.cluster.local:9090"
}

variable "grafana_plugins" {
  description = "Grafana 插件列表"
  type        = list(string)
  default = [
    "grafana-piechart-panel",
    "grafana-worldmap-panel",
    "grafana-clock-panel"
  ]
}

variable "grafana_dashboards_enabled" {
  description = "是否启用预装仪表板"
  type        = bool
  default     = true
}

variable "grafana_smtp_enabled" {
  description = "是否启用 SMTP"
  type        = bool
  default     = false
}

variable "grafana_smtp_host" {
  description = "SMTP 主机"
  type        = string
  default     = ""
}

variable "grafana_smtp_port" {
  description = "SMTP 端口"
  type        = number
  default     = 587
}

variable "grafana_smtp_user" {
  description = "SMTP 用户名"
  type        = string
  default     = ""
}

variable "grafana_smtp_password" {
  description = "SMTP 密码"
  type        = string
  default     = ""
  sensitive   = true
}

variable "grafana_smtp_from_name" {
  description = "SMTP 发件人名称"
  type        = string
  default     = "Grafana"
}

variable "grafana_smtp_from_email" {
  description = "SMTP 发件人邮箱"
  type        = string
  default     = "grafana@example.com"
}

# Alertmanager 配置
variable "alertmanager_chart_version" {
  description = "Alertmanager Helm Chart 版本"
  type        = string
  default     = "0.3.0"
}

variable "alertmanager_version" {
  description = "Alertmanager 版本"
  type        = string
  default     = "0.26.0"
}

variable "alertmanager_external_port" {
  description = "Alertmanager 外部端口"
  type        = number
  default     = 30093
}

variable "alertmanager_storage_size" {
  description = "Alertmanager 存储大小"
  type        = string
  default     = "2Gi"
}

variable "alertmanager_memory_request" {
  description = "Alertmanager 内存请求"
  type        = string
  default     = "64Mi"
}

variable "alertmanager_cpu_request" {
  description = "Alertmanager CPU 请求"
  type        = string
  default     = "25m"
}

variable "alertmanager_memory_limit" {
  description = "Alertmanager 内存限制"
  type        = string
  default     = "256Mi"
}

variable "alertmanager_cpu_limit" {
  description = "Alertmanager CPU 限制"
  type        = string
  default     = "100m"
}

variable "alertmanager_retention" {
  description = "Alertmanager 数据保留时间"
  type        = string
  default     = "120h"
}

variable "alertmanager_smtp_enabled" {
  description = "是否启用 SMTP 邮件通知"
  type        = bool
  default     = false
}

variable "alertmanager_smtp_smarthost" {
  description = "SMTP 服务器地址"
  type        = string
  default     = "localhost:587"
}

variable "alertmanager_smtp_from" {
  description = "邮件发件人地址"
  type        = string
  default     = "alertmanager@example.com"
}

variable "alertmanager_smtp_username" {
  description = "SMTP 用户名"
  type        = string
  default     = ""
}

variable "alertmanager_smtp_password" {
  description = "SMTP 密码"
  type        = string
  default     = ""
  sensitive   = true
}

variable "alertmanager_smtp_require_tls" {
  description = "是否要求 TLS"
  type        = bool
  default     = true
}

variable "alertmanager_webhook_enabled" {
  description = "是否启用 Webhook 通知"
  type        = bool
  default     = false
}

variable "alertmanager_webhook_url" {
  description = "Webhook URL"
  type        = string
  default     = ""
}

variable "alertmanager_slack_enabled" {
  description = "是否启用 Slack 通知"
  type        = bool
  default     = false
}

variable "alertmanager_slack_api_url" {
  description = "Slack API URL"
  type        = string
  default     = ""
  sensitive   = true
}

variable "alertmanager_slack_channel" {
  description = "Slack 频道"
  type        = string
  default     = "#alerts"
}

variable "alertmanager_slack_username" {
  description = "Slack 用户名"
  type        = string
  default     = "alertmanager"
}

variable "alertmanager_slack_icon_emoji" {
  description = "Slack 图标"
  type        = string
  default     = ":warning:"
}

variable "alertmanager_wechat_enabled" {
  description = "是否启用企业微信通知"
  type        = bool
  default     = false
}

variable "alertmanager_wechat_corp_id" {
  description = "企业微信企业ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "alertmanager_wechat_corp_secret" {
  description = "企业微信应用密钥"
  type        = string
  default     = ""
  sensitive   = true
}

variable "alertmanager_wechat_agent_id" {
  description = "企业微信应用ID"
  type        = string
  default     = ""
}

variable "alertmanager_wechat_to_user" {
  description = "企业微信接收用户"
  type        = string
  default     = "@all"
}

variable "alertmanager_wechat_to_party" {
  description = "企业微信接收部门"
  type        = string
  default     = ""
}

variable "alertmanager_wechat_to_tag" {
  description = "企业微信接收标签"
  type        = string
  default     = ""
}

variable "alertmanager_group_by" {
  description = "告警分组字段"
  type        = list(string)
  default     = ["alertname", "cluster", "service"]
}

variable "alertmanager_group_wait" {
  description = "分组等待时间"
  type        = string
  default     = "10s"
}

variable "alertmanager_group_interval" {
  description = "分组间隔时间"
  type        = string
  default     = "10s"
}

variable "alertmanager_repeat_interval" {
  description = "重复发送间隔"
  type        = string
  default     = "1h"
}

variable "alertmanager_inhibit_enabled" {
  description = "是否启用告警抑制规则"
  type        = bool
  default     = true
}

# ==============================================
# MongoDB 配置
# ==============================================

variable "mongodb_namespace" {
  description = "MongoDB 命名空间"
  type        = string
  default     = "infra"
}

variable "mongodb_release_name" {
  description = "MongoDB Helm 发布名称"
  type        = string
  default     = "mongodb"
}

variable "mongodb_chart_version" {
  description = "MongoDB Helm Chart 版本"
  type        = string
  default     = "15.1.0"
}

variable "mongodb_version" {
  description = "MongoDB 版本"
  type        = string
  default     = "7.0"
}

variable "mongodb_architecture" {
  description = "MongoDB 架构"
  type        = string
  default     = "standalone"
}

variable "mongodb_replica_count" {
  description = "MongoDB 副本数量"
  type        = number
  default     = 1
}

variable "mongodb_external_port" {
  description = "MongoDB 外部端口"
  type        = number
  default     = 30017
}

variable "mongodb_root_user" {
  description = "MongoDB 根用户名"
  type        = string
  default     = "admin"
}

variable "mongodb_root_password" {
  description = "MongoDB 根密码"
  type        = string
  default     = "MongoAdmin2024!"
  sensitive   = true
}

variable "mongodb_usernames" {
  description = "MongoDB 用户名列表"
  type        = list(string)
  default     = ["appuser"]
}

variable "mongodb_passwords" {
  description = "MongoDB 密码列表"
  type        = list(string)
  default     = ["AppUser2024!"]
  sensitive   = true
}

variable "mongodb_databases" {
  description = "MongoDB 数据库列表"
  type        = list(string)
  default     = ["app_database"]
}

variable "mongodb_storage_size" {
  description = "MongoDB 存储大小"
  type        = string
  default     = "20Gi"
}

variable "mongodb_memory_request" {
  description = "MongoDB 内存请求"
  type        = string
  default     = "512Mi"
}

variable "mongodb_cpu_request" {
  description = "MongoDB CPU 请求"
  type        = string
  default     = "250m"
}

variable "mongodb_memory_limit" {
  description = "MongoDB 内存限制"
  type        = string
  default     = "2Gi"
}

variable "mongodb_cpu_limit" {
  description = "MongoDB CPU 限制"
  type        = string
  default     = "1000m"
}

# ==============================================
# Redis 配置
# ==============================================

variable "redis_namespace" {
  description = "Redis 命名空间"
  type        = string
  default     = "infra"
}

variable "redis_release_name" {
  description = "Redis Helm 发布名称"
  type        = string
  default     = "redis"
}

variable "redis_chart_version" {
  description = "Redis Helm Chart 版本"
  type        = string
  default     = "19.0.0"
}

variable "redis_version" {
  description = "Redis 版本"
  type        = string
  default     = "7.2"
}

variable "redis_architecture" {
  description = "Redis 架构"
  type        = string
  default     = "standalone"
}

variable "redis_auth_enabled" {
  description = "是否启用 Redis 认证"
  type        = bool
  default     = true
}

variable "redis_auth_password" {
  description = "Redis 认证密码"
  type        = string
  default     = "RedisSecure2024!"
  sensitive   = true
}

variable "redis_external_port" {
  description = "Redis 外部端口"
  type        = number
  default     = 30379
}

variable "redis_storage_size" {
  description = "Redis 存储大小"
  type        = string
  default     = "5Gi"
}

variable "redis_memory_request" {
  description = "Redis 内存请求"
  type        = string
  default     = "256Mi"
}

variable "redis_cpu_request" {
  description = "Redis CPU 请求"
  type        = string
  default     = "100m"
}

variable "redis_memory_limit" {
  description = "Redis 内存限制"
  type        = string
  default     = "1Gi"
}

variable "redis_cpu_limit" {
  description = "Redis CPU 限制"
  type        = string
  default     = "500m"
}

variable "redis_replica_enabled" {
  description = "是否启用 Redis 副本"
  type        = bool
  default     = false
}

variable "redis_replica_count" {
  description = "Redis 副本数量"
  type        = number
  default     = 0
}

variable "redis_sentinel_enabled" {
  description = "是否启用 Redis 哨兵"
  type        = bool
  default     = false
}

variable "redis_max_memory_policy" {
  description = "Redis 最大内存策略"
  type        = string
  default     = "allkeys-lru"
}

# ==============================================
# RabbitMQ 配置
# ==============================================

variable "rabbitmq_namespace" {
  description = "RabbitMQ 命名空间"
  type        = string
  default     = "infra"
}

variable "rabbitmq_release_name" {
  description = "RabbitMQ Helm 发布名称"
  type        = string
  default     = "rabbitmq"
}

variable "rabbitmq_chart_version" {
  description = "RabbitMQ Helm Chart 版本"
  type        = string
  default     = "14.0.0"
}

variable "rabbitmq_version" {
  description = "RabbitMQ 版本"
  type        = string
  default     = "3.13"
}

variable "rabbitmq_replica_count" {
  description = "RabbitMQ 副本数量"
  type        = number
  default     = 1
}

variable "rabbitmq_username" {
  description = "RabbitMQ 用户名"
  type        = string
  default     = "admin"
}

variable "rabbitmq_password" {
  description = "RabbitMQ 密码"
  type        = string
  default     = "RabbitAdmin2024!"
  sensitive   = true
}

variable "rabbitmq_erlang_cookie" {
  description = "RabbitMQ Erlang Cookie"
  type        = string
  default     = "secreterlangcookie2024"
  sensitive   = true
}

variable "rabbitmq_clustering_enabled" {
  description = "是否启用 RabbitMQ 集群"
  type        = bool
  default     = false
}

variable "rabbitmq_amqp_port" {
  description = "RabbitMQ AMQP 外部端口"
  type        = number
  default     = 30672
}

variable "rabbitmq_management_port" {
  description = "RabbitMQ 管理界面外部端口"
  type        = number
  default     = 31672
}

variable "rabbitmq_default_vhost" {
  description = "RabbitMQ 默认虚拟主机"
  type        = string
  default     = "/"
}

variable "rabbitmq_plugins" {
  description = "RabbitMQ 启用的插件"
  type        = string
  default     = "rabbitmq_management"
}

variable "rabbitmq_storage_size" {
  description = "RabbitMQ 存储大小"
  type        = string
  default     = "8Gi"
}

variable "rabbitmq_memory_request" {
  description = "RabbitMQ 内存请求"
  type        = string
  default     = "512Mi"
}

variable "rabbitmq_cpu_request" {
  description = "RabbitMQ CPU 请求"
  type        = string
  default     = "200m"
}

variable "rabbitmq_memory_limit" {
  description = "RabbitMQ 内存限制"
  type        = string
  default     = "1.5Gi"
}

variable "rabbitmq_cpu_limit" {
  description = "RabbitMQ CPU 限制"
  type        = string
  default     = "750m"
}

variable "rabbitmq_memory_high_watermark" {
  description = "RabbitMQ 内存高水位阈值"
  type        = number
  default     = 0.4
}