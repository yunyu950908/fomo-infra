===========================================
Alertmanager 告警系统连接信息
===========================================

Web 界面访问：
-------------------
URL: http://NODE_IP:${alertmanager_port}
说明: Alertmanager 告警管理和静默设置界面

集群内部访问：
-------------------------------------
服务: ${release_name}.${namespace}.svc.cluster.local
端口: 9093

内部连接 URL：
http://${release_name}.${namespace}.svc.cluster.local:9093

CLI 访问：
-----------
# 端口转发进行本地访问：
kubectl port-forward -n ${namespace} svc/${release_name} 9093:9093

# 查看 Alertmanager 配置：
kubectl exec -it ${release_name}-0 -n ${namespace} -- cat /opt/bitnami/alertmanager/conf/alertmanager.yml

# 查看 Alertmanager 日志：
kubectl logs -f ${release_name}-0 -n ${namespace}

# 重载配置：
kubectl exec -it ${release_name}-0 -n ${namespace} -- kill -HUP 1

常用 API 端点：
-----------
# 查看所有告警
http://NODE_IP:${alertmanager_port}/api/v1/alerts

# 查看告警组
http://NODE_IP:${alertmanager_port}/api/v1/alerts/groups

# 查看静默规则
http://NODE_IP:${alertmanager_port}/api/v1/silences

# 查看接收器
http://NODE_IP:${alertmanager_port}/api/v1/receivers

# 查看状态
http://NODE_IP:${alertmanager_port}/api/v1/status

# 健康检查
http://NODE_IP:${alertmanager_port}/-/healthy

告警路由配置：
-----------
✓ 严重告警 (critical) - 5秒内发送，30分钟重复
✓ 节点告警 - CPU/内存/磁盘使用率过高，1小时重复
✓ 数据库告警 - MongoDB/Redis/RabbitMQ 相关，1小时重复
✓ Kubernetes 告警 - Pod失败/重启，30分钟重复
✓ 存储告警 - 磁盘空间/PV 问题，2小时重复
✓ 网络告警 - 网络错误率过高，2小时重复

通知渠道配置：
-----------
支持的通知方式：
- 📧 邮件通知 (SMTP)
- 🔗 Webhook 通知
- 💬 Slack 通知
- 🏢 企业微信通知

邮件模板格式：
- HTML 格式，包含告警详细信息
- 严重告警使用红色警告样式
- 按告警类型分组显示

告警抑制规则：
-----------
✓ 节点宕机时抑制该节点其他告警
✓ 严重告警抑制相同实例的警告告警
✓ Pod失败时抑制容器相关告警
✓ 数据库服务不可用时抑制性能告警
✓ 磁盘使用率过高时抑制 I/O 告警

静默管理：
-----------
# 通过 Web 界面创建静默：
1. 访问 http://NODE_IP:${alertmanager_port}
2. 点击 "New Silence"
3. 设置匹配器和持续时间
4. 添加注释说明原因

# 通过 API 创建静默：
curl -X POST http://NODE_IP:${alertmanager_port}/api/v1/silences \
  -H "Content-Type: application/json" \
  -d '{
    "matchers": [
      {
        "name": "alertname",
        "value": "HighCPUUsage",
        "isRegex": false
      }
    ],
    "startsAt": "2024-01-01T00:00:00Z",
    "endsAt": "2024-01-01T01:00:00Z",
    "comment": "维护期间静默CPU告警"
  }'

常用命令：
-----------
# 查看当前所有告警
curl -s http://NODE_IP:${alertmanager_port}/api/v1/alerts | jq '.data[] | {alertname: .labels.alertname, status: .status.state, instance: .labels.instance}'

# 查看活跃告警数量
curl -s http://NODE_IP:${alertmanager_port}/api/v1/alerts | jq '.data | map(select(.status.state == "active")) | length'

# 查看静默规则
curl -s http://NODE_IP:${alertmanager_port}/api/v1/silences | jq '.data[] | {id: .id, comment: .comment, matchers: .matchers}'

# 删除静默规则
curl -X DELETE http://NODE_IP:${alertmanager_port}/api/v1/silence/<silence-id>

告警测试：
-----------
# 发送测试告警到 Alertmanager
curl -X POST http://NODE_IP:${alertmanager_port}/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[
    {
      "labels": {
        "alertname": "TestAlert",
        "severity": "warning",
        "instance": "test-instance"
      },
      "annotations": {
        "summary": "这是一个测试告警",
        "description": "用于测试 Alertmanager 配置是否正常"
      },
      "generatorURL": "http://prometheus:9090/graph"
    }
  ]'

配置验证：
-----------
# 验证配置文件语法
kubectl exec -it ${release_name}-0 -n ${namespace} -- amtool config check /opt/bitnami/alertmanager/conf/alertmanager.yml

# 验证路由配置
kubectl exec -it ${release_name}-0 -n ${namespace} -- amtool config routes test --config.file=/opt/bitnami/alertmanager/conf/alertmanager.yml

# 查看配置信息
kubectl exec -it ${release_name}-0 -n ${namespace} -- amtool config show --config.file=/opt/bitnami/alertmanager/conf/alertmanager.yml

故障排查：
-----------
# 查看服务状态
kubectl get pods -n ${namespace} -l app.kubernetes.io/name=alertmanager

# 查看详细日志
kubectl logs -f ${release_name}-0 -n ${namespace}

# 查看配置加载状态
kubectl exec -it ${release_name}-0 -n ${namespace} -- wget -qO- http://localhost:9093/-/healthy

# 重载配置文件
kubectl exec -it ${release_name}-0 -n ${namespace} -- kill -HUP \$(pgrep alertmanager)

# 检查告警接收情况
kubectl exec -it ${release_name}-0 -n ${namespace} -- amtool alert --alertmanager.url=http://localhost:9093

性能监控：
-----------
数据保留: 120小时 (5天)
资源限制: 256Mi 内存, 100m CPU
告警分组: 按 alertname, cluster, service 分组
通知间隔: 严重告警30分钟，警告告警1小时

集成 Prometheus：
-----------
在 Prometheus 配置中添加：
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - "${release_name}.${namespace}.svc.cluster.local:9093"

重要注意事项：
-----------
⚠️ 请根据实际需求配置邮件 SMTP 服务器信息
⚠️ 企业微信需要配置应用密钥和企业ID
⚠️ Slack 需要创建 Incoming Webhook URL
⚠️ 建议在生产环境前先测试告警通知功能
⚠️ 定期检查告警规则是否符合当前业务需求