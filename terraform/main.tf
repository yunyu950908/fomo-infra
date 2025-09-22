# FOMO Infrastructure 主配置 - 4C8G 单节点部署

terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# K3s 集群部署
module "k3s" {
  source = "./modules/k3s"

  k3s_version        = var.k3s_version
  cluster_cidr       = var.cluster_cidr
  service_cidr       = var.service_cidr
  cluster_dns        = var.cluster_dns
  disabled_addons    = var.disabled_addons
  flannel_backend    = var.flannel_backend
  storage_path       = var.storage_path
  max_pods           = var.max_pods
  memory_threshold   = var.memory_threshold
  disk_threshold     = var.disk_threshold
  inode_threshold    = var.inode_threshold
  imagefs_threshold  = var.imagefs_threshold
}

# 基础服务部署
module "portainer" {
  source = "./modules/portainer"

  namespace     = var.portainer_namespace
  release_name  = var.portainer_release_name
  chart_version = var.portainer_chart_version
  external_port = var.portainer_external_port

  depends_on = [module.k3s]
}

module "traefik" {
  source = "./modules/traefik"

  namespace     = var.traefik_namespace
  release_name  = var.traefik_release_name
  chart_version = var.traefik_chart_version
  external_port = var.traefik_external_port

  depends_on = [module.k3s]
}

# 监控系统部署
module "prometheus" {
  source = "./modules/prometheus"

  namespace         = var.monitoring_namespace
  release_name      = "prometheus"
  chart_version     = var.prometheus_chart_version
  prometheus_version = var.prometheus_version
  external_port     = var.prometheus_external_port

  storage = {
    class = var.storage_class
    size  = var.prometheus_storage_size
  }

  resources = {
    requests = {
      memory = var.prometheus_memory_request
      cpu    = var.prometheus_cpu_request
    }
    limits = {
      memory = var.prometheus_memory_limit
      cpu    = var.prometheus_cpu_limit
    }
  }

  retention              = var.prometheus_retention
  scrape_interval        = var.prometheus_scrape_interval
  evaluation_interval    = var.prometheus_evaluation_interval
  alertmanager_url       = "http://alertmanager.infra.svc.cluster.local:9093"

  depends_on = [module.k3s]
}

module "grafana" {
  source = "./modules/grafana"

  namespace     = var.monitoring_namespace
  release_name  = "grafana"
  chart_version = var.grafana_chart_version
  grafana_version = var.grafana_version
  external_port = var.grafana_external_port

  admin_credentials = {
    username = var.grafana_admin_username
    password = var.grafana_admin_password
  }

  storage = {
    class = var.storage_class
    size  = var.grafana_storage_size
  }

  resources = {
    requests = {
      memory = var.grafana_memory_request
      cpu    = var.grafana_cpu_request
    }
    limits = {
      memory = var.grafana_memory_limit
      cpu    = var.grafana_cpu_limit
    }
  }

  prometheus_url = "http://prometheus.infra.svc.cluster.local:9090"

  plugins = var.grafana_plugins
  dashboards = {
    enabled = var.grafana_dashboards_enabled
  }

  smtp = {
    enabled    = var.grafana_smtp_enabled
    host       = var.grafana_smtp_host
    port       = var.grafana_smtp_port
    user       = var.grafana_smtp_user
    password   = var.grafana_smtp_password
    from_name  = var.grafana_smtp_from_name
    from_email = var.grafana_smtp_from_email
  }

  depends_on = [module.k3s, module.prometheus]
}

module "alertmanager" {
  source = "./modules/alertmanager"

  namespace         = var.monitoring_namespace
  release_name      = "alertmanager"
  chart_version     = var.alertmanager_chart_version
  alertmanager_version = var.alertmanager_version
  external_port     = var.alertmanager_external_port

  storage = {
    class = var.storage_class
    size  = var.alertmanager_storage_size
  }

  resources = {
    requests = {
      memory = var.alertmanager_memory_request
      cpu    = var.alertmanager_cpu_request
    }
    limits = {
      memory = var.alertmanager_memory_limit
      cpu    = var.alertmanager_cpu_limit
    }
  }

  retention = var.alertmanager_retention

  smtp = {
    enabled      = var.alertmanager_smtp_enabled
    smarthost    = var.alertmanager_smtp_smarthost
    from         = var.alertmanager_smtp_from
    auth_username = var.alertmanager_smtp_username
    auth_password = var.alertmanager_smtp_password
    require_tls  = var.alertmanager_smtp_require_tls
  }

