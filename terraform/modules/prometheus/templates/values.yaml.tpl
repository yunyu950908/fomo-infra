# Prometheus Helm Chart Values - 4C8G 单节点优化配置

# Prometheus 配置
prometheus:
  image:
    tag: "${prometheus_version}"

  # 存储配置
  persistence:
    enabled: true
    storageClass: "${storage_class}"
    size: ${storage_size}

  # 资源配置
  resources:
    requests:
      memory: "${memory_request}"
      cpu: "${cpu_request}"
    limits:
      memory: "${memory_limit}"
      cpu: "${cpu_limit}"

  # 服务配置
  service:
    type: ClusterIP
    ports:
      http: 9090

  # 配置文件
  configuration: |
    global:
      scrape_interval: ${scrape_interval}
      evaluation_interval: ${evaluation_interval}
      external_labels:
        cluster: 'fomo-k3s'
        replica: 'prometheus'

    # 告警管理器配置
    alerting:
      alertmanagers:
        - static_configs:
            - targets:
              - "${alertmanager_url}"

    # 规则文件
    rule_files:
      - "/opt/bitnami/prometheus/conf/alert-rules.yaml"

    # 抓取配置
    scrape_configs:
      # Prometheus 自身监控
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']
        scrape_interval: 30s
        metrics_path: /metrics

      # Kubernetes API Server
      - job_name: 'kubernetes-apiservers'
        kubernetes_sd_configs:
          - role: endpoints
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
          - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
            action: keep
            regex: default;kubernetes;https

      # Kubernetes Nodes
      - job_name: 'kubernetes-nodes'
        kubernetes_sd_configs:
          - role: node
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
          - action: labelmap
            regex: __meta_kubernetes_node_label_(.+)
          - target_label: __address__
            replacement: kubernetes.default.svc:443
          - source_labels: [__meta_kubernetes_node_name]
            regex: (.+)
            target_label: __metrics_path__
            replacement: /api/v1/nodes/$1/proxy/metrics

      # Kubernetes Pods
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
            action: replace
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: $1:$2
            target_label: __address__
          - action: labelmap
            regex: __meta_kubernetes_pod_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            action: replace
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_pod_name]
            action: replace
            target_label: kubernetes_pod_name

      # MongoDB 监控（如果启用了 metrics）
      - job_name: 'mongodb'
        static_configs:
          - targets: ['mongodb-metrics.infra.svc.cluster.local:9216']
        scrape_interval: 30s

      # Redis 监控（如果启用了 metrics）
      - job_name: 'redis'
        static_configs:
          - targets: ['redis-metrics.infra.svc.cluster.local:9121']
        scrape_interval: 30s

      # RabbitMQ 监控（如果启用了 metrics）
      - job_name: 'rabbitmq'
        static_configs:
          - targets: ['rabbitmq-metrics.infra.svc.cluster.local:9419']
        scrape_interval: 30s

  # 外部标签
  externalLabels:
    cluster: 'fomo-k3s'
    replica: 'prometheus'

  # 数据保留
  retention: "${retention}"

  # 安全上下文
  securityContext:
    enabled: true
    runAsUser: 1001
    runAsNonRoot: true
    fsGroup: 1001

# Node Exporter（监控节点指标）
nodeExporter:
  enabled: true
  resources:
    requests:
      memory: "64Mi"
      cpu: "50m"
    limits:
      memory: "128Mi"
      cpu: "100m"

# kube-state-metrics（监控 Kubernetes 对象）
kubeStateMetrics:
  enabled: true
  resources:
    requests:
      memory: "64Mi"
      cpu: "50m"
    limits:
      memory: "128Mi"
      cpu: "100m"

# Alertmanager（使用独立模块部署）
alertmanager:
  enabled: false

# 服务账户
serviceAccount:
  create: true
  automountServiceAccountToken: true

# RBAC
rbac:
  create: true

# 网络策略
networkPolicy:
  enabled: ${network_policy_enabled}

# ServiceMonitor（用于自动发现）
serviceMonitor:
  enabled: ${service_monitor_enabled}
  interval: 30s
  scrapeTimeout: 30s

# 禁用不需要的组件以节省资源
pushgateway:
  enabled: false

server:
  # 禁用高可用配置
  replicaCount: 1

  # 持久化配置
  persistentVolume:
    enabled: true
    storageClass: "${storage_class}"
    size: ${storage_size}

  # 资源限制
  resources:
    requests:
      memory: "${memory_request}"
      cpu: "${cpu_request}"
    limits:
      memory: "${memory_limit}"
      cpu: "${cpu_limit}"

# 配置文件挂载
configmapReload:
  prometheus:
    enabled: true
    resources:
      requests:
        memory: "32Mi"
        cpu: "25m"
      limits:
        memory: "64Mi"
        cpu: "50m"