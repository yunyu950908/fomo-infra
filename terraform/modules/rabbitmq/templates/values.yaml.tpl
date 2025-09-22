# RabbitMQ Helm Chart Values - 单节点优化配置
image:
  tag: "${rabbitmq_version}"

# 认证配置
auth:
  username: ${username}
  password: ${password}
  erlangCookie: ${erlang_cookie}
  securePassword: true

# 集群配置（单节点关闭）
clustering:
  enabled: ${clustering_enabled}

# 副本数量（单节点优化）
replicaCount: ${replica_count}

# 持久化存储（单节点优化）
persistence:
  enabled: true
  storageClass: "${storage_class}"
  size: ${storage_size}

# 服务配置
service:
  type: ClusterIP
  ports:
    amqp: 5672
    epmd: 4369
    dist: 25672
    manager: 15672
    metrics: 9419

# RabbitMQ 配置
rabbitmq:
  # 插件配置（单节点优化）
  plugins: "${plugins}"

  # 额外配置（内存优化）
  extraConfiguration: |-
    # 内存高水位阈值（单节点优化）
    vm_memory_high_watermark.relative = ${memory_high_watermark}

    # 磁盘空间限制
    disk_free_limit.absolute = 1GB

    # 管理插件配置
    management.tcp.port = 15672

    # 性能调优（单节点优化）
    channel_max = 1024
    heartbeat = 30

    # 消息 TTL 和队列限制
    consumer_timeout = 3600000

  # 负载定义
  loadDefinition:
    enabled: false

# 资源配置（2C4G 优化）
resources:
  requests:
    memory: "${memory_request}"
    cpu: "${cpu_request}"
  limits:
    memory: "${memory_limit}"
    cpu: "${cpu_limit}"

# 卷权限
volumePermissions:
  enabled: true
  resources:
    requests:
      memory: "64Mi"
      cpu: "50m"

# 安全上下文
podSecurityContext:
  enabled: true
  fsGroup: 1001
  runAsUser: 1001

containerSecurityContext:
  enabled: true
  runAsUser: 1001
  runAsNonRoot: true

# 存活和就绪探针（单节点优化）
livenessProbe:
  enabled: true
  initialDelaySeconds: 60
  periodSeconds: 30
  timeoutSeconds: 20
  successThreshold: 1
  failureThreshold: 3

readinessProbe:
  enabled: true
  initialDelaySeconds: 10
  periodSeconds: 30
  timeoutSeconds: 20
  successThreshold: 1
  failureThreshold: 3

# 指标收集（单节点关闭）
metrics:
  enabled: ${metrics_enabled}

# 网络策略
networkPolicy:
  enabled: ${network_policy_enabled}
  allowExternal: true

# Pod 中断预算（单节点关闭）
pdb:
  create: ${pdb_enabled}
%{ if pdb_enabled ~}
  minAvailable: ${pdb_min_available}
%{ endif ~}

# 额外环境变量
extraEnvVars:
  - name: RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS
    value: "-rabbit log_levels [{connection,error}]"
  - name: RABBITMQ_FORCE_BOOT
    value: "no"

# Ingress 配置
ingress:
  enabled: false

# 反亲和性（单节点关闭）
affinity: {}

# 状态集配置
statefulSetLabels: {}
statefulSetAnnotations: {}

# 更新策略
updateStrategy:
  type: RollingUpdate

# 额外密钥
extraSecrets: {}