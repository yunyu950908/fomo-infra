# Alertmanager 告警配置文件 - 4C8G 单节点环境

global:
  # 全局 SMTP 配置
%{ if smtp_enabled ~}
  smtp_smarthost: '${smtp_smarthost}'
  smtp_from: '${smtp_from}'
%{ if smtp_auth_username != "" ~}
  smtp_auth_username: '${smtp_auth_username}'
  smtp_auth_password: '${smtp_auth_password}'
%{ endif ~}
  smtp_require_tls: ${smtp_require_tls}
%{ endif ~}

  # 全局企业微信配置
%{ if wechat_enabled ~}
  wechat_api_url: 'https://qyapi.weixin.qq.com/cgi-bin/'
  wechat_api_secret: '${wechat_corp_secret}'
  wechat_api_corp_id: '${wechat_corp_id}'
%{ endif ~}

  # 全局 Slack 配置
%{ if slack_enabled ~}
  slack_api_url: '${slack_api_url}'
%{ endif ~}

  # 解析超时
  resolve_timeout: 5m

# 告警路由配置
route:
  group_by: ${jsonencode(group_by)}
  group_wait: ${group_wait}
  group_interval: ${group_interval}
  repeat_interval: ${repeat_interval}
  receiver: 'default'

  # 子路由
  routes:
    # 严重告警 - 立即通知
    - match:
        severity: critical
      receiver: 'critical-alerts'
      group_wait: 5s
      repeat_interval: 30m
      continue: false

    # 节点相关告警
    - match_re:
        alertname: '^(NodeDown|HighCPUUsage|HighMemoryUsage|HighDiskUsage)$'
      receiver: 'node-alerts'
      group_wait: 10s
      repeat_interval: 1h
      continue: false

    # 数据库告警
    - match_re:
        job: '^(mongodb|redis|rabbitmq)$'
      receiver: 'database-alerts'
      group_wait: 10s
      repeat_interval: 1h
      continue: false

    # Kubernetes 告警
    - match_re:
        alertname: '^(PodFailed|PodRestartingTooMuch|PodPending)$'
      receiver: 'kubernetes-alerts'
      group_wait: 5s
      repeat_interval: 30m
      continue: false

    # 存储告警
    - match_re:
        alertname: '^(PersistentVolume.*|HighDiskUsage)$'
      receiver: 'storage-alerts'
      group_wait: 10s
      repeat_interval: 2h
      continue: false

    # 网络告警
    - match_re:
        alertname: '^(HighNetworkErrorRate)$'
      receiver: 'network-alerts'
      group_wait: 15s
      repeat_interval: 2h
      continue: false

# 告警抑制规则
%{ if inhibit_enabled ~}
inhibit_rules:
  # 节点宕机时抑制该节点上的所有其他告警
  - source_match:
      alertname: 'NodeDown'
    target_match_re:
      instance: '.*'
    equal: ['instance']

  # 严重告警抑制相同实例的警告告警
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']

  # Pod 失败时抑制该 Pod 的容器相关告警
  - source_match:
      alertname: 'PodFailed'
    target_match_re:
      alertname: '^Container.*'
    equal: ['pod', 'namespace']

  # 数据库服务不可用时抑制相关性能告警
  - source_match:
      alertname: 'DatabaseServiceDown'
    target_match_re:
      alertname: '^(MongoDB.*|Redis.*|RabbitMQ.*)$'
    equal: ['job']

  # 磁盘使用率过高时抑制 I/O 相关告警
  - source_match:
      alertname: 'HighDiskUsage'
    target_match:
      alertname: 'HighDiskIOUsage'
    equal: ['instance', 'device']
%{ endif ~}

# 接收器配置
receivers:
  # 默认接收器
  - name: 'default'
%{ if smtp_enabled ~}
    email_configs:
      - to: 'admin@example.com'
        subject: '[FOMO-K3S] 告警通知'
        html: |
          <h3>🔔 系统告警通知</h3>
          <table border="1" style="border-collapse: collapse;">
          <tr><th>告警名称</th><th>级别</th><th>状态</th><th>时间</th><th>描述</th></tr>
          {{ range .Alerts }}
          <tr>
            <td>{{ .Labels.alertname }}</td>
            <td>{{ .Labels.severity }}</td>
            <td>{{ .Status }}</td>
            <td>{{ .StartsAt.Format "2006-01-02 15:04:05" }}</td>
            <td>{{ .Annotations.description }}</td>
          </tr>
          {{ end }}
          </table>
          <p>请及时处理相关告警！</p>
%{ endif ~}
%{ if webhook_enabled ~}
    webhook_configs:
      - url: '${webhook_url}'
        send_resolved: true
        http_config:
          basic_auth:
            username: ''
            password: ''
%{ endif ~}

  # 严重告警接收器
  - name: 'critical-alerts'
