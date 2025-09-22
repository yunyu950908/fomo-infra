# Grafana 模块

基于 Bitnami Helm Chart 的 Grafana 10.2 可视化平台，针对单节点 4C8G 环境优化。

## 特性

- **版本**: Grafana 10.2.2
- **数据源**: 预配置 Prometheus
- **存储**: 5Gi 持久化存储
- **插件**: 饼图、世界地图、时钟面板
- **外部访问**: NodePort 30030
- **认证**: 内置管理员账户

## 配置参数

| 参数 | 默认值 | 说明 |
|-----|--------|------|
| `namespace` | infra | 部署命名空间 |
| `release_name` | grafana | Helm 发布名称 |
| `grafana_version` | 10.2.2 | Grafana 版本 |
| `external_port` | 30030 | NodePort 端口 |
| `storage.size` | 5Gi | 存储大小 |
| `prometheus_url` | http://prometheus.infra:9090 | Prometheus 地址 |

### 认证配置

| 参数 | 默认值 | 说明 |
|-----|--------|------|
| `admin_credentials.username` | admin | 管理员用户名 |
| `admin_credentials.password` | GrafanaAdmin2024! | 管理员密码 |

### 资源配置

| 资源 | 请求 | 限制 |
|------|------|------|
| CPU | 50m | 250m |
| 内存 | 128Mi | 512Mi |

## 使用方法

### 基础使用

```hcl
module "grafana" {
  source = "./modules/grafana"

  prometheus_url = module.prometheus.prometheus_url_internal
}
```

### 自定义配置

```hcl
module "grafana" {
  source = "./modules/grafana"

  namespace = "monitoring"
  grafana_version = "10.2.2"

  admin_credentials = {
    username = "admin"
    password = var.grafana_password
  }

  storage = {
    class = "fast-ssd"
    size  = "10Gi"
  }

  resources = {
    requests = {
      memory = "256Mi"
      cpu    = "100m"
    }
    limits = {
      memory = "1Gi"
      cpu    = "500m"
    }
  }

  # 插件配置
  plugins = [
    "grafana-piechart-panel",
    "grafana-worldmap-panel",
    "grafana-clock-panel",
    "grafana-simple-json-datasource"
  ]

  # SMTP 配置
  smtp = {
    enabled    = true
    host       = "smtp.gmail.com"
    port       = 587
    user       = "alerts@example.com"
    password   = var.smtp_password
    from_name  = "Grafana"
    from_email = "grafana@example.com"
  }
}
```

## 访问方式

### Web 界面

```bash
# 外部访问
http://<NODE_IP>:30030

# 登录凭据
用户名: admin
密码: GrafanaAdmin2024!

# 端口转发（本地访问）
kubectl port-forward -n infra svc/grafana 3000:3000
```

### API 访问

```bash
# 健康检查
curl http://<NODE_IP>:30030/api/health

# 获取组织信息
curl -u admin:GrafanaAdmin2024! http://<NODE_IP>:30030/api/org

# 获取数据源列表
curl -u admin:GrafanaAdmin2024! http://<NODE_IP>:30030/api/datasources

# 搜索仪表板
curl -u admin:GrafanaAdmin2024! http://<NODE_IP>:30030/api/search
```

## 数据源配置

### 预配置数据源

1. **Prometheus** (默认)
   - URL: `http://prometheus.infra.svc.cluster.local:9090`
   - 类型: Prometheus
   - 访问: proxy

2. **TestData**
   - 用于测试和演示
   - 类型: TestData

### 添加数据源

#### 通过 UI

1. 设置 → 数据源 → 添加数据源
2. 选择数据源类型
3. 配置连接参数
4. 保存并测试

#### 通过 API

```bash
curl -X POST -H "Content-Type: application/json" \
  -u admin:GrafanaAdmin2024! \
  -d '{
    "name": "MySQL",
    "type": "mysql",
    "url": "mysql.infra:3306",
    "access": "proxy",
    "user": "grafana",
    "database": "metrics",
    "basicAuth": false,
    "isDefault": false,
    "jsonData": {
      "maxOpenConns": 0,
      "maxIdleConns": 2,
      "connMaxLifetime": 14400
    }
  }' \
  http://<NODE_IP>:30030/api/datasources
```

## 仪表板管理

### 推荐仪表板

#### 系统监控
- **Node Exporter Full** (ID: 1860)
- **Kubernetes Cluster Monitoring** (ID: 7249)
- **Kubernetes Pod Monitoring** (ID: 6417)

#### 数据库监控
- **MongoDB Overview** (ID: 2583)
- **Redis Dashboard** (ID: 763)
- **RabbitMQ Overview** (ID: 10991)

#### 应用监控
- **Prometheus Stats** (ID: 2)
- **Nginx Ingress Controller** (ID: 9614)

### 导入仪表板

#### 方法一：通过 ID

