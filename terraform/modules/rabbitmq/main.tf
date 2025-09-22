# RabbitMQ 消息队列模块
# 使用 Bitnami Helm Chart 部署 RabbitMQ（单节点优化）

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
resource "kubernetes_namespace" "rabbitmq" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "rabbitmq"
      "app.kubernetes.io/instance" = var.release_name
    }
  }
}

# 部署 RabbitMQ Helm Chart
resource "helm_release" "rabbitmq" {
  name       = var.release_name
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "rabbitmq"
  version    = var.chart_version
  namespace  = kubernetes_namespace.rabbitmq.metadata[0].name

  values = [
    templatefile("${path.module}/templates/values.yaml.tpl", {
      rabbitmq_version     = var.rabbitmq_version
      username            = var.auth.username
      password            = var.auth.password
      erlang_cookie       = var.auth.erlang_cookie
      clustering_enabled  = var.clustering.enabled
      replica_count       = var.replica_count
      storage_class       = var.storage.class
      storage_size        = var.storage.size
      plugins             = var.plugins
      memory_request      = var.resources.requests.memory
      cpu_request         = var.resources.requests.cpu
      memory_limit        = var.resources.limits.memory
      cpu_limit           = var.resources.limits.cpu
      metrics_enabled     = var.metrics.enabled
      network_policy_enabled = var.network_policy.enabled
      pdb_enabled         = var.pdb.enabled
      pdb_min_available   = var.pdb.min_available
      memory_high_watermark = var.memory_high_watermark
    })
  ]

  # 等待部署完成
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  depends_on = [kubernetes_namespace.rabbitmq]
}

# 创建外部访问的 NodePort 服务 - AMQP
resource "kubernetes_service" "rabbitmq_external_amqp" {
  metadata {
    name      = "${var.release_name}-external-amqp"
    namespace = kubernetes_namespace.rabbitmq.metadata[0].name
  }

  spec {
    type = "NodePort"

    selector = {
      "app.kubernetes.io/name"      = "rabbitmq"
      "app.kubernetes.io/instance"  = var.release_name
    }

    port {
      name        = "amqp"
      port        = 5672
      target_port = 5672
      node_port   = var.external_ports.amqp
      protocol    = "TCP"
    }
  }

  depends_on = [helm_release.rabbitmq]
}

# 创建外部访问的 NodePort 服务 - Management
resource "kubernetes_service" "rabbitmq_external_management" {
  metadata {
    name      = "${var.release_name}-external-management"
    namespace = kubernetes_namespace.rabbitmq.metadata[0].name
  }

  spec {
    type = "NodePort"

    selector = {
      "app.kubernetes.io/name"      = "rabbitmq"
      "app.kubernetes.io/instance"  = var.release_name
    }

    port {
      name        = "management"
      port        = 15672
      target_port = 15672
      node_port   = var.external_ports.management
      protocol    = "TCP"
    }
  }

  depends_on = [helm_release.rabbitmq]
}

# 创建连接信息配置映射
resource "kubernetes_config_map" "rabbitmq_connection_info" {
  metadata {
    name      = "${var.release_name}-connection-info"
    namespace = kubernetes_namespace.rabbitmq.metadata[0].name
  }

  data = {
    "connection-info.txt" = templatefile("${path.module}/templates/connection-info.txt.tpl", {
      release_name       = var.release_name
      namespace          = kubernetes_namespace.rabbitmq.metadata[0].name
      amqp_port         = var.external_ports.amqp
      management_port   = var.external_ports.management
      username          = var.auth.username
      password          = var.auth.password
      virtual_host      = var.default_vhost
      rabbitmq_version  = var.rabbitmq_version
    })
  }

  depends_on = [helm_release.rabbitmq]
}