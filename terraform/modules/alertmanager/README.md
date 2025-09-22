# Alertmanager 模块

基于 Bitnami Helm Chart 的 Alertmanager 0.26 告警管理系统，针对单节点 4C8G 环境优化。

## 特性

- **版本**: Alertmanager 0.26.0
- **数据保留**: 120 小时
- **存储**: 2Gi 持久化存储
- **告警路由**: 智能分组和抑制
- **通知渠道**: 邮件、Slack、企业微信、Webhook
- **外部访问**: NodePort 30093

## 配置参数

| 参数 | 默认值 | 说明 |
|-----|--------|------|
| `namespace` | infra | 部署命名空间 |
| `release_name` | alertmanager | Helm 发布名称 |
| `alertmanager_version` | 0.26.0 | Alertmanager 版本 |
| `external_port` | 30093 | NodePort 端口 |
| `storage.size` | 2Gi | 存储大小 |
| `retention` | 120h | 数据保留时间 |

### 路由配置

| 参数 | 默认值 | 说明 |
|-----|--------|------|
| `routes.group_by` | [alertname, cluster, service] | 分组字段 |
| `routes.group_wait` | 10s | 分组等待时间 |
| `routes.group_interval` | 10s | 分组间隔 |
| `routes.repeat_interval` | 1h | 重复发送间隔 |

### 资源配置

| 资源 | 请求 | 限制 |
|------|------|------|
| CPU | 25m | 100m |
| 内存 | 64Mi | 256Mi |

## 使用方法

### 基础使用

```hcl
module "alertmanager" {
  source = "./modules/alertmanager"
}
```

### 自定义配置

```hcl
module "alertmanager" {
  source = "./modules/alertmanager"

  namespace = "monitoring"
  retention = "240h"

  # SMTP 配置
  smtp = {
    enabled      = true
    smarthost    = "smtp.gmail.com:587"
    from         = "alerts@example.com"
    auth_username = "alerts@example.com"
    auth_password = var.smtp_password
    require_tls  = true
  }

  # Slack 配置
  slack = {
    enabled    = true
    api_url    = var.slack_webhook_url
    channel    = "#alerts"
    username   = "alertmanager"
    icon_emoji = ":warning:"
  }

  # Webhook 配置
  webhook = {
    enabled = true
    url     = "https://webhook.site/your-webhook-url"
  }

  # 企业微信配置
  wechat = {
    enabled   = true
    corp_id   = var.wechat_corp_id
    corp_secret = var.wechat_secret
    agent_id  = var.wechat_agent_id
    to_user   = "@all"
    to_party  = ""
    to_tag    = ""
  }

  # 路由配置
  routes = {
    group_by       = ["alertname", "cluster", "service", "severity"]
    group_wait     = "5s"
    group_interval = "5s"
    repeat_interval = "30m"
  }
}
```

## 访问方式

### Web 界面

```bash
# 外部访问
http://<NODE_IP>:30093

# 端口转发（本地访问）
kubectl port-forward -n infra svc/alertmanager 9093:9093
```

### API 访问

```bash
# 查看所有告警
curl http://<NODE_IP>:30093/api/v1/alerts

# 查看告警组
curl http://<NODE_IP>:30093/api/v1/alerts/groups

# 查看接收器
curl http://<NODE_IP>:30093/api/v1/receivers

# 查看静默规则
curl http://<NODE_IP>:30093/api/v1/silences

# 健康检查
curl http://<NODE_IP>:30093/-/healthy
```

## 告警路由

### 路由配置结构

```yaml
route:
  # 默认接收器
  receiver: 'default'

  # 分组配置
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h

  # 子路由
  routes:
    # 严重告警
    - match:
        severity: critical
      receiver: 'critical-alerts'
      group_wait: 5s
      repeat_interval: 30m

    # 数据库告警
    - match_re:
        job: '^(mongodb|redis|rabbitmq)$'
      receiver: 'database-alerts'

    # Kubernetes 告警
    - match_re:
        alertname: '^(PodFailed|NodeDown)$'
      receiver: 'kubernetes-alerts'
```