```bash
# 通过 API 导入
curl -X POST -H "Content-Type: application/json" \
  -u admin:GrafanaAdmin2024! \
  -d '{
    "dashboard": {
      "id": null,
      "uid": null,
      "title": "Production Overview",
      "tags": ["templated"],
      "timezone": "browser",
      "schemaVersion": 16,
      "version": 0
    },
    "folderId": 0,
    "overwrite": false
  }' \
  http://<NODE_IP>:30030/api/dashboards/db
```

#### 方法二：通过 JSON 文件

```bash
# 下载仪表板 JSON
wget https://grafana.com/api/dashboards/1860/revisions/latest/download -O dashboard.json

# 导入仪表板
curl -X POST -H "Content-Type: application/json" \
  -u admin:GrafanaAdmin2024! \
  -d @dashboard.json \
  http://<NODE_IP>:30030/api/dashboards/db
```

### 创建自定义仪表板

```json
{
  "dashboard": {
    "title": "自定义监控",
    "panels": [
      {
        "id": 1,
        "gridPos": { "h": 8, "w": 12, "x": 0, "y": 0 },
        "type": "graph",
        "title": "CPU 使用率",
        "targets": [
          {
            "expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "refId": "A"
          }
        ]
      },
      {
        "id": 2,
        "gridPos": { "h": 8, "w": 12, "x": 12, "y": 0 },
        "type": "graph",
        "title": "内存使用率",
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
            "refId": "B"
          }
        ]
      }
    ]
  }
}
```

## 告警配置

### 创建告警规则

1. 进入仪表板面板
2. 点击面板标题 → Edit
3. 切换到 Alert 选项卡
4. 配置告警条件

### 通知渠道

#### 配置邮件通知

```bash
# 通过 API 创建通知渠道
curl -X POST -H "Content-Type: application/json" \
  -u admin:GrafanaAdmin2024! \
  -d '{
    "name": "Email Alert",
    "type": "email",
    "isDefault": true,
    "settings": {
      "addresses": "admin@example.com;ops@example.com"
    }
  }' \
  http://<NODE_IP>:30030/api/alert-notifications
```

#### 配置 Webhook

```bash
curl -X POST -H "Content-Type: application/json" \
  -u admin:GrafanaAdmin2024! \
  -d '{
    "name": "Webhook",
    "type": "webhook",
    "settings": {
      "url": "http://webhook.example.com/alert",
      "httpMethod": "POST"
    }
  }' \
  http://<NODE_IP>:30030/api/alert-notifications
```

## 用户管理

### 创建用户

```bash
# 创建新用户
curl -X POST -H "Content-Type: application/json" \
  -u admin:GrafanaAdmin2024! \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "login": "john",
    "password": "password123"
  }' \
  http://<NODE_IP>:30030/api/admin/users

# 授予权限
curl -X PATCH -H "Content-Type: application/json" \
  -u admin:GrafanaAdmin2024! \
  -d '{"role": "Editor"}' \
  http://<NODE_IP>:30030/api/org/users/2
```

### 创建团队

```bash
curl -X POST -H "Content-Type: application/json" \
  -u admin:GrafanaAdmin2024! \
  -d '{
    "name": "DevOps Team",
    "email": "devops@example.com"
  }' \
  http://<NODE_IP>:30030/api/teams
```

## 插件管理

### 查看已安装插件

```bash
kubectl exec -it grafana-0 -n infra -- grafana-cli plugins ls
```

### 安装新插件

```bash
# 安装插件
kubectl exec -it grafana-0 -n infra -- grafana-cli plugins install <plugin-id>

# 重启 Grafana
kubectl rollout restart deployment/grafana -n infra

# 常用插件
grafana-cli plugins install grafana-piechart-panel
grafana-cli plugins install grafana-worldmap-panel
grafana-cli plugins install alexanderzobnin-zabbix-app
grafana-cli plugins install grafana-kubernetes-app
```

## 运维管理

### 查看状态

```bash
# 查看 Pod 状态
kubectl get pods -n infra -l app.kubernetes.io/name=grafana

# 查看日志
kubectl logs -f grafana-0 -n infra

# 查看配置
kubectl exec -it grafana-0 -n infra -- cat /opt/bitnami/grafana/conf/grafana.ini
```

### 备份与恢复

#### 备份

```bash
# 备份数据库和配置
kubectl exec -it grafana-0 -n infra -- tar czf /tmp/grafana-backup.tar.gz \
  /opt/bitnami/grafana/data \
  /opt/bitnami/grafana/conf

# 复制到本地
kubectl cp infra/grafana-0:/tmp/grafana-backup.tar.gz ./grafana-backup.tar.gz

# 导出所有仪表板
for dashboard in $(curl -s -u admin:GrafanaAdmin2024! http://<NODE_IP>:30030/api/search | jq -r '.[].uid'); do
  curl -s -u admin:GrafanaAdmin2024! http://<NODE_IP>:30030/api/dashboards/uid/$dashboard \
    > dashboard-$dashboard.json
done
```

