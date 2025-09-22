# Alertmanager Helm Chart Values - 4C8G 单节点优化配置

# Alertmanager 镜像配置
image:
  tag: "${alertmanager_version}"

# 副本数量（单节点）
replicaCount: 1

# 持久化存储
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
    http: 9093

# 配置文件
config:
  # 使用外部配置文件
  useExistingConfig: false
  configMap: ""

  # 全局配置
  global:
    # SMTP 配置
    %{ if smtp_enabled ~}
    smtp_smarthost: '${smtp_smarthost}'
    smtp_from: '${smtp_from}'
    %{ if smtp_auth_username != "" ~}
    smtp_auth_username: '${smtp_auth_username}'
    smtp_auth_password: '${smtp_auth_password}'
    %{ endif ~}
    smtp_require_tls: ${smtp_require_tls}
    %{ endif ~}

    # 企业微信配置
    %{ if wechat_enabled ~}
    wechat_api_url: 'https://qyapi.weixin.qq.com/cgi-bin/'
    wechat_api_secret: '${wechat_corp_secret}'
    wechat_api_corp_id: '${wechat_corp_id}'
    %{ endif ~}

    # Slack 配置
    %{ if slack_enabled ~}
    slack_api_url: '${slack_api_url}'
    %{ endif ~}

  # 路由配置
  route:
    group_by: [${group_by}]
    group_wait: ${group_wait}
    group_interval: ${group_interval}
    repeat_interval: ${repeat_interval}
    receiver: 'default-receiver'
    routes:
      # 严重告警路由
      - match:
          severity: critical
        receiver: 'critical-receiver'
        group_wait: 5s
        repeat_interval: 30m

      # 警告告警路由
      - match:
          severity: warning
        receiver: 'warning-receiver'
        group_wait: 10s
        repeat_interval: 1h

      # 数据库告警路由
      - match_re:
          job: ^(mongodb|redis|rabbitmq)$
        receiver: 'database-receiver'
        group_wait: 10s
        repeat_interval: 1h

      # Kubernetes 告警路由
      - match_re:
          alertname: ^(PodFailed|PodRestartingTooMuch|NodeDown)$
        receiver: 'kubernetes-receiver'
        group_wait: 5s
        repeat_interval: 30m

  # 接收器配置
  receivers:
    # 默认接收器
    - name: 'default-receiver'
      %{ if smtp_enabled ~}
      email_configs:
        - to: 'admin@example.com'
          subject: '[告警] {{ .GroupLabels.SortedPairs }}'
          body: |
            告警详情:
            {{ range .Alerts }}
            告警名称: {{ .Annotations.summary }}
            告警描述: {{ .Annotations.description }}
            告警级别: {{ .Labels.severity }}
            告警时间: {{ .StartsAt }}
            {{ end }}
      %{ endif ~}

    # 严重告警接收器
    - name: 'critical-receiver'
      %{ if smtp_enabled ~}
      email_configs:
        - to: 'admin@example.com'
          subject: '[紧急告警] {{ .GroupLabels.SortedPairs }}'
          body: |
            🚨 紧急告警 🚨
            {{ range .Alerts }}
            告警名称: {{ .Annotations.summary }}
            告警描述: {{ .Annotations.description }}
            告警级别: {{ .Labels.severity }}
            告警时间: {{ .StartsAt }}
            实例: {{ .Labels.instance }}
            {{ end }}
      %{ endif ~}
      %{ if webhook_enabled ~}
      webhook_configs:
        - url: '${webhook_url}'
          send_resolved: true
      %{ endif ~}
      %{ if slack_enabled ~}
      slack_configs:
        - api_url: '${slack_api_url}'
          channel: '${slack_channel}'
          username: '${slack_username}'
          icon_emoji: '${slack_icon_emoji}'
          title: '🚨 紧急告警'
          text: |
            {{ range .Alerts }}
            告警: {{ .Annotations.summary }}
            描述: {{ .Annotations.description }}
            级别: {{ .Labels.severity }}
            实例: {{ .Labels.instance }}
            {{ end }}
      %{ endif ~}
      %{ if wechat_enabled ~}
      wechat_configs:
        - api_secret: '${wechat_corp_secret}'
          corp_id: '${wechat_corp_id}'
          agent_id: '${wechat_agent_id}'
          to_user: '${wechat_to_user}'
          message: |
            🚨 紧急告警
            {{ range .Alerts }}
            {{ .Annotations.summary }}
            {{ .Annotations.description }}
            级别: {{ .Labels.severity }}
            {{ end }}
      %{ endif ~}

    # 警告接收器
    - name: 'warning-receiver'
      %{ if smtp_enabled ~}
      email_configs:
        - to: 'ops@example.com'
          subject: '[警告] {{ .GroupLabels.SortedPairs }}'
          body: |
            ⚠️ 系统警告
            {{ range .Alerts }}
            告警名称: {{ .Annotations.summary }}
            告警描述: {{ .Annotations.description }}
            告警级别: {{ .Labels.severity }}
            告警时间: {{ .StartsAt }}
            {{ end }}
      %{ endif ~}
      %{ if slack_enabled ~}
      slack_configs:
        - api_url: '${slack_api_url}'
          channel: '${slack_channel}'
          username: '${slack_username}'
          icon_emoji: ':warning:'
          title: '⚠️ 系统警告'
          text: |
            {{ range .Alerts }}
            告警: {{ .Annotations.summary }}
            {{ end }}
      %{ endif ~}

    # 数据库告警接收器
    - name: 'database-receiver'
      %{ if smtp_enabled ~}
      email_configs:
        - to: 'dba@example.com'
          subject: '[数据库告警] {{ .GroupLabels.SortedPairs }}'
          body: |
            🗄️ 数据库告警
            {{ range .Alerts }}
            数据库: {{ .Labels.job }}
            告警: {{ .Annotations.summary }}
            描述: {{ .Annotations.description }}
            {{ end }}
      %{ endif ~}

    # Kubernetes 告警接收器
    - name: 'kubernetes-receiver'
      %{ if smtp_enabled ~}
      email_configs:
        - to: 'k8s-admin@example.com'
          subject: '[Kubernetes告警] {{ .GroupLabels.SortedPairs }}'
          body: |
            ☸️ Kubernetes 告警
            {{ range .Alerts }}
            命名空间: {{ .Labels.namespace }}
            Pod: {{ .Labels.pod }}
            告警: {{ .Annotations.summary }}
            {{ end }}
      %{ endif ~}

  # 抑制规则
  %{ if inhibit_enabled ~}
  inhibit_rules:
    # 节点宕机时抑制该节点上的其他告警
    - source_match:
        alertname: 'NodeDown'
      target_match_re:
        instance: '.*'
      equal: ['instance']

    # 严重告警抑制同类警告告警
    - source_match:
        severity: 'critical'
      target_match:
        severity: 'warning'
      equal: ['alertname', 'instance']

    # Pod 失败时抑制容器相关告警
    - source_match:
        alertname: 'PodFailed'
      target_match_re:
        alertname: 'Container.*'
      equal: ['pod', 'namespace']
  %{ endif ~}

# 数据保留时间
retention: "${retention}"

# 集群模式（单节点关闭）
clustering:
  enabled: false

# 安全上下文
securityContext:
  enabled: true
  runAsUser: 1001
  runAsNonRoot: true
  fsGroup: 1001

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

# Pod 注释
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "9093"
  prometheus.io/path: "/metrics"

# 探活配置
livenessProbe:
  enabled: true
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  successThreshold: 1
  failureThreshold: 6

readinessProbe:
  enabled: true
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  successThreshold: 1
  failureThreshold: 3

# 更新策略
updateStrategy:
  type: RollingUpdate

# 额外配置
extraArgs:
  - --log.level=info
  - --web.external-url=http://alertmanager.monitoring.svc.cluster.local:9093

# 配置重载
configmapReload:
  enabled: true
  resources:
    requests:
      memory: "32Mi"
      cpu: "25m"
    limits:
      memory: "64Mi"
      cpu: "50m"