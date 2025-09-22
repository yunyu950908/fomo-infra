# FOMO Infrastructure 输出定义
# 所有服务的访问信息汇总

# K3s 集群信息
output "k3s_info" {
  description = "K3s 集群信息"
  value = {
    status     = "K3s cluster deployed"
    node_ip    = module.k3s.node_ip
    kubeconfig = "~/.kube/config"
  }
}

# 临时注释其他模块的输出，等模块启用后再打开
# output "management_urls" {
#   description = "管理界面访问地址"
#   value = {
#     portainer = module.portainer.url
#     traefik   = module.traefik.dashboard_url
#   }
# }

# output "monitoring_info" {
#   description = "监控系统详细信息"
#   value = {
#     prometheus = {
#       namespace    = module.prometheus.namespace
#       external_url = module.prometheus.prometheus_url_external
#       internal_url = module.prometheus.prometheus_url_internal
#       config       = module.prometheus.config_file
#     }
#     grafana = {
#       namespace    = module.grafana.namespace
#       external_url = module.grafana.grafana_url_external
#       internal_url = module.grafana.grafana_url_internal
#       credentials  = module.grafana.admin_credentials_file
#       dashboards   = module.grafana.dashboard_urls
#     }
#     alertmanager = {
#       namespace    = module.alertmanager.namespace
#       external_url = module.alertmanager.alertmanager_url_external
#       internal_url = module.alertmanager.alertmanager_url_internal
#       config       = module.alertmanager.config_file
#     }
#   }
#   sensitive = true
# }

# output "monitoring_urls" {
#   description = "监控系统访问地址"
#   value = {
#     prometheus   = module.prometheus.prometheus_url_external
#     grafana      = module.grafana.grafana_url_external
#     alertmanager = module.alertmanager.alertmanager_url_external
#   }
# }

# output "monitoring_credentials" {
#   description = "监控系统访问凭据"
#   value = {
#     grafana = {
#       username = module.grafana.admin_username
#       password = module.grafana.admin_password
#     }
#   }
#   sensitive = true
# }

# output "database_info" {
#   description = "数据库服务详细信息"
#   value = {
#     mongodb = {
#       namespace    = module.mongodb.namespace
#       external_url = module.mongodb.mongodb_url_external
#       internal_url = module.mongodb.mongodb_url_internal
#       connection_info = module.mongodb.connection_info_file
#     }
#     redis = {
#       namespace    = module.redis.namespace
#       external_url = module.redis.redis_url_external
#       internal_url = module.redis.redis_url_internal
#       connection_info = module.redis.connection_info_file
#     }
#     rabbitmq = {
#       namespace    = module.rabbitmq.namespace
#       external_url = module.rabbitmq.rabbitmq_url_external
#       internal_url = module.rabbitmq.rabbitmq_url_internal
#       management_url = module.rabbitmq.management_url_external
#       connection_info = module.rabbitmq.connection_info_file
#     }
#   }
#   sensitive = true
# }

# output "database_urls" {
#   description = "数据库服务访问地址"
#   value = {
#     mongodb  = module.mongodb.mongodb_url_external
#     redis    = module.redis.redis_url_external
#     rabbitmq = module.rabbitmq.management_url_external
#   }
# }

# output "database_credentials" {
#   description = "数据库访问凭据"
#   value = {
#     mongodb = {
#       root_user     = module.mongodb.root_user
#       root_password = module.mongodb.root_password
#     }
#     redis = {
#       password = module.redis.auth_password
#     }
#     rabbitmq = {
#       username = module.rabbitmq.admin_username
#       password = module.rabbitmq.admin_password
#     }
#   }
#   sensitive = true
# }

# output "storage_info" {
#   description = "存储配置信息"
#   value = {
#     storage_class = var.storage_class
#     storage_path  = var.storage_path
#   }
# }

# output "namespace" {
#   description = "服务部署命名空间"
#   value       = "infra"
# }

output "quick_start" {
  description = "快速开始指南"
  value = <<-EOT
    ====================================
    K3s 部署完成！
    ====================================

    验证集群状态:
      kubectl get nodes
      kubectl get pods -A

    查看服务:
      kubectl get svc -n kube-system

    如需部署其他组件，请取消 main.tf 中相应模块的注释。
  EOT
}