#### 恢复

```bash
# 复制备份文件
kubectl cp ./grafana-backup.tar.gz infra/grafana-0:/tmp/

# 恢复数据
kubectl exec -it grafana-0 -n infra -- tar xzf /tmp/grafana-backup.tar.gz -C /

# 重启 Grafana
kubectl rollout restart deployment/grafana -n infra
```

## 性能优化

### 查询优化

```ini
# grafana.ini 配置
[dataproxy]
timeout = 30
keep_alive_seconds = 30
concurrent_query_limit = 10

[rendering]
concurrent_render_limit = 5

[database]
max_idle_conn = 2
max_open_conn = 25
conn_max_lifetime = 14400
```

### 缓存配置

```ini
[caching]
enabled = true

[remote_cache]
type = redis
connstr = addr=redis.infra:6379,pool_size=100,password=RedisSecure2024!
```

### 面板优化

1. **减少查询数量**: 合并相似查询
2. **使用变量**: 减少重复查询
3. **设置刷新间隔**: 避免过于频繁刷新
4. **限制时间范围**: 避免查询过多历史数据

## 故障排查

### 登录问题

```bash
# 重置管理员密码
kubectl exec -it grafana-0 -n infra -- grafana-cli admin reset-admin-password newpassword

# 查看认证日志
kubectl logs grafana-0 -n infra | grep auth
```

### 数据源连接问题

```bash
# 测试 Prometheus 连接
kubectl exec -it grafana-0 -n infra -- curl -s http://prometheus.infra:9090/api/v1/query?query=up

# 查看数据源配置
kubectl exec -it grafana-0 -n infra -- cat /opt/bitnami/grafana/conf/provisioning/datasources/datasources.yaml
```

### 性能问题

```bash
# 查看资源使用
kubectl top pod grafana-0 -n infra

# 查看慢查询
kubectl logs grafana-0 -n infra | grep "slow query"

# 清理缓存
kubectl exec -it grafana-0 -n infra -- rm -rf /opt/bitnami/grafana/data/cache/*
```

## 集成配置

### Prometheus 集成

Grafana 已预配置 Prometheus 数据源：
- URL: `http://prometheus.infra.svc.cluster.local:9090`
- 访问模式: proxy
- 默认数据源: 是

### LDAP 集成

```ini
# grafana.ini
[auth.ldap]
enabled = true
config_file = /opt/bitnami/grafana/conf/ldap.toml
```

### OAuth 集成

```ini
[auth.generic_oauth]
enabled = true
client_id = YOUR_CLIENT_ID
client_secret = YOUR_CLIENT_SECRET
scopes = openid profile email
auth_url = https://oauth.provider.com/authorize
token_url = https://oauth.provider.com/token
api_url = https://oauth.provider.com/userinfo
```

## 安全建议

1. **更改默认密码**: 生产环境必须修改管理员密码
2. **启用 HTTPS**: 配置 TLS 证书
3. **限制访问**: 使用 NetworkPolicy
4. **审计日志**: 启用操作审计
5. **定期备份**: 自动备份仪表板和配置

### 安全配置

```ini
[security]
admin_user = admin
admin_password = ${GRAFANA_ADMIN_PASSWORD}
secret_key = ${GRAFANA_SECRET_KEY}
disable_gravatar = true
cookie_secure = true
cookie_samesite = strict
strict_transport_security = true
x_content_type_options = true
x_xss_protection = true
```

## 监控 Grafana

### 自身指标

Grafana 暴露了 Prometheus 指标：

```promql
# Grafana 指标
grafana_api_response_status_total
grafana_api_dataproxy_request_all_milliseconds
grafana_alerting_active_alerts
grafana_db_datasource_query_duration
```

### 健康检查

```bash
# API 健康检查
curl http://<NODE_IP>:30030/api/health

# 数据库健康检查
curl http://<NODE_IP>:30030/api/health/db
```

## 升级指南

```bash
# 备份数据
kubectl exec -it grafana-0 -n infra -- tar czf /tmp/backup.tar.gz /opt/bitnami/grafana/data

# 更新版本
# 修改 variables.tf 中的 grafana_version

# 应用更新
terraform apply -target=module.grafana

# 验证版本
kubectl exec -it grafana-0 -n infra -- grafana-server -v
```

## 相关文档

- [Grafana 官方文档](https://grafana.com/docs/grafana/latest/)
- [Grafana 仪表板库](https://grafana.com/grafana/dashboards/)
- [Bitnami Grafana Chart](https://github.com/bitnami/charts/tree/main/bitnami/grafana)
- [Grafana 最佳实践](https://grafana.com/docs/grafana/latest/best-practices/)