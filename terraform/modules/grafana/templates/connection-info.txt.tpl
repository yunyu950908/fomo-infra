===========================================
Grafana 可视化系统连接信息
===========================================

Web 界面访问：
-------------------
URL: http://NODE_IP:${grafana_port}
用户名: ${admin_username}
密码: ${admin_password}

集群内部访问：
-------------------------------------
服务: ${release_name}.${namespace}.svc.cluster.local
端口: 3000

内部连接 URL：
http://${release_name}.${namespace}.svc.cluster.local:3000

CLI 访问：
-----------
# 端口转发进行本地访问：
kubectl port-forward -n ${namespace} svc/${release_name} 3000:3000

# 查看 Grafana 配置：
kubectl exec -it ${release_name}-0 -n ${namespace} -- cat /opt/bitnami/grafana/conf/grafana.ini

# 查看 Grafana 日志：
kubectl logs -f ${release_name}-0 -n ${namespace}

# 重启 Grafana：
kubectl rollout restart deployment/${release_name} -n ${namespace}

常用 API 端点：
-----------
# 健康检查
http://NODE_IP:${grafana_port}/api/health

# 组织信息
http://NODE_IP:${grafana_port}/api/org

# 数据源列表
http://NODE_IP:${grafana_port}/api/datasources

# 仪表板搜索
http://NODE_IP:${grafana_port}/api/search

# 用户信息
http://NODE_IP:${grafana_port}/api/user

预配置数据源：
-----------
✓ Prometheus (默认数据源)
  - URL: http://prometheus.monitoring.svc.cluster.local:9090
  - 类型: Prometheus
  - 查询超时: 30秒

✓ TestData (测试数据源)
  - 用于测试和演示

推荐仪表板：
-----------
系统监控：
- Node Exporter Full (ID: 1860)
- Kubernetes Cluster Monitoring (ID: 7249)
- Kubernetes Pod Monitoring (ID: 6417)

数据库监控：
- MongoDB Overview (ID: 2583)
- Redis Dashboard (ID: 763)
- RabbitMQ Overview (ID: 10991)

应用监控：
- Prometheus Stats (ID: 2)
- Prometheus 2.0 Stats (ID: 3662)

安装仪表板：
-----------
方法一: 通过 ID 导入
1. 点击 "+" -> "Import"
2. 输入仪表板 ID (如: 1860)
3. 点击 "Load" -> "Import"

方法二: 通过 JSON 导入
1. 从 https://grafana.com/grafana/dashboards/ 下载 JSON
2. 点击 "+" -> "Import"
3. 上传 JSON 文件或粘贴内容

方法三: 从 URL 导入
1. 点击 "+" -> "Import"
2. 输入仪表板 URL
3. 点击 "Load" -> "Import"

告警配置：
-----------
# 创建告警规则：
1. 进入仪表板面板
2. 点击面板标题 -> "Edit"
3. 切换到 "Alert" 选项卡
4. 配置告警条件和通知

# 通知渠道配置：
1. 设置 -> "Notification channels"
2. 添加邮件、Slack、Webhook 等渠道
3. 测试通知渠道

常用查询示例：
-----------
# 节点 CPU 使用率
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# 节点内存使用率
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# 磁盘使用率
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100

# Pod CPU 使用率
rate(container_cpu_usage_seconds_total{container!="POD"}[5m]) * 100

# Pod 内存使用率
container_memory_usage_bytes{container!="POD"} / container_spec_memory_limit_bytes * 100

# MongoDB 连接数
mongodb_connections{state="current"}

# Redis 内存使用
redis_memory_used_bytes

# RabbitMQ 队列消息数
rabbitmq_queue_messages

性能优化建议：
-----------
存储: 5Gi (适合单节点环境)
资源限制: 512Mi 内存, 250m CPU
查询超时: 30秒
刷新间隔: 建议设置为 30s-1m

插件管理：
-----------
已安装插件:
- grafana-piechart-panel (饼图面板)
- grafana-worldmap-panel (世界地图面板)
- grafana-clock-panel (时钟面板)

安装新插件：
kubectl exec -it ${release_name}-0 -n ${namespace} -- grafana-cli plugins install <plugin-name>
kubectl rollout restart deployment/${release_name} -n ${namespace}

故障排查：
-----------
# 查看服务状态
kubectl get pods -n ${namespace} -l app.kubernetes.io/name=grafana

# 查看详细日志
kubectl logs -f ${release_name}-0 -n ${namespace}

# 查看配置是否正确
kubectl exec -it ${release_name}-0 -n ${namespace} -- grafana-cli admin reset-admin-password newpassword

# 检查数据源连接
kubectl exec -it ${release_name}-0 -n ${namespace} -- curl -s http://prometheus.monitoring.svc.cluster.local:9090/api/v1/query?query=up

# 清理缓存和重启
kubectl exec -it ${release_name}-0 -n ${namespace} -- rm -rf /opt/bitnami/grafana/data/cache/*
kubectl rollout restart deployment/${release_name} -n ${namespace}

备份与恢复：
-----------
# 备份仪表板和数据源
kubectl exec -it ${release_name}-0 -n ${namespace} -- tar czf /tmp/grafana-backup.tar.gz /opt/bitnami/grafana/data

# 复制备份文件
kubectl cp ${namespace}/${release_name}-0:/tmp/grafana-backup.tar.gz ./grafana-backup.tar.gz

# 恢复数据
kubectl cp ./grafana-backup.tar.gz ${namespace}/${release_name}-0:/tmp/
kubectl exec -it ${release_name}-0 -n ${namespace} -- tar xzf /tmp/grafana-backup.tar.gz -C /