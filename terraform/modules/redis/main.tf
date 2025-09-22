# Redis 内存数据库模块
# 使用 Bitnami Helm Chart 部署 Redis（单节点优化）

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# 创建命名空间
resource "kubernetes_namespace" "redis" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "redis"
      "app.kubernetes.io/instance" = var.release_name
    }
  }
}

# 部署 Redis Helm Chart
resource "helm_release" "redis" {
  name       = var.release_name
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  version    = var.chart_version
  namespace  = kubernetes_namespace.redis.metadata[0].name

  values = [
    templatefile("${path.module}/templates/values.yaml.tpl", {
      redis_version        = var.redis_version
      architecture        = var.architecture
      auth_enabled        = var.auth.enabled
      auth_password       = var.auth.password
      storage_class       = var.storage.class
      storage_size        = var.storage.size
      memory_request      = var.resources.requests.memory
      cpu_request         = var.resources.requests.cpu
      memory_limit        = var.resources.limits.memory
      cpu_limit           = var.resources.limits.cpu
      replica_count       = var.replica.count
      replica_enabled     = var.replica.enabled
      sentinel_enabled    = var.sentinel.enabled
      metrics_enabled     = var.metrics.enabled
      network_policy_enabled = var.network_policy.enabled
      pdb_enabled         = var.pdb.enabled
      pdb_min_available   = var.pdb.min_available
      max_memory_policy   = var.max_memory_policy
    })
  ]

  # 等待部署完成
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  depends_on = [kubernetes_namespace.redis]
}

# 创建外部访问的 NodePort 服务 - Redis
resource "kubernetes_service" "redis_external" {
  metadata {
    name      = "${var.release_name}-external"
    namespace = kubernetes_namespace.redis.metadata[0].name
  }

  spec {
    type = "NodePort"

    selector = {
      "app.kubernetes.io/name"      = "redis"
      "app.kubernetes.io/instance"  = var.release_name
      "app.kubernetes.io/component" = var.architecture == "standalone" ? "redis" : "master"
    }

    port {
      name        = "tcp-redis"
      port        = 6379
      target_port = 6379
      node_port   = var.external_ports.redis
      protocol    = "TCP"
    }
  }

  depends_on = [helm_release.redis]
}

# 创建连接信息配置映射
resource "kubernetes_config_map" "redis_connection_info" {
  metadata {
    name      = "${var.release_name}-connection-info"
    namespace = kubernetes_namespace.redis.metadata[0].name
  }

  data = {
    "connection-info.txt" = templatefile("${path.module}/templates/connection-info.txt.tpl", {
      release_name      = var.release_name
      namespace         = kubernetes_namespace.redis.metadata[0].name
      redis_port        = var.external_ports.redis
      password          = var.auth.password
      redis_version     = var.redis_version
      architecture      = var.architecture
    })
  }

  depends_on = [helm_release.redis]
}