  webhook = {
    enabled = var.alertmanager_webhook_enabled
    url     = var.alertmanager_webhook_url
  }

  slack = {
    enabled    = var.alertmanager_slack_enabled
    api_url    = var.alertmanager_slack_api_url
    channel    = var.alertmanager_slack_channel
    username   = var.alertmanager_slack_username
    icon_emoji = var.alertmanager_slack_icon_emoji
  }

  wechat = {
    enabled   = var.alertmanager_wechat_enabled
    corp_id   = var.alertmanager_wechat_corp_id
    corp_secret = var.alertmanager_wechat_corp_secret
    agent_id  = var.alertmanager_wechat_agent_id
    to_user   = var.alertmanager_wechat_to_user
    to_party  = var.alertmanager_wechat_to_party
    to_tag    = var.alertmanager_wechat_to_tag
  }

  routes = {
    group_by       = var.alertmanager_group_by
    group_wait     = var.alertmanager_group_wait
    group_interval = var.alertmanager_group_interval
    repeat_interval = var.alertmanager_repeat_interval
  }

  inhibit_rules = {
    enabled = var.alertmanager_inhibit_enabled
  }

  depends_on = [module.k3s, module.prometheus]
}

# 数据库服务部署
module "mongodb" {
  source = "./modules/mongodb"

  namespace     = var.mongodb_namespace
  release_name  = var.mongodb_release_name
  chart_version = var.mongodb_chart_version
  mongodb_version = var.mongodb_version
  architecture  = var.mongodb_architecture
  replica_count = var.mongodb_replica_count
  external_port = var.mongodb_external_port

  auth = {
    root_user     = var.mongodb_root_user
    root_password = var.mongodb_root_password
    usernames     = var.mongodb_usernames
    passwords     = var.mongodb_passwords
    databases     = var.mongodb_databases
  }

  storage = {
    class = var.storage_class
    size  = var.mongodb_storage_size
  }

  resources = {
    requests = {
      memory = var.mongodb_memory_request
      cpu    = var.mongodb_cpu_request
    }
    limits = {
      memory = var.mongodb_memory_limit
      cpu    = var.mongodb_cpu_limit
    }
  }

  depends_on = [module.k3s]
}

module "redis" {
  source = "./modules/redis"

  namespace     = var.redis_namespace
  release_name  = var.redis_release_name
  chart_version = var.redis_chart_version
  redis_version = var.redis_version
  architecture  = var.redis_architecture

  auth = {
    enabled  = var.redis_auth_enabled
    password = var.redis_auth_password
  }

  external_ports = {
    redis = var.redis_external_port
  }

  storage = {
    class = var.storage_class
    size  = var.redis_storage_size
  }

  resources = {
    requests = {
      memory = var.redis_memory_request
      cpu    = var.redis_cpu_request
    }
    limits = {
      memory = var.redis_memory_limit
      cpu    = var.redis_cpu_limit
    }
  }

  replica = {
    enabled = var.redis_replica_enabled
    count   = var.redis_replica_count
  }

  sentinel = {
    enabled = var.redis_sentinel_enabled
  }

  max_memory_policy = var.redis_max_memory_policy

  depends_on = [module.k3s]
}

module "rabbitmq" {
  source = "./modules/rabbitmq"

  namespace     = var.rabbitmq_namespace
  release_name  = var.rabbitmq_release_name
  chart_version = var.rabbitmq_chart_version
  rabbitmq_version = var.rabbitmq_version
  replica_count = var.rabbitmq_replica_count

  auth = {
    username      = var.rabbitmq_username
    password      = var.rabbitmq_password
    erlang_cookie = var.rabbitmq_erlang_cookie
  }

  clustering = {
    enabled = var.rabbitmq_clustering_enabled
  }

  external_ports = {
    amqp       = var.rabbitmq_amqp_port
    management = var.rabbitmq_management_port
  }

  default_vhost = var.rabbitmq_default_vhost
  plugins       = var.rabbitmq_plugins

  storage = {
    class = var.storage_class
    size  = var.rabbitmq_storage_size
  }

  resources = {
    requests = {
      memory = var.rabbitmq_memory_request
      cpu    = var.rabbitmq_cpu_request
    }
    limits = {
      memory = var.rabbitmq_memory_limit
      cpu    = var.rabbitmq_cpu_limit
    }
  }

  memory_high_watermark = var.rabbitmq_memory_high_watermark

  depends_on = [module.k3s]
}