### 告警分组

告警会根据标签自动分组，相同组的告警会合并发送：

```bash
# 查看当前分组
curl http://<NODE_IP>:30093/api/v1/alerts/groups | jq '.[] | {name: .name, alerts: .alerts | length}'
```

## 通知配置

### 邮件通知

```yaml
email_configs:
  - to: 'admin@example.com'
    from: 'alerts@example.com'
    smarthost: 'smtp.gmail.com:587'
    auth_username: 'alerts@example.com'
    auth_password: 'password'
    headers:
      Subject: '{{ .GroupLabels.SortedPairs }}'
    html: |
      <h3>告警详情</h3>
      {{ range .Alerts }}
      <p>{{ .Annotations.description }}</p>
      {{ end }}
```

### Slack 通知

```yaml
slack_configs:
  - api_url: 'YOUR_SLACK_WEBHOOK_URL'
    channel: '#alerts'
    username: 'alertmanager'
    icon_emoji: ':warning:'
    title: '告警通知'
    text: |
      {{ range .Alerts }}
      *告警:* {{ .Labels.alertname }}
      *描述:* {{ .Annotations.description }}
      {{ end }}
```

### Webhook 通知

```yaml
webhook_configs:
  - url: 'http://webhook.example.com/alerts'
    send_resolved: true
    http_config:
      basic_auth:
        username: 'webhook_user'
        password: 'webhook_pass'
```

### 企业微信通知

```yaml
wechat_configs:
  - api_secret: 'YOUR_SECRET'
    corp_id: 'YOUR_CORP_ID'
    agent_id: 'YOUR_AGENT_ID'
    to_user: '@all'
    message: |
      告警通知
      {{ range .Alerts }}
      {{ .Annotations.summary }}
      {{ end }}
```

## 静默管理

### 创建静默规则

#### 通过 Web UI

1. 访问 `http://<NODE_IP>:30093/#/silences`
2. 点击 "New Silence"
3. 设置匹配器和时间
4. 添加注释

#### 通过 API

```bash
# 创建静默
curl -X POST http://<NODE_IP>:30093/api/v1/silences \
  -H "Content-Type: application/json" \
  -d '{
    "matchers": [
      {
        "name": "alertname",
        "value": "HighCPUUsage",
        "isRegex": false
      },
      {
        "name": "instance",
        "value": "node1",
        "isRegex": false
      }
    ],
    "startsAt": "2024-01-01T00:00:00Z",
    "endsAt": "2024-01-01T02:00:00Z",
    "createdBy": "admin",
    "comment": "维护期间静默"
  }'

# 查看静默规则
curl http://<NODE_IP>:30093/api/v1/silences | jq '.[] | {id: .id, comment: .comment, state: .status.state}'

# 删除静默
curl -X DELETE http://<NODE_IP>:30093/api/v1/silence/<silence-id>
```

### 静默匹配测试

```bash
# 测试告警是否会被静默
curl -X POST http://<NODE_IP>:30093/api/v1/silences/test \
  -H "Content-Type: application/json" \
  -d '{
    "alert": {
      "labels": {
        "alertname": "HighCPUUsage",
        "instance": "node1"
      }
    }
  }'
```

## 告警抑制

### 抑制规则配置

```yaml
inhibit_rules:
  # 节点宕机时抑制该节点的其他告警
  - source_match:
      alertname: 'NodeDown'
    target_match_re:
      instance: '.*'
    equal: ['instance']

  # 严重告警抑制警告告警
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']

  # 数据库服务不可用时抑制性能告警
  - source_match:
      alertname: 'DatabaseServiceDown'
    target_match_re:
      alertname: '^(MongoDB|Redis|RabbitMQ).*'
    equal: ['job']
```

