# Prometheus 模块

基于 Bitnami Helm Chart 的 Prometheus 2.48 监控系统，针对单节点 4C8G 环境优化。

## 特性

- **版本**: Prometheus 2.48.0
- **数据保留**: 15 天
- **抓取间隔**: 30 秒
- **存储**: 15Gi 持久化存储
- **告警集成**: Alertmanager 支持
- **外部访问**: NodePort 30090

## 配置参数

| 参数 | 默认值 | 说明 |
|-----|--------|------|
| `namespace` | infra | 部署命名空间 |
| `release_name` | prometheus | Helm 发布名称 |
| `prometheus_version` | 2.48.0 | Prometheus 版本 |
| `external_port` | 30090 | NodePort 端口 |
| `storage.size` | 15Gi | 存储大小 |
| `retention` | 15d | 数据保留时间 |
| `scrape_interval` | 30s | 全局抓取间隔 |
| `evaluation_interval` | 30s | 规则评估间隔 |

### 资源配置

| 资源 | 请求 | 限制 |
|------|------|------|
| CPU | 100m | 500m |
| 内存 | 256Mi | 1Gi |

## 使用方法

### 基础使用

```hcl
module "prometheus" {
  source = "./modules/prometheus"
}
```

### 自定义配置

```hcl
module "prometheus" {
  source = "./modules/prometheus"

  namespace = "monitoring"
  retention = "30d"

  storage = {
    class = "fast-ssd"
    size  = "50Gi"
  }

  resources = {
    requests = {
      memory = "512Mi"
      cpu    = "200m"
    }
    limits = {
      memory = "2Gi"
      cpu    = "1000m"
    }
  }

  scrape_interval = "15s"
  evaluation_interval = "15s"
}
```

## 访问方式

### Web 界面

```bash
# 外部访问
http://<NODE_IP>:30090

# 端口转发（本地访问）
kubectl port-forward -n infra svc/prometheus 9090:9090
```

### API 访问

```bash
# 查询 API
curl http://<NODE_IP>:30090/api/v1/query?query=up

# 查看所有目标
curl http://<NODE_IP>:30090/api/v1/targets

# 查看告警
curl http://<NODE_IP>:30090/api/v1/alerts

# 查看规则
curl http://<NODE_IP>:30090/api/v1/rules
```

## 监控目标

### 自动发现

- ✅ Kubernetes API Server
- ✅ Kubernetes Nodes (Node Exporter)
- ✅ Kubernetes Pods (带 prometheus.io/scrape 注解)
- ✅ kube-state-metrics

### 预配置目标

- ✅ MongoDB (mongodb-metrics.infra:9216)
- ✅ Redis (redis-metrics.infra:9121)
- ✅ RabbitMQ (rabbitmq-metrics.infra:9419)
- ✅ Prometheus 自身 (localhost:9090)

## 告警规则

### 节点告警

| 告警名称 | 触发条件 | 严重级别 |
|---------|---------|----------|
| HighCPUUsage | CPU > 80% 持续 5 分钟 | warning |
| HighMemoryUsage | 内存 > 85% 持续 5 分钟 | warning |
| HighDiskUsage | 磁盘 > 85% 持续 5 分钟 | warning |
| NodeDown | 节点不可达超过 1 分钟 | critical |

### Pod 告警

| 告警名称 | 触发条件 | 严重级别 |
|---------|---------|----------|
| PodRestartingTooMuch | 1 小时内重启次数 > 0 | warning |
| PodFailed | Pod 处于 Failed 状态 | critical |
| PodPending | Pod Pending 超过 10 分钟 | warning |
| ContainerHighCPUUsage | 容器 CPU > 80% | warning |
| ContainerHighMemoryUsage | 容器内存 > 85% | warning |

### 数据库告警

| 告警名称 | 触发条件 | 严重级别 |
|---------|---------|----------|
| MongoDBHighConnections | 连接数 > 80% 最大值 | warning |
| RedisHighMemoryUsage | 内存使用 > 85% | warning |
| RabbitMQQueueTooManyMessages | 队列消息 > 1000 | warning |
| DatabaseServiceDown | 数据库服务不可用 | critical |

## 常用查询

### 系统指标

```promql
# CPU 使用率
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# 内存使用率
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# 磁盘使用率
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100

# 网络流量
rate(node_network_receive_bytes_total[5m])
rate(node_network_transmit_bytes_total[5m])
```

### Kubernetes 指标

```promql
# Pod 数量
count(kube_pod_info)

# Pod 重启次数
rate(kube_pod_container_status_restarts_total[1h])

# 容器 CPU 使用
rate(container_cpu_usage_seconds_total{container!="POD"}[5m])

# 容器内存使用
container_memory_usage_bytes{container!="POD"}

# PVC 使用率
kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes * 100
```

