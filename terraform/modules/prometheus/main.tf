# Prometheus 监控模块（4C8G 单节点优化）

# 创建命名空间
resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# 生成 Prometheus 配置文件
resource "local_file" "prometheus_values" {
  content = templatefile("${path.module}/templates/values.yaml.tpl", {
    prometheus_version    = var.prometheus_version
    storage_class        = var.storage.class
    storage_size         = var.storage.size
    memory_request       = var.resources.requests.memory
    cpu_request          = var.resources.requests.cpu
    memory_limit         = var.resources.limits.memory
    cpu_limit            = var.resources.limits.cpu
    retention            = var.retention
    scrape_interval      = var.scrape_interval
    evaluation_interval  = var.evaluation_interval
    alertmanager_url     = var.alertmanager_url
    network_policy_enabled = var.network_policy.enabled
    service_monitor_enabled = var.service_monitor.enabled
    external_port        = var.external_port
  })
  filename = "${path.module}/generated/values.yaml"
}

# 生成告警规则
resource "local_file" "prometheus_rules" {
  content = templatefile("${path.module}/templates/alert-rules.yaml.tpl", {
    namespace = var.namespace
  })
  filename = "${path.module}/generated/alert-rules.yaml"
}

# 部署 Prometheus
resource "helm_release" "prometheus" {
  name       = var.release_name
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "prometheus"
  version    = var.chart_version
  namespace  = var.namespace

  values = [
    local_file.prometheus_values.content
  ]

  depends_on = [
    kubernetes_namespace.prometheus,
    local_file.prometheus_values,
    local_file.prometheus_rules
  ]
}

# NodePort 服务
resource "kubernetes_service" "prometheus_nodeport" {
  metadata {
    name      = "${var.release_name}-nodeport"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = "prometheus"
      "app.kubernetes.io/instance" = var.release_name
    }
  }

  spec {
    type = "NodePort"

    port {
      name        = "http"
      port        = 9090
      target_port = 9090
      node_port   = var.external_port
    }

    selector = {
      "app.kubernetes.io/name" = "prometheus"
      "app.kubernetes.io/instance" = var.release_name
      "app.kubernetes.io/component" = "server"
    }
  }

  depends_on = [helm_release.prometheus]
}

# 生成连接信息
resource "local_file" "connection_info" {
  content = templatefile("${path.module}/templates/connection-info.txt.tpl", {
    release_name = var.release_name
    namespace    = var.namespace
    prometheus_port = var.external_port
  })
  filename = "${path.module}/generated/connection-info.txt"

  depends_on = [helm_release.prometheus]
}