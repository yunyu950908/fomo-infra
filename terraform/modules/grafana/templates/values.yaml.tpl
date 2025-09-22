# Grafana Helm Chart Values - 4C8G 单节点优化配置

# Grafana 镜像配置
image:
  tag: "${grafana_version}"

# 管理员配置
admin:
  user: "${admin_username}"
  password: "${admin_password}"

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
    grafana: 3000

# 副本数量（单节点）
replicaCount: 1

# 配置文件
config:
  # 基础配置
  useGrafanaIniFile: true
  grafanaIniConfigMap: "${release_name}-config"
  grafanaIniSecret: ""

# 数据源配置
datasources:
  secretName: "${release_name}-datasources"

# 仪表板配置
%{ if dashboards_enabled ~}
dashboards:
  configMapName: "${release_name}-dashboards"
%{ endif ~}

# 插件配置
plugins: "${plugins}"

# 环境变量
envVars:
  GF_INSTALL_PLUGINS: "${plugins}"
  GF_PATHS_PLUGINS: "/opt/bitnami/grafana/plugins"
  GF_PATHS_PROVISIONING: "/opt/bitnami/grafana/conf/provisioning"

# SMTP 配置
%{ if smtp_enabled ~}
smtp:
  enabled: ${smtp_enabled}
  host: "${smtp_host}"
  port: ${smtp_port}
  user: "${smtp_user}"
  password: "${smtp_password}"
  fromName: "${smtp_from_name}"
  fromAddress: "${smtp_from_email}"
%{ endif ~}

# 安全配置
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

# 初始化配置
initContainers: []

# 额外的配置映射
configmaps:
  # Grafana 主配置
  config:
    grafana.ini: |
      [analytics]
      check_for_updates = false

      [grafana_net]
      url = https://grafana.net

      [log]
      mode = console
      level = info

      [paths]
      data = /opt/bitnami/grafana/data
      logs = /opt/bitnami/grafana/logs
      plugins = /opt/bitnami/grafana/plugins
      provisioning = /opt/bitnami/grafana/conf/provisioning

      [server]
      root_url = http://localhost:3000/
      serve_from_sub_path = false

      [database]
      type = sqlite3
      path = grafana.db

      [session]
      provider = file

      [dataproxy]
      logging = false

      [snapshots]
      external_enabled = true
      external_snapshot_url = https://snapshots-origin.raintank.io
      external_snapshot_name = Publish to snapshot.raintank.io

      [dashboards]
      default_home_dashboard_path = /opt/bitnami/grafana/conf/provisioning/dashboards/home.json

      [alerting]
      enabled = true
      execute_alerts = true

      [metrics]
      enabled = true
      interval_seconds = 10

      [explore]
      enabled = true

      [help]
      enabled = true

      %{ if smtp_enabled ~}
      [smtp]
      enabled = ${smtp_enabled}
      host = ${smtp_host}:${smtp_port}
      user = ${smtp_user}
      password = ${smtp_password}
      from_address = ${smtp_from_email}
      from_name = ${smtp_from_name}
      skip_verify = false
      %{ endif ~}

      [users]
      allow_sign_up = false
      allow_org_create = false
      auto_assign_org = true
      auto_assign_org_id = 1
      auto_assign_org_role = Viewer
      verify_email_enabled = false
      login_hint = email or username
      default_theme = dark

  # 数据源配置
  datasources:
    datasources.yaml: |
      apiVersion: 1
      datasources:
        - name: Prometheus
          type: prometheus
          access: proxy
          url: ${prometheus_url}
          isDefault: true
          editable: true
          jsonData:
            httpMethod: POST
            queryTimeout: 30s
            timeInterval: 30s

%{ if dashboards_enabled ~}
  # 仪表板配置
  dashboards:
    dashboards.yaml: |
      apiVersion: 1
      providers:
        - name: 'default'
          orgId: 1
          folder: ''
          folderUid: ''
          type: file
          disableDeletion: false
          updateIntervalSeconds: 30
          allowUiUpdates: true
          options:
            path: /opt/bitnami/grafana/dashboards
        - name: 'kubernetes'
          orgId: 1
          folder: 'Kubernetes'
          folderUid: 'kubernetes'
          type: file
          disableDeletion: false
          updateIntervalSeconds: 30
          allowUiUpdates: true
          options:
            path: /opt/bitnami/grafana/dashboards/kubernetes
        - name: 'database'
          orgId: 1
          folder: 'Database'
          folderUid: 'database'
          type: file
          disableDeletion: false
          updateIntervalSeconds: 30
          allowUiUpdates: true
          options:
            path: /opt/bitnami/grafana/dashboards/database
%{ endif ~}

# 配置映射挂载
configMaps:
  - name: "${release_name}-config"
    mountPath: "/opt/bitnami/grafana/conf"
    subPath: "grafana.ini"
    readOnly: true
  - name: "${release_name}-datasources"
    mountPath: "/opt/bitnami/grafana/conf/provisioning/datasources"
    readOnly: true
%{ if dashboards_enabled ~}
  - name: "${release_name}-dashboards"
    mountPath: "/opt/bitnami/grafana/conf/provisioning/dashboards"
    readOnly: true
%{ endif ~}

# 额外的容器配置
extraContainers: []

# 额外的初始化容器
extraInitContainers: []

# 额外的卷
extraVolumes: []

# 额外的卷挂载
extraVolumeMounts: []

# Pod 注释
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "3000"
  prometheus.io/path: "/metrics"

# 探活配置
livenessProbe:
  enabled: true
  initialDelaySeconds: 120
  periodSeconds: 10
  timeoutSeconds: 5
  successThreshold: 1
  failureThreshold: 6

readinessProbe:
  enabled: true
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  successThreshold: 1
  failureThreshold: 3

# 更新策略
updateStrategy:
  type: RollingUpdate