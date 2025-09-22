# Redis Helm Chart Values - 单节点优化配置
image:
  tag: "${redis_version}"

# 架构配置（单节点优化）
architecture: ${architecture}

# 认证配置
auth:
  enabled: ${auth_enabled}
  password: "${auth_password}"
  sentinel: false

# 主节点配置
master:
  count: 1
  service:
    type: ClusterIP
    ports:
      redis: 6379
  persistence:
    enabled: true
    storageClass: "${storage_class}"
    size: ${storage_size}
  resources:
    requests:
      memory: "${memory_request}"
      cpu: "${cpu_request}"
    limits:
      memory: "${memory_limit}"
      cpu: "${cpu_limit}"
  podSecurityContext:
    enabled: true
    fsGroup: 1001
  containerSecurityContext:
    enabled: true
    runAsUser: 1001
  livenessProbe:
    enabled: true
    initialDelaySeconds: 20
    periodSeconds: 5
    timeoutSeconds: 5
    successThreshold: 1
    failureThreshold: 5
  readinessProbe:
    enabled: true
    initialDelaySeconds: 20
    periodSeconds: 5
    timeoutSeconds: 1
    successThreshold: 1
    failureThreshold: 5

%{ if replica_enabled ~}
# 副本配置（单节点关闭）
replica:
  replicaCount: ${replica_count}
  service:
    type: ClusterIP
    ports:
      redis: 6379
  persistence:
    enabled: true
    storageClass: "${storage_class}"
    size: ${storage_size}
  resources:
    requests:
      memory: "${memory_request}"
      cpu: "${cpu_request}"
    limits:
      memory: "${memory_limit}"
      cpu: "${cpu_limit}"
  autoscaling:
    enabled: false
%{ else ~}
replica:
  replicaCount: 0
%{ endif ~}

%{ if sentinel_enabled ~}
# 哨兵配置（单节点关闭）
sentinel:
  enabled: ${sentinel_enabled}
%{ else ~}
sentinel:
  enabled: false
%{ endif ~}

# 卷权限
volumePermissions:
  enabled: true
  resources:
    requests:
      memory: "64Mi"
      cpu: "50m"

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

# 通用 Redis 配置（内存优化）
commonConfiguration: |-
  # 启用 AOF 持久化
  appendonly yes
  appendfsync everysec

  # 禁用 RDB 持久化（使用 AOF）
  save ""

  # 内存管理策略
  maxmemory-policy ${max_memory_policy}

  # TCP 设置
  tcp-keepalive 60
  tcp-backlog 511

  # 慢日志
  slowlog-log-slower-than 10000
  slowlog-max-len 128

  # 客户端输出缓冲区限制（单节点优化）
  client-output-buffer-limit normal 0 0 0
  client-output-buffer-limit replica 128mb 32mb 60
  client-output-buffer-limit pubsub 16mb 4mb 60

  # 线程 I/O（单节点优化）
  io-threads 2
  io-threads-do-reads yes

# 服务账户
serviceAccount:
  create: true
  automountServiceAccountToken: true

# 安全上下文
podSecurityContext:
  enabled: true
  fsGroup: 1001

containerSecurityContext:
  enabled: true
  runAsUser: 1001
  runAsNonRoot: true

# 更新策略
updateStrategy:
  type: RollingUpdate

# TLS（单节点环境关闭）
tls:
  enabled: false