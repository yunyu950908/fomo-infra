# MongoDB Helm Chart Values - 单节点优化配置
image:
  tag: "${mongodb_version}"

# 架构配置（单节点优化）
architecture: ${architecture}
%{ if replica_count > 1 ~}
replicaCount: ${replica_count}
%{ endif ~}

# 认证配置
auth:
  enabled: true
  rootUser: ${root_user}
  rootPassword: ${root_password}
  usernames: ${usernames}
  passwords: ${passwords}
  databases: ${databases}

# 持久化存储（单节点优化）
persistence:
  enabled: true
  storageClass: "${storage_class}"
  size: ${storage_size}
  mountPath: /bitnami/mongodb

# 资源配置（2C4G 优化）
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
  port: 27017
  nodePort: null

%{ if arbiter_enabled ~}
# 仲裁者配置（standalone 模式下禁用）
arbiter:
  enabled: ${arbiter_enabled}
  resources:
    requests:
      memory: "${arbiter_memory_request}"
      cpu: "${arbiter_cpu_request}"
    limits:
      memory: "${arbiter_memory_limit}"
      cpu: "${arbiter_cpu_limit}"
%{ else ~}
arbiter:
  enabled: false
%{ endif ~}

# 指标收集（单节点优化关闭）
metrics:
  enabled: ${metrics_enabled}
%{ if metrics_enabled ~}
  resources:
    requests:
      memory: "${metrics_memory_request}"
      cpu: "${metrics_cpu_request}"
    limits:
      memory: "${metrics_memory_limit}"
      cpu: "${metrics_cpu_limit}"
%{ endif ~}

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

containerSecurityContext:
  enabled: true
  runAsUser: 1001

# 存活和就绪探针
livenessProbe:
  enabled: true
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  successThreshold: 1
  failureThreshold: 5

readinessProbe:
  enabled: true
  initialDelaySeconds: 5
  periodSeconds: 10
  timeoutSeconds: 5
  successThreshold: 1
  failureThreshold: 5

# 备份配置
backup:
  enabled: ${backup_enabled}

# 网络策略
networkPolicy:
  enabled: ${network_policy_enabled}

# Pod 中断预算
pdb:
  create: ${pdb_enabled}
%{ if pdb_enabled ~}
  minAvailable: ${pdb_min_available}
%{ endif ~}

# 额外环境变量（内存优化）
extraEnvVars:
  - name: MONGODB_EXTRA_FLAGS
    value: "--wiredTigerCacheSizeGB=0.5"