## 告警测试

### 发送测试告警

```bash
# 发送测试告警到 Alertmanager
curl -X POST http://<NODE_IP>:30093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[
    {
      "labels": {
        "alertname": "TestAlert",
        "severity": "warning",
        "instance": "test-instance",
        "job": "test"
      },
      "annotations": {
        "summary": "测试告警",
        "description": "这是一个测试告警，用于验证 Alertmanager 配置"
      },
      "generatorURL": "http://prometheus:9090/",
      "startsAt": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'"
    }
  ]'
```

### 批量测试

```bash
# 发送多个测试告警
for severity in critical warning info; do
  curl -X POST http://<NODE_IP>:30093/api/v1/alerts \
    -H "Content-Type: application/json" \
    -d '[{
      "labels": {
        "alertname": "Test'$severity'Alert",
        "severity": "'$severity'",
        "instance": "test-'$severity'"
      },
      "annotations": {
        "summary": "'$severity'级别测试告警"
      }
    }]'
done
```

## 运维管理

### 查看状态

```bash
# 查看 Pod 状态
kubectl get pods -n infra -l app.kubernetes.io/name=alertmanager

# 查看日志
kubectl logs -f alertmanager-0 -n infra

# 查看配置
kubectl exec -it alertmanager-0 -n infra -- cat /opt/bitnami/alertmanager/conf/alertmanager.yml
```

### 配置管理

```bash
# 验证配置语法
kubectl exec -it alertmanager-0 -n infra -- amtool config check /opt/bitnami/alertmanager/conf/alertmanager.yml

# 查看路由树
kubectl exec -it alertmanager-0 -n infra -- amtool config routes --config.file=/opt/bitnami/alertmanager/conf/alertmanager.yml

# 测试路由匹配
kubectl exec -it alertmanager-0 -n infra -- amtool config routes test --config.file=/opt/bitnami/alertmanager/conf/alertmanager.yml <<EOF
{
  "labels": {
    "alertname": "HighCPUUsage",
    "severity": "critical"
  }
}
EOF
```

### 重载配置

```bash
# 发送 SIGHUP 信号
kubectl exec -it alertmanager-0 -n infra -- kill -HUP 1

# 或使用 API
curl -X POST http://<NODE_IP>:30093/-/reload
```

## 集群模式

### 查看集群状态

```bash
# 查看集群成员
curl http://<NODE_IP>:30093/api/v1/status | jq '.data.cluster'

# 查看集群配置
kubectl exec -it alertmanager-0 -n infra -- amtool cluster show --alertmanager.url=http://localhost:9093
```

### 同步测试

```bash
# 在一个节点创建静默
curl -X POST http://<NODE_IP>:30093/api/v1/silences -d '...'

# 在其他节点验证同步
curl http://<OTHER_NODE_IP>:30093/api/v1/silences
```

## 性能监控

### 关键指标

```promql
# 活跃告警数
alertmanager_alerts

# 静默规则数
alertmanager_silences

# 通知发送速率
rate(alertmanager_notifications_total[5m])

# 通知失败率
rate(alertmanager_notifications_failed_total[5m])

# 告警处理延迟
alertmanager_notification_latency_seconds
```

### 资源使用

```bash
# 查看资源使用
kubectl top pod alertmanager-0 -n infra

# 查看内存详情
kubectl exec -it alertmanager-0 -n infra -- cat /proc/meminfo
```

## 故障排查

### 告警未收到

```bash
# 检查告警是否到达
curl http://<NODE_IP>:30093/api/v1/alerts | jq '.[] | select(.labels.alertname == "YOUR_ALERT")'

# 查看日志中的错误
kubectl logs alertmanager-0 -n infra | grep ERROR

# 检查通知配置
kubectl exec -it alertmanager-0 -n infra -- amtool config check
```

### 通知发送失败

