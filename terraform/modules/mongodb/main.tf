# MongoDB 数据库模块
# 使用 Bitnami Helm Chart 部署 MongoDB 副本集

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
resource "kubernetes_namespace" "mongodb" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "mongodb"
      "app.kubernetes.io/instance" = var.release_name
    }
  }
}

# 部署 MongoDB Helm Chart
resource "helm_release" "mongodb" {
  name       = var.release_name
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mongodb"
  version    = var.chart_version
  namespace  = kubernetes_namespace.mongodb.metadata[0].name

  values = [
    templatefile("${path.module}/templates/values.yaml.tpl", {
      mongodb_version        = var.mongodb_version
      architecture          = var.architecture
      replica_count         = var.replica_count
      root_user            = var.auth.root_user
      root_password        = var.auth.root_password
      usernames            = jsonencode(var.auth.usernames)
      passwords            = jsonencode(var.auth.passwords)
      databases            = jsonencode(var.auth.databases)
      storage_class        = var.storage.class
      storage_size         = var.storage.size
      arbiter_enabled      = var.arbiter.enabled
      metrics_enabled      = var.metrics.enabled
      backup_enabled       = var.backup.enabled
      network_policy_enabled = var.network_policy.enabled
      pdb_enabled          = var.pdb.enabled
      pdb_min_available    = var.pdb.min_available
      memory_request       = var.resources.requests.memory
      cpu_request          = var.resources.requests.cpu
      memory_limit         = var.resources.limits.memory
      cpu_limit            = var.resources.limits.cpu
      arbiter_memory_request = var.arbiter.resources.requests.memory
      arbiter_cpu_request    = var.arbiter.resources.requests.cpu
      arbiter_memory_limit   = var.arbiter.resources.limits.memory
      arbiter_cpu_limit      = var.arbiter.resources.limits.cpu
      metrics_memory_request = var.metrics.resources.requests.memory
      metrics_cpu_request    = var.metrics.resources.requests.cpu
      metrics_memory_limit   = var.metrics.resources.limits.memory
      metrics_cpu_limit      = var.metrics.resources.limits.cpu
    })
  ]

  # 等待部署完成
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  depends_on = [kubernetes_namespace.mongodb]
}

# 创建外部访问的 NodePort 服务
resource "kubernetes_service" "mongodb_external" {
  metadata {
    name      = "${var.release_name}-external"
    namespace = kubernetes_namespace.mongodb.metadata[0].name
  }

  spec {
    type = "NodePort"

    selector = {
      "app.kubernetes.io/name"      = "mongodb"
      "app.kubernetes.io/instance"  = var.release_name
      "app.kubernetes.io/component" = "mongodb"
    }

    port {
      name        = "mongodb"
      port        = 27017
      target_port = 27017
      node_port   = var.external_port
      protocol    = "TCP"
    }
  }

  depends_on = [helm_release.mongodb]
}

# 创建连接信息配置映射
resource "kubernetes_config_map" "mongodb_connection_info" {
  metadata {
    name      = "${var.release_name}-connection-info"
    namespace = kubernetes_namespace.mongodb.metadata[0].name
  }

  data = {
    "connection-info.txt" = templatefile("${path.module}/templates/connection-info.txt.tpl", {
      release_name     = var.release_name
      namespace        = kubernetes_namespace.mongodb.metadata[0].name
      external_port    = var.external_port
      root_user        = var.auth.root_user
      root_password    = var.auth.root_password
      database         = var.auth.databases[0]
      app_user         = var.auth.usernames[0]
      app_password     = var.auth.passwords[0]
      mongodb_version  = var.mongodb_version
    })
  }

  depends_on = [helm_release.mongodb]
}