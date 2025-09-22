# Prometheus 告警规则配置 - 4C8G 单节点环境

groups:
  # 节点级别告警
  - name: node-alerts
    rules:
      # CPU 使用率告警
      - alert: HighCPUUsage
        expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "节点 CPU 使用率过高"
          description: "节点 {{ $labels.instance }} CPU 使用率为 {{ $value }}%，超过 80%"

      # 内存使用率告警
      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "节点内存使用率过高"
          description: "节点 {{ $labels.instance }} 内存使用率为 {{ $value }}%，超过 85%"

      # 磁盘使用率告警
      - alert: HighDiskUsage
        expr: (1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "磁盘使用率过高"
          description: "节点 {{ $labels.instance }} 磁盘 {{ $labels.mountpoint }} 使用率为 {{ $value }}%，超过 85%"

      # 磁盘 I/O 告警
      - alert: HighDiskIOUsage
        expr: rate(node_disk_io_time_seconds_total[5m]) > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "磁盘 I/O 使用率过高"
          description: "节点 {{ $labels.instance }} 磁盘 I/O 使用率过高"

      # 节点不可用告警
      - alert: NodeDown
        expr: up{job="kubernetes-nodes"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "节点不可用"
          description: "节点 {{ $labels.instance }} 已经下线超过 1 分钟"

  # Kubernetes 集群告警
  - name: kubernetes-alerts
    rules:
      # Pod 重启告警
      - alert: PodRestartingTooMuch
        expr: rate(kube_pod_container_status_restarts_total[1h]) > 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Pod 频繁重启"
          description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} 在过去 1 小时内重启了 {{ $value }} 次"

      # Pod 失败状态告警
      - alert: PodFailed
        expr: kube_pod_status_phase{phase="Failed"} == 1
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Pod 处于失败状态"
          description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} 处于 Failed 状态"

      # Pod 待调度告警
      - alert: PodPending
        expr: kube_pod_status_phase{phase="Pending"} == 1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Pod 长时间待调度"
          description: "Pod {{ $labels.namespace }}/{{ $labels.pod }} 已经待调度超过 10 分钟"

      # 容器 CPU 使用率告警
      - alert: ContainerHighCPUUsage
        expr: rate(container_cpu_usage_seconds_total{container!="POD",container!=""}[5m]) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "容器 CPU 使用率过高"
          description: "容器 {{ $labels.namespace }}/{{ $labels.pod }}/{{ $labels.container }} CPU 使用率为 {{ $value }}%"

      # 容器内存使用率告警
      - alert: ContainerHighMemoryUsage
        expr: container_memory_usage_bytes{container!="POD",container!=""} / container_spec_memory_limit_bytes * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "容器内存使用率过高"
          description: "容器 {{ $labels.namespace }}/{{ $labels.pod }}/{{ $labels.container }} 内存使用率为 {{ $value }}%"

  # 数据库相关告警
  - name: database-alerts
    rules:
      # MongoDB 连接数告警
      - alert: MongoDBHighConnections
        expr: mongodb_connections{state="current"} / mongodb_connections{state="available"} > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "MongoDB 连接数过高"
          description: "MongoDB 当前连接数占可用连接数的 {{ $value | humanizePercentage }}"

      # Redis 内存使用告警
      - alert: RedisHighMemoryUsage
        expr: redis_memory_used_bytes / redis_memory_max_bytes > 0.85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Redis 内存使用率过高"
          description: "Redis 内存使用率为 {{ $value | humanizePercentage }}"

      # RabbitMQ 队列消息积压告警
      - alert: RabbitMQQueueTooManyMessages
        expr: rabbitmq_queue_messages > 1000
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "RabbitMQ 队列消息积压"
          description: "队列 {{ $labels.queue }} 有 {{ $value }} 条消息积压"

      # 数据库服务不可用告警
      - alert: DatabaseServiceDown
        expr: up{job=~"mongodb|redis|rabbitmq"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "数据库服务不可用"
          description: "数据库服务 {{ $labels.job }} 已经不可用超过 2 分钟"

  # 存储相关告警
  - name: storage-alerts
    rules:
      # PV 使用率告警
      - alert: PersistentVolumeUsageHigh
        expr: (kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "持久化卷使用率过高"
          description: "PV {{ $labels.persistentvolumeclaim }} 使用率为 {{ $value }}%"

      # PV 不可用告警
      - alert: PersistentVolumeDown
        expr: kube_persistentvolume_status_phase{phase!="Bound"} == 1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "持久化卷不可用"
          description: "PV {{ $labels.persistentvolume }} 状态为 {{ $labels.phase }}"

  # 网络相关告警
  - name: network-alerts
    rules:
      # 网络错误率告警
      - alert: HighNetworkErrorRate
        expr: rate(node_network_receive_errs_total[5m]) + rate(node_network_transmit_errs_total[5m]) > 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "网络错误率过高"
          description: "节点 {{ $labels.instance }} 网卡 {{ $labels.device }} 网络错误率过高"

  # Prometheus 自身告警
  - name: prometheus-alerts
    rules:
      # Prometheus 目标不可达告警
      - alert: PrometheusTargetDown
        expr: up == 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Prometheus 目标不可达"
          description: "目标 {{ $labels.instance }} ({{ $labels.job }}) 已经不可达超过 5 分钟"

      # Prometheus 配置重载失败告警
      - alert: PrometheusConfigReloadFailed
        expr: prometheus_config_last_reload_successful != 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Prometheus 配置重载失败"
          description: "Prometheus 配置重载失败"