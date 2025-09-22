# Grafana 可视化模块（4C8G 单节点优化）

# 生成 Grafana 配置文件
resource "local_file" "grafana_values" {
  content = templatefile("${path.module}/templates/values.yaml.tpl", {
    grafana_version     = var.grafana_version
    admin_username      = var.admin_credentials.username
    admin_password      = var.admin_credentials.password
    storage_class       = var.storage.class
    storage_size        = var.storage.size
    memory_request      = var.resources.requests.memory
    cpu_request         = var.resources.requests.cpu
    memory_limit        = var.resources.limits.memory
    cpu_limit           = var.resources.limits.cpu
    prometheus_url      = var.prometheus_url
    plugins             = join(",", var.plugins)
    dashboards_enabled  = var.dashboards.enabled
    network_policy_enabled = var.network_policy.enabled
    external_port       = var.external_port
    smtp_enabled        = var.smtp.enabled
    smtp_host           = var.smtp.host
    smtp_port           = var.smtp.port
    smtp_user           = var.smtp.user
    smtp_password       = var.smtp.password
    smtp_from_name      = var.smtp.from_name
    smtp_from_email     = var.smtp.from_email
  })
  filename = "${path.module}/generated/values.yaml"
}

# 生成数据源配置
resource "local_file" "grafana_datasources" {
  content = templatefile("${path.module}/templates/datasources.yaml.tpl", {
    prometheus_url = var.prometheus_url
  })
  filename = "${path.module}/generated/datasources.yaml"
}

# 生成仪表板配置
resource "local_file" "grafana_dashboards" {
  count = var.dashboards.enabled ? 1 : 0

  content = templatefile("${path.module}/templates/dashboards.yaml.tpl", {
    namespace = var.namespace
  })
  filename = "${path.module}/generated/dashboards.yaml"
}

# 部署 Grafana
resource "helm_release" "grafana" {
  name       = var.release_name
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "grafana"
  version    = var.chart_version
  namespace  = var.namespace

  values = [
    local_file.grafana_values.content
  ]

  depends_on = [
    local_file.grafana_values,
    local_file.grafana_datasources
  ]
}

# NodePort 服务
resource "kubernetes_service" "grafana_nodeport" {
  metadata {
    name      = "${var.release_name}-nodeport"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = "grafana"
      "app.kubernetes.io/instance" = var.release_name
    }
  }

  spec {
    type = "NodePort"

    port {
      name        = "http"
      port        = 3000
      target_port = 3000
      node_port   = var.external_port
    }

    selector = {
      "app.kubernetes.io/name" = "grafana"
      "app.kubernetes.io/instance" = var.release_name
    }
  }

  depends_on = [helm_release.grafana]
}

# 生成连接信息
resource "local_file" "connection_info" {
  content = templatefile("${path.module}/templates/connection-info.txt.tpl", {
    release_name = var.release_name
    namespace    = var.namespace
    grafana_port = var.external_port
    admin_username = var.admin_credentials.username
    admin_password = var.admin_credentials.password
  })
  filename = "${path.module}/generated/connection-info.txt"

  depends_on = [helm_release.grafana]
}