### 数据库指标

```promql
# MongoDB 连接数
mongodb_connections{state="current"}

# Redis 内存使用
redis_memory_used_bytes

# RabbitMQ 队列深度
rabbitmq_queue_messages
```

## 配置管理

### 添加新的抓取目标

编辑 `templates/values.yaml.tpl`：

```yaml
scrape_configs:
  - job_name: 'custom-app'
    static_configs:
      - targets: ['app.infra.svc.cluster.local:8080']
    metrics_path: /metrics
    scrape_interval: 30s
```

### 添加新的告警规则

编辑 `templates/alert-rules.yaml.tpl`：

```yaml
groups:
  - name: custom-alerts
    rules:
      - alert: CustomAlert
        expr: metric_name > threshold
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "自定义告警"
          description: "{{ $labels.instance }} 触发自定义告警"
```

## 运维管理

### 查看状态

```bash
# 查看 Pod 状态
kubectl get pods -n infra -l app.kubernetes.io/name=prometheus

# 查看日志
kubectl logs -f prometheus-0 -n infra

# 查看配置
kubectl exec -it prometheus-0 -n infra -- cat /opt/bitnami/prometheus/conf/prometheus.yml
```

### 重载配置

```bash
# 发送 SIGHUP 信号重载配置
kubectl exec -it prometheus-0 -n infra -- kill -HUP 1

# 或使用 API
curl -X POST http://<NODE_IP>:30090/-/reload
```

### 数据管理

```bash
# 查看存储使用
kubectl exec -it prometheus-0 -n infra -- df -h /opt/bitnami/prometheus/data

# 清理旧数据（谨慎使用）
kubectl exec -it prometheus-0 -n infra -- rm -rf /opt/bitnami/prometheus/data/*

# 查看 TSDB 状态
curl http://<NODE_IP>:30090/api/v1/label/__name__/values
```

## 性能调优

### 存储优化

```yaml
# 调整数据保留时间
retention: "7d"  # 减少保留时间

# 调整 TSDB 块大小
storage.tsdb.retention.size: "10GB"
```

### 抓取优化

```yaml
# 增加抓取间隔
scrape_interval: 60s

# 减少标签数量
metric_relabel_configs:
  - source_labels: [__name__]
    regex: 'go_.*'
    action: drop
```

### 资源优化

```bash
# 查看内存使用
kubectl exec -it prometheus-0 -n infra -- curl -s localhost:9090/api/v1/query?query=prometheus_tsdb_symbol_table_size_bytes

# 查看活跃序列数
kubectl exec -it prometheus-0 -n infra -- curl -s localhost:9090/api/v1/query?query=prometheus_tsdb_head_samples
```

## 故障排查

### 目标抓取失败

```bash
# 查看失败的目标
curl http://<NODE_IP>:30090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'

# 查看抓取错误
kubectl exec -it prometheus-0 -n infra -- tail -f /opt/bitnami/prometheus/logs/prometheus.log
```

### 告警不触发

```bash
# 检查告警规则
curl http://<NODE_IP>:30090/api/v1/rules | jq '.data.groups[].rules[] | select(.state == "pending")'

# 测试告警表达式
curl -g 'http://<NODE_IP>:30090/api/v1/query?query=up==0'
```

### 高内存使用

```bash
# 查看序列基数
curl http://<NODE_IP>:30090/api/v1/label/__name__/values | jq '. | length'

# 查看高基数标签
curl http://<NODE_IP>:30090/api/v1/query?query=prometheus_tsdb_symbol_table_size_bytes
```

## 备份与恢复

### 备份

```bash
# 创建快照
curl -X POST http://<NODE_IP>:30090/api/v1/admin/tsdb/snapshot

# 复制快照到本地
kubectl cp infra/prometheus-0:/opt/bitnami/prometheus/data/snapshots ./prometheus-backup
```

### 恢复

```bash
# 停止 Prometheus
kubectl scale statefulset prometheus -n infra --replicas=0

# 恢复数据
kubectl cp ./prometheus-backup infra/prometheus-0:/opt/bitnami/prometheus/data/

# 启动 Prometheus
kubectl scale statefulset prometheus -n infra --replicas=1
```

## 集成配置

### Grafana 集成

在 Grafana 中添加数据源：

```yaml
name: Prometheus
type: prometheus
url: http://prometheus.infra.svc.cluster.local:9090
access: proxy
isDefault: true
```

### Alertmanager 集成

Prometheus 已配置发送告警到：
```
http://alertmanager.infra.svc.cluster.local:9093
```

## 相关文档

- [Prometheus 官方文档](https://prometheus.io/docs/)
- [PromQL 查询语言](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Bitnami Prometheus Chart](https://github.com/bitnami/charts/tree/main/bitnami/prometheus)