```bash
# 查看通知错误
kubectl logs alertmanager-0 -n infra | grep "notify error"

# 测试 SMTP 连接
kubectl exec -it alertmanager-0 -n infra -- nc -zv smtp.gmail.com 587

# 测试 Webhook
kubectl exec -it alertmanager-0 -n infra -- curl -X POST webhook.example.com/test
```

### 静默不生效

```bash
# 查看静默状态
curl http://<NODE_IP>:30093/api/v1/silences | jq '.[] | select(.status.state == "active")'

# 检查匹配器
curl http://<NODE_IP>:30093/api/v1/silences | jq '.[] | .matchers'

# 测试匹配
kubectl exec -it alertmanager-0 -n infra -- amtool silence query --alertmanager.url=http://localhost:9093
```

## 备份与恢复

### 备份

```bash
# 导出静默规则
curl http://<NODE_IP>:30093/api/v1/silences > silences-backup.json

# 备份数据目录
kubectl exec -it alertmanager-0 -n infra -- tar czf /tmp/alertmanager-backup.tar.gz /opt/bitnami/alertmanager/data

# 复制到本地
kubectl cp infra/alertmanager-0:/tmp/alertmanager-backup.tar.gz ./alertmanager-backup.tar.gz
```

### 恢复

```bash
# 恢复静默规则
cat silences-backup.json | jq '.[]' | while read silence; do
  curl -X POST http://<NODE_IP>:30093/api/v1/silences -d "$silence"
done

# 恢复数据
kubectl cp ./alertmanager-backup.tar.gz infra/alertmanager-0:/tmp/
kubectl exec -it alertmanager-0 -n infra -- tar xzf /tmp/alertmanager-backup.tar.gz -C /
```

## 安全建议

1. **启用认证**: 配置基本认证或 OAuth
2. **TLS 加密**: 启用 HTTPS
3. **网络隔离**: 使用 NetworkPolicy
4. **敏感信息**: 使用 Secret 管理密码
5. **审计日志**: 记录所有操作

### 基本认证配置

```yaml
# 在 Ingress 中配置
annotations:
  nginx.ingress.kubernetes.io/auth-type: basic
  nginx.ingress.kubernetes.io/auth-secret: alertmanager-auth
  nginx.ingress.kubernetes.io/auth-realm: 'Alertmanager'
```

### TLS 配置

```yaml
tls:
  enabled: true
  certFile: /certs/tls.crt
  keyFile: /certs/tls.key
```

## 集成配置

### Prometheus 集成

Prometheus 配置中添加：

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager.infra.svc.cluster.local:9093
```

### Grafana 集成

在 Grafana 中添加 Alertmanager 数据源：

```json
{
  "name": "Alertmanager",
  "type": "alertmanager",
  "url": "http://alertmanager.infra.svc.cluster.local:9093",
  "access": "proxy"
}
```

## 最佳实践

1. **告警分级**: 使用 severity 标签区分告警级别
2. **告警模板**: 使用模板减少重复配置
3. **静默计划**: 维护期间提前设置静默
4. **告警收敛**: 合理设置分组减少告警风暴
5. **定期测试**: 定期测试告警链路

## 升级指南

```bash
# 备份配置和数据
kubectl exec -it alertmanager-0 -n infra -- tar czf /tmp/backup.tar.gz /opt/bitnami/alertmanager

# 更新版本
# 修改 variables.tf 中的 alertmanager_version

# 应用更新
terraform apply -target=module.alertmanager

# 验证版本
kubectl exec -it alertmanager-0 -n infra -- alertmanager --version
```

## 相关文档

- [Alertmanager 官方文档](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Alertmanager 配置](https://prometheus.io/docs/alerting/latest/configuration/)
- [Bitnami Alertmanager Chart](https://github.com/bitnami/charts/tree/main/bitnami/alertmanager)
- [告警最佳实践](https://prometheus.io/docs/practices/alerting/)