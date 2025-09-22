# FOMO Infrastructure 输出

# ==============================================
# K3s 集群输出
# ==============================================

output "k3s_info" {
  description = "K3s 集群信息"
  value = {
    version         = var.k3s_version
    cluster_cidr    = var.cluster_cidr
    service_cidr    = var.service_cidr
    cluster_dns     = var.cluster_dns
    storage_path    = var.storage_path
    max_pods        = var.max_pods
    memory_threshold = var.memory_threshold
  }
}

output "k3s_kubeconfig" {
  description = "K3s Kubeconfig 文件路径"
  value       = "/etc/rancher/k3s/k3s.yaml"
  sensitive   = true
}

# ==============================================
# 基础服务输出
# ==============================================

output "portainer_info" {
  description = "Portainer 访问信息"
  value = {
    namespace    = module.portainer.namespace
    external_url = module.portainer.portainer_url_external
    internal_url = module.portainer.portainer_url_internal
    connection_info = module.portainer.connection_info_file
  }
}

output "traefik_info" {
  description = "Traefik 访问信息"
  value = {
    namespace    = module.traefik.namespace
    external_url = module.traefik.traefik_url_external
    internal_url = module.traefik.traefik_url_internal
    connection_info = module.traefik.connection_info_file
  }
}

# ==============================================
# 监控系统输出
# ==============================================

output "monitoring_info" {
  description = "监控系统访问信息"
  value = {
    namespace = var.monitoring_namespace
    prometheus = {
      external_url = module.prometheus.prometheus_url_external
      internal_url = module.prometheus.prometheus_url_internal
      connection_info = module.prometheus.connection_info_file
    }
    grafana = {
      external_url = module.grafana.grafana_url_external
      internal_url = module.grafana.grafana_url_internal
      admin_username = var.grafana_admin_username
      connection_info = module.grafana.connection_info_file
    }
    alertmanager = {
      external_url = module.alertmanager.alertmanager_url_external
      internal_url = module.alertmanager.alertmanager_url_internal
      connection_info = module.alertmanager.connection_info_file
    }
  }
  sensitive = true
}

output "monitoring_urls" {
  description = "监控系统访问地址"
  value = {
    prometheus   = "http://NODE_IP:${var.prometheus_external_port}"
    grafana      = "http://NODE_IP:${var.grafana_external_port}"
    alertmanager = "http://NODE_IP:${var.alertmanager_external_port}"
  }
}

# ==============================================
# 数据库服务输出
# ==============================================

output "database_info" {
  description = "数据库服务访问信息"
  value = {
    mongodb = {
      namespace    = module.mongodb.namespace
      external_url = module.mongodb.mongodb_url_external
      internal_url = module.mongodb.mongodb_url_internal
      connection_info = module.mongodb.connection_info_file
    }
    redis = {
      namespace    = module.redis.namespace
      external_url = module.redis.redis_url_external
      internal_url = module.redis.redis_url_internal
      connection_info = module.redis.connection_info_file
    }
    rabbitmq = {
      namespace    = module.rabbitmq.namespace
      external_url = module.rabbitmq.rabbitmq_url_external
      internal_url = module.rabbitmq.rabbitmq_url_internal
      management_url = module.rabbitmq.management_url_external
      connection_info = module.rabbitmq.connection_info_file
    }
  }
  sensitive = true
}

output "database_urls" {
  description = "数据库服务访问地址"
  value = {
    mongodb_port     = var.mongodb_external_port
    redis_port       = var.redis_external_port
    rabbitmq_amqp    = var.rabbitmq_amqp_port
    rabbitmq_mgmt    = var.rabbitmq_management_port
  }
}

# ==============================================
# 资源使用情况
# ==============================================

output "resource_summary" {
  description = "资源使用情况汇总"
  value = {
    total_memory_requests = "${parseint(replace(var.prometheus_memory_request, "Mi", ""), 10) + parseint(replace(var.grafana_memory_request, "Mi", ""), 10) + parseint(replace(var.alertmanager_memory_request, "Mi", ""), 10) + parseint(replace(var.mongodb_memory_request, "Mi", ""), 10) + parseint(replace(var.redis_memory_request, "Mi", ""), 10) + parseint(replace(var.rabbitmq_memory_request, "Mi", ""), 10)}Mi"

    total_cpu_requests = "${parseint(replace(var.prometheus_cpu_request, "m", ""), 10) + parseint(replace(var.grafana_cpu_request, "m", ""), 10) + parseint(replace(var.alertmanager_cpu_request, "m", ""), 10) + parseint(replace(var.mongodb_cpu_request, "m", ""), 10) + parseint(replace(var.redis_cpu_request, "m", ""), 10) + parseint(replace(var.rabbitmq_cpu_request, "m", ""), 10)}m"

    total_storage = "${parseint(replace(var.prometheus_storage_size, "Gi", ""), 10) + parseint(replace(var.grafana_storage_size, "Gi", ""), 10) + parseint(replace(var.alertmanager_storage_size, "Gi", ""), 10) + parseint(replace(var.mongodb_storage_size, "Gi", ""), 10) + parseint(replace(var.redis_storage_size, "Gi", ""), 10) + parseint(replace(var.rabbitmq_storage_size, "Gi", ""), 10)}Gi"

    node_capacity = "4C8G"
    storage_class = var.storage_class
  }
}

# ==============================================
# 网络端口映射
# ==============================================

output "port_mapping" {
  description = "所有服务端口映射"
  value = {
    infrastructure = {
      portainer = var.portainer_external_port
      traefik   = var.traefik_external_port
    }
    monitoring = {
      prometheus   = var.prometheus_external_port
      grafana      = var.grafana_external_port
      alertmanager = var.alertmanager_external_port
    }
    databases = {
      mongodb          = var.mongodb_external_port
      redis           = var.redis_external_port
      rabbitmq_amqp   = var.rabbitmq_amqp_port
      rabbitmq_mgmt   = var.rabbitmq_management_port
    }
  }
}

# ==============================================
# 快速访问命令
# ==============================================

output "quick_access" {
  description = "快速访问命令"
  value = {
    kubeconfig = "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml"

    port_forwards = {
      prometheus = "kubectl port-forward -n ${var.monitoring_namespace} svc/prometheus 9090:9090"
      grafana    = "kubectl port-forward -n ${var.monitoring_namespace} svc/grafana 3000:3000"
      alertmanager = "kubectl port-forward -n ${var.monitoring_namespace} svc/alertmanager 9093:9093"
      mongodb    = "kubectl port-forward -n ${var.mongodb_namespace} svc/mongodb 27017:27017"
      redis      = "kubectl port-forward -n ${var.redis_namespace} svc/redis 6379:6379"
      rabbitmq   = "kubectl port-forward -n ${var.rabbitmq_namespace} svc/rabbitmq 5672:5672 15672:15672"
    }

    logs = {
      prometheus = "kubectl logs -f deployment/prometheus -n ${var.monitoring_namespace}"
      grafana    = "kubectl logs -f deployment/grafana -n ${var.monitoring_namespace}"
      alertmanager = "kubectl logs -f deployment/alertmanager -n ${var.monitoring_namespace}"
      mongodb    = "kubectl logs -f statefulset/mongodb -n ${var.mongodb_namespace}"
      redis      = "kubectl logs -f statefulset/redis -n ${var.redis_namespace}"
      rabbitmq   = "kubectl logs -f statefulset/rabbitmq -n ${var.rabbitmq_namespace}"
    }
  }
}