%{ if smtp_enabled ~}
    email_configs:
      - to: 'admin@example.com,ops@example.com'
        subject: '[FOMO-K3S] 🚨 紧急告警 🚨'
        html: |
          <h2 style="color: red;">🚨 紧急告警通知 🚨</h2>
          <p><strong>请立即处理以下严重告警：</strong></p>
          <table border="1" style="border-collapse: collapse; color: red;">
          <tr style="background-color: #ffcccc;"><th>告警名称</th><th>实例</th><th>时间</th><th>描述</th></tr>
          {{ range .Alerts }}
          <tr>
            <td><strong>{{ .Labels.alertname }}</strong></td>
            <td>{{ .Labels.instance }}</td>
            <td>{{ .StartsAt.Format "2006-01-02 15:04:05" }}</td>
            <td>{{ .Annotations.description }}</td>
          </tr>
          {{ end }}
          </table>
          <p style="color: red;"><strong>此告警需要立即处理！</strong></p>
%{ endif ~}
%{ if slack_enabled ~}
    slack_configs:
      - api_url: '${slack_api_url}'
        channel: '${slack_channel}'
        username: '${slack_username}'
        icon_emoji: ':rotating_light:'
        title: '🚨 FOMO-K3S 紧急告警'
        text: |
          {{ range .Alerts }}
          *告警:* {{ .Labels.alertname }}
          *实例:* {{ .Labels.instance }}
          *描述:* {{ .Annotations.description }}
          *时间:* {{ .StartsAt.Format "2006-01-02 15:04:05" }}
          {{ end }}
        color: 'danger'
        send_resolved: true
%{ endif ~}
%{ if wechat_enabled ~}
    wechat_configs:
      - api_secret: '${wechat_corp_secret}'
        corp_id: '${wechat_corp_id}'
        agent_id: '${wechat_agent_id}'
        to_user: '${wechat_to_user}'
        message: |
          🚨 FOMO-K3S 紧急告警
          {{ range .Alerts }}
          告警: {{ .Labels.alertname }}
          实例: {{ .Labels.instance }}
          描述: {{ .Annotations.description }}
          时间: {{ .StartsAt.Format "2006-01-02 15:04:05" }}
          {{ end }}
          请立即处理！
%{ endif ~}

  # 节点告警接收器
  - name: 'node-alerts'
%{ if smtp_enabled ~}
    email_configs:
      - to: 'ops@example.com'
        subject: '[FOMO-K3S] 节点告警通知'
        html: |
          <h3>🖥️ 节点告警通知</h3>
          <p>以下节点出现异常：</p>
          <ul>
          {{ range .Alerts }}
          <li><strong>{{ .Labels.alertname }}</strong> - {{ .Labels.instance }}: {{ .Annotations.description }}</li>
          {{ end }}
          </ul>
%{ endif ~}

  # 数据库告警接收器
  - name: 'database-alerts'
%{ if smtp_enabled ~}
    email_configs:
      - to: 'dba@example.com'
        subject: '[FOMO-K3S] 数据库告警通知'
        html: |
          <h3>🗄️ 数据库告警通知</h3>
          <table border="1" style="border-collapse: collapse;">
          <tr><th>数据库</th><th>告警</th><th>描述</th></tr>
          {{ range .Alerts }}
          <tr>
            <td>{{ .Labels.job }}</td>
            <td>{{ .Labels.alertname }}</td>
            <td>{{ .Annotations.description }}</td>
          </tr>
          {{ end }}
          </table>
%{ endif ~}

  # Kubernetes 告警接收器
  - name: 'kubernetes-alerts'
%{ if smtp_enabled ~}
    email_configs:
      - to: 'k8s-admin@example.com'
        subject: '[FOMO-K3S] Kubernetes 告警通知'
        html: |
          <h3>☸️ Kubernetes 告警通知</h3>
          <table border="1" style="border-collapse: collapse;">
          <tr><th>命名空间</th><th>Pod</th><th>告警</th><th>描述</th></tr>
          {{ range .Alerts }}
          <tr>
            <td>{{ .Labels.namespace }}</td>
            <td>{{ .Labels.pod }}</td>
            <td>{{ .Labels.alertname }}</td>
            <td>{{ .Annotations.description }}</td>
          </tr>
          {{ end }}
          </table>
%{ endif ~}

  # 存储告警接收器
  - name: 'storage-alerts'
%{ if smtp_enabled ~}
    email_configs:
      - to: 'ops@example.com'
        subject: '[FOMO-K3S] 存储告警通知'
        html: |
          <h3>💾 存储告警通知</h3>
          <p>存储系统出现以下问题：</p>
          <ul>
          {{ range .Alerts }}
          <li>{{ .Labels.alertname }}: {{ .Annotations.description }}</li>
          {{ end }}
          </ul>
%{ endif ~}

  # 网络告警接收器
  - name: 'network-alerts'
%{ if smtp_enabled ~}
    email_configs:
      - to: 'network-admin@example.com'
        subject: '[FOMO-K3S] 网络告警通知'
        html: |
          <h3>🌐 网络告警通知</h3>
          <p>网络系统出现以下问题：</p>
          <ul>
          {{ range .Alerts }}
          <li>{{ .Labels.instance }} - {{ .Labels.device }}: {{ .Annotations.description }}</li>
          {{ end }}
          </ul>
%{ endif ~}

# 模板配置
templates:
  - '/etc/alertmanager/templates/*.tmpl'