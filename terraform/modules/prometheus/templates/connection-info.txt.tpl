===========================================
Prometheus 监控系统连接信息
===========================================

Web 界面访问：
-------------------
URL: http://NODE_IP:${prometheus_port}
说明: Prometheus 查询和规则管理界面

集群内部访问：
-------------------------------------
服务: ${release_name}.${namespace}.svc.cluster.local
端口: 9090

内部连接 URL：
http://${release_name}.${namespace}.svc.cluster.local:9090

CLI 访问：
-----------
# 端口转发进行本地访问：
kubectl port-forward -n ${namespace} svc/${release_name} 9090:9090

# 查看 Prometheus 配置：
kubectl exec -it ${release_name}-0 -n ${namespace} -- cat /opt/bitnami/prometheus/conf/prometheus.yml

# 查看告警规则：
kubectl exec -it ${release_name}-0 -n ${namespace} -- cat /opt/bitnami/prometheus/conf/alert-rules.yaml

# 重载配置：
kubectl exec -it ${release_name}-0 -n ${namespace} -- kill -HUP 1

常用 API 端点：
-----------
# 查询 API
http://NODE_IP:${prometheus_port}/api/v1/query?query=up

# 范围查询
http://NODE_IP:${prometheus_port}/api/v1/query_range?query=up&start=2024-01-01T00:00:00Z&end=2024-01-01T01:00:00Z&step=15s

# 查看所有目标
http://NODE_IP:${prometheus_port}/api/v1/targets

# 查看告警状态
http://NODE_IP:${prometheus_port}/api/v1/alerts

# 查看规则
http://NODE_IP:${prometheus_port}/api/v1/rules

监控目标：
-----------
✓ Kubernetes API Server
✓ Kubernetes Nodes (通过 Node Exporter)
✓ Kubernetes Pods (自动发现)
✓ kube-state-metrics (Kubernetes 对象状态)
✓ MongoDB (如果启用 metrics)
✓ Redis (如果启用 metrics)
✓ RabbitMQ (如果启用 metrics)
✓ Prometheus 自身

重要指标查询：
-----------
# 节点 CPU 使用率
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# 节点内存使用率
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# 磁盘使用率
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100

# Pod 重启次数
rate(kube_pod_container_status_restarts_total[1h])

# 容器 CPU 使用率
rate(container_cpu_usage_seconds_total{container!="POD"}[5m]) * 100

# 容器内存使用率
container_memory_usage_bytes{container!="POD"} / container_spec_memory_limit_bytes * 100

告警配置：
-----------
告警规则文件: /opt/bitnami/prometheus/conf/alert-rules.yaml
Alertmanager: ${namespace}/alertmanager:9093

主要告警规则：
- 节点资源使用率过高 (CPU>80%, Memory>85%, Disk>85%)
- Pod 频繁重启或失败状态
- 数据库服务不可用
- 存储使用率过高
- 网络错误率过高

性能优化建议：
-----------
数据保留: 15天 (节省存储空间)
抓取间隔: 30秒 (平衡精度和资源消耗)
存储: 15Gi (适合单节点环境)
资源限制: 1Gi 内存, 500m CPU

故障排查：
-----------
# 查看 Prometheus 日志
kubectl logs -f ${release_name}-0 -n ${namespace}

# 查看存储使用情况
kubectl exec -it ${release_name}-0 -n ${namespace} -- df -h

# 查看配置是否正确
kubectl exec -it ${release_name}-0 -n ${namespace} -- /opt/bitnami/prometheus/bin/promtool check config /opt/bitnami/prometheus/conf/prometheus.yml

# 查看规则是否正确
kubectl exec -it ${release_name}-0 -n ${namespace} -- /opt/bitnami/prometheus/bin/promtool check rules /opt/bitnami/prometheus/conf/alert-rules.yaml