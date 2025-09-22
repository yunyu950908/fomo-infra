# Alertmanager 告警模块（4C8G 单节点优化）

# 生成 Alertmanager 配置文件
resource "local_file" "alertmanager_values" {
  content = templatefile("${path.module}/templates/values.yaml.tpl", {
    alertmanager_version = var.alertmanager_version
    storage_class       = var.storage.class
    storage_size        = var.storage.size
    memory_request      = var.resources.requests.memory
    cpu_request         = var.resources.requests.cpu
    memory_limit        = var.resources.limits.memory
    cpu_limit           = var.resources.limits.cpu
    retention           = var.retention
    network_policy_enabled = var.network_policy.enabled
    external_port       = var.external_port

    # 通知配置
    smtp_enabled        = var.smtp.enabled
    smtp_smarthost      = var.smtp.smarthost
    smtp_from           = var.smtp.from
    smtp_auth_username  = var.smtp.auth_username
    smtp_auth_password  = var.smtp.auth_password
    smtp_require_tls    = var.smtp.require_tls

    webhook_enabled     = var.webhook.enabled
    webhook_url         = var.webhook.url

    slack_enabled       = var.slack.enabled
    slack_api_url       = var.slack.api_url
    slack_channel       = var.slack.channel
    slack_username      = var.slack.username
    slack_icon_emoji    = var.slack.icon_emoji

    wechat_enabled      = var.wechat.enabled
    wechat_corp_id      = var.wechat.corp_id
    wechat_corp_secret  = var.wechat.corp_secret
    wechat_agent_id     = var.wechat.agent_id
    wechat_to_user      = var.wechat.to_user
    wechat_to_party     = var.wechat.to_party
    wechat_to_tag       = var.wechat.to_tag

    # 路由配置
    group_by           = join(", ", [for item in var.routes.group_by : "'${item}'"])
    group_wait         = var.routes.group_wait
    group_interval     = var.routes.group_interval
    repeat_interval    = var.routes.repeat_interval

    # 抑制规则
    inhibit_enabled    = var.inhibit_rules.enabled
  })
  filename = "${path.module}/generated/values.yaml"
}

# 生成 Alertmanager 告警配置
resource "local_file" "alertmanager_config" {
  content = templatefile("${path.module}/templates/alertmanager.yml.tpl", {
    # 通知配置
    smtp_enabled        = var.smtp.enabled
    smtp_smarthost      = var.smtp.smarthost
    smtp_from           = var.smtp.from
    smtp_auth_username  = var.smtp.auth_username
    smtp_auth_password  = var.smtp.auth_password
    smtp_require_tls    = var.smtp.require_tls

    webhook_enabled     = var.webhook.enabled
    webhook_url         = var.webhook.url

    slack_enabled       = var.slack.enabled
    slack_api_url       = var.slack.api_url
    slack_channel       = var.slack.channel
    slack_username      = var.slack.username
    slack_icon_emoji    = var.slack.icon_emoji

    wechat_enabled      = var.wechat.enabled
    wechat_corp_id      = var.wechat.corp_id
    wechat_corp_secret  = var.wechat.corp_secret
    wechat_agent_id     = var.wechat.agent_id
    wechat_to_user      = var.wechat.to_user
    wechat_to_party     = var.wechat.to_party
    wechat_to_tag       = var.wechat.to_tag

    # 路由配置
    group_by           = var.routes.group_by
    group_wait         = var.routes.group_wait
    group_interval     = var.routes.group_interval
    repeat_interval    = var.routes.repeat_interval

    # 抑制规则
    inhibit_enabled    = var.inhibit_rules.enabled
  })
  filename = "${path.module}/generated/alertmanager.yml"
}

# 部署 Alertmanager
resource "helm_release" "alertmanager" {
  name       = var.release_name
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "alertmanager"
  version    = var.chart_version
  namespace  = var.namespace

  values = [
    local_file.alertmanager_values.content
  ]

  depends_on = [
    local_file.alertmanager_values,
    local_file.alertmanager_config
  ]
}

# NodePort 服务
resource "kubernetes_service" "alertmanager_nodeport" {
  metadata {
    name      = "${var.release_name}-nodeport"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = "alertmanager"
      "app.kubernetes.io/instance" = var.release_name
    }
  }

  spec {
    type = "NodePort"

    port {
      name        = "http"
      port        = 9093
      target_port = 9093
      node_port   = var.external_port
    }

    selector = {
      "app.kubernetes.io/name" = "alertmanager"
      "app.kubernetes.io/instance" = var.release_name
    }
  }

  depends_on = [helm_release.alertmanager]
}

# 生成连接信息
resource "local_file" "connection_info" {
  content = templatefile("${path.module}/templates/connection-info.txt.tpl", {
    release_name = var.release_name
    namespace    = var.namespace
    alertmanager_port = var.external_port
  })
  filename = "${path.module}/generated/connection-info.txt"

  depends_on = [helm_release.alertmanager]
}