# RabbitMQ 模块

基于 Bitnami Helm Chart 的 RabbitMQ 3.13 消息队列，针对单节点 4C8G 环境优化。

## 特性

- **版本**: RabbitMQ 3.13
- **架构**: 单节点（可启用集群）
- **存储**: 8Gi 持久化存储
- **管理界面**: 启用 Web 管理控制台
- **外部访问**: AMQP 30672, 管理界面 31672
- **插件**: rabbitmq_management

## 配置参数

| 参数 | 默认值 | 说明 |
|-----|--------|------|
| `namespace` | infra | 部署命名空间 |
| `release_name` | rabbitmq | Helm 发布名称 |
| `rabbitmq_version` | 3.13 | RabbitMQ 版本 |
| `replica_count` | 1 | 节点数量 |
| `external_ports.amqp` | 30672 | AMQP NodePort |
| `external_ports.management` | 31672 | 管理界面 NodePort |
| `storage.size` | 8Gi | 存储大小 |
| `default_vhost` | / | 默认虚拟主机 |

### 认证配置

| 参数 | 默认值 | 说明 |
|-----|--------|------|
| `auth.username` | admin | 管理员用户名 |
| `auth.password` | RabbitAdmin2024! | 管理员密码 |
| `auth.erlang_cookie` | secreterlangcookie2024 | Erlang Cookie |

### 资源配置

| 资源 | 请求 | 限制 |
|------|------|------|
| CPU | 200m | 750m |
| 内存 | 512Mi | 1.5Gi |

## 使用方法

### 基础使用

```hcl
module "rabbitmq" {
  source = "./modules/rabbitmq"
}
```

### 自定义配置

```hcl
module "rabbitmq" {
  source = "./modules/rabbitmq"

  namespace = "messaging"
  rabbitmq_version = "3.13"

  # 启用集群
  replica_count = 3
  clustering = {
    enabled = true
  }

  auth = {
    username      = "admin"
    password      = var.rabbitmq_password
    erlang_cookie = var.erlang_cookie
  }

  storage = {
    class = "fast-ssd"
    size  = "20Gi"
  }

  resources = {
    requests = {
      memory = "1Gi"
      cpu    = "500m"
    }
    limits = {
      memory = "2Gi"
      cpu    = "1000m"
    }
  }

  # 内存高水位
  memory_high_watermark = 0.5
}
```

## 访问方式

### 管理界面

```bash
# Web 管理控制台
http://<NODE_IP>:31672

# 登录凭据
用户名: admin
密码: RabbitAdmin2024!
```

### AMQP 连接

#### 外部连接

```bash
# AMQP URL
amqp://admin:RabbitAdmin2024!@<NODE_IP>:30672/

# 带虚拟主机
amqp://admin:RabbitAdmin2024!@<NODE_IP>:30672/%2F
```

#### 内部连接

```bash
# Kubernetes 内部
amqp://admin:RabbitAdmin2024!@rabbitmq.infra.svc.cluster.local:5672/
```

### 编程语言示例

#### Node.js (amqplib)

```javascript
const amqp = require('amqplib');

// 外部连接
const connection = await amqp.connect('amqp://admin:RabbitAdmin2024!@<NODE_IP>:30672');

// 内部连接
const connection = await amqp.connect('amqp://admin:RabbitAdmin2024!@rabbitmq.infra.svc.cluster.local:5672');

// 创建通道
const channel = await connection.createChannel();

// 声明队列
await channel.assertQueue('task_queue', { durable: true });

// 发送消息
channel.sendToQueue('task_queue', Buffer.from('Hello World'));

// 消费消息
channel.consume('task_queue', (msg) => {
  console.log("Received:", msg.content.toString());
  channel.ack(msg);
});
```

#### Python (pika)

```python
import pika

# 外部连接
credentials = pika.PlainCredentials('admin', 'RabbitAdmin2024!')
parameters = pika.ConnectionParameters('<NODE_IP>', 30672, '/', credentials)

# 内部连接
parameters = pika.ConnectionParameters('rabbitmq.infra.svc.cluster.local', 5672, '/', credentials)

connection = pika.BlockingConnection(parameters)
channel = connection.channel()

# 声明队列
channel.queue_declare(queue='task_queue', durable=True)

# 发送消息
channel.basic_publish(
    exchange='',
    routing_key='task_queue',
    body='Hello World',
    properties=pika.BasicProperties(delivery_mode=2)
)

# 消费消息
def callback(ch, method, properties, body):
    print(f"Received: {body}")
    ch.basic_ack(delivery_tag=method.delivery_tag)

channel.basic_consume(queue='task_queue', on_message_callback=callback)
channel.start_consuming()
```

#### Go (amqp091-go)

```go
import "github.com/rabbitmq/amqp091-go"

// 外部连接
conn, err := amqp.Dial("amqp://admin:RabbitAdmin2024!@<NODE_IP>:30672/")

// 内部连接
conn, err := amqp.Dial("amqp://admin:RabbitAdmin2024!@rabbitmq.infra.svc.cluster.local:5672/")

// 创建通道
ch, err := conn.Channel()

// 声明队列
q, err := ch.QueueDeclare(
    "task_queue", // name
    true,         // durable
    false,        // delete when unused
    false,        // exclusive
    false,        // no-wait
    nil,          // arguments
)

// 发送消息
err = ch.Publish(
    "",           // exchange
    q.Name,       // routing key
    false,        // mandatory
    false,        // immediate
    amqp.Publishing{
        ContentType: "text/plain",
        Body:        []byte("Hello World"),
    })
```

#### Spring Boot

```yaml
spring:
  rabbitmq:
    host: rabbitmq.infra.svc.cluster.local
    port: 5672
    username: admin
    password: RabbitAdmin2024!
    virtual-host: /
    connection-timeout: 5000
    publisher-confirms: true
    publisher-returns: true
```

## 常用命令

### 管理命令

```bash
# 进入 RabbitMQ Pod
kubectl exec -it rabbitmq-0 -n infra -- bash

# 查看状态
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl status

# 查看集群状态
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl cluster_status

# 列出用户
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl list_users

# 列出虚拟主机
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl list_vhosts

# 列出权限
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl list_permissions
```

### 队列管理

```bash
# 列出队列
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl list_queues name messages consumers

# 查看队列详情
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl list_queues name messages_ready messages_unacknowledged

# 清空队列
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl purge_queue queue_name

# 删除队列
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl delete_queue queue_name
```

### 交换器和绑定

```bash
# 列出交换器
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl list_exchanges

# 列出绑定
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl list_bindings

# 创建交换器
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqadmin declare exchange name=my_exchange type=topic
```

### 连接和通道

```bash
# 查看连接
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl list_connections

# 查看通道
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl list_channels

# 关闭连接
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl close_connection "<connection_name>"
```

## 运维管理

### 查看状态

```bash
# 查看 Pod 状态
kubectl get pods -n infra -l app.kubernetes.io/name=rabbitmq

# 查看日志
kubectl logs -f rabbitmq-0 -n infra

# 查看资源使用
kubectl top pod rabbitmq-0 -n infra
```

### 用户管理

```bash
# 添加用户
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl add_user myuser mypassword

# 设置用户标签（管理员）
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl set_user_tags myuser administrator

# 设置权限
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl set_permissions -p / myuser ".*" ".*" ".*"

# 修改密码
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl change_password myuser newpassword

# 删除用户
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl delete_user myuser
```

### 虚拟主机管理

```bash
# 创建虚拟主机
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl add_vhost myvhost

# 设置虚拟主机权限
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl set_permissions -p myvhost admin ".*" ".*" ".*"

# 删除虚拟主机
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl delete_vhost myvhost
```

## 性能优化

### 内存管理

```bash
# 查看内存使用
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl status | grep -A 10 memory

# 设置内存高水位（40%）
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl set_vm_memory_high_watermark 0.4

# 查看内存报警状态
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl list_connections name peer_host peer_port state | grep blocking
```

### 消息持久化

```javascript
// 持久化队列
channel.assertQueue('durable_queue', { durable: true });

// 持久化消息
channel.sendToQueue('durable_queue', Buffer.from(msg), { persistent: true });
```

### 消费者确认

```javascript
// 手动确认模式
channel.consume('queue', (msg) => {
  // 处理消息
  processMessage(msg);
  // 确认消息
  channel.ack(msg);
}, { noAck: false });
```

### 预取设置

```javascript
// 设置预取数量
channel.prefetch(10); // 每次最多处理10条消息
```

## 监控指标

### 关键指标

```bash
# 队列深度
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl list_queues | awk '{sum+=$2} END {print "Total messages:", sum}'

# 消费者数量
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl list_queues name consumers

# 发布/消费速率
# 需要通过管理界面或 API 查看
```

### Prometheus 指标

如果启用了 metrics：

```promql
# 队列消息数
rabbitmq_queue_messages

# 队列消费者数
rabbitmq_queue_consumers

# 连接数
rabbitmq_connections

# 通道数
rabbitmq_channels

# 节点内存使用
rabbitmq_node_mem_used
```

## 故障排查

### 连接问题

```bash
# 测试网络连接
kubectl exec -it rabbitmq-0 -n infra -- nc -zv localhost 5672

# 检查服务
kubectl get svc -n infra | grep rabbitmq

# 查看监听端口
kubectl exec -it rabbitmq-0 -n infra -- netstat -tlnp | grep beam
```

### 队列积压

```bash
# 查找积压队列
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl list_queues name messages | awk '$2 > 1000'

# 查看队列消费者
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl list_queues name consumers | grep " 0$"

# 强制清空队列
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl purge_queue queue_name
```

### 内存问题

```bash
# 查看内存报警
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl eval 'rabbit_alarm:get_alarms().'

# 查看内存使用详情
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl status | grep -A 20 "{memory,"

# 强制垃圾回收
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl eval 'erlang:garbage_collect().'
```

### 集群问题

```bash
# 查看集群节点
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl cluster_status

# 重置节点
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl reset

# 重新加入集群
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl join_cluster rabbit@rabbitmq-1.rabbitmq.infra.svc.cluster.local
```

## 备份与恢复

### 导出定义

```bash
# 导出所有定义（用户、虚拟主机、权限、队列等）
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl export_definitions /tmp/definitions.json

# 复制到本地
kubectl cp infra/rabbitmq-0:/tmp/definitions.json ./rabbitmq-definitions.json
```

### 导入定义

```bash
# 复制定义文件到 Pod
kubectl cp ./rabbitmq-definitions.json infra/rabbitmq-0:/tmp/definitions.json

# 导入定义
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl import_definitions /tmp/definitions.json
```

## 安全建议

1. **更改默认密码**: 生产环境必须修改默认凭据
2. **启用 TLS**: 配置 SSL/TLS 加密连接
3. **限制权限**: 为不同应用创建专用用户
4. **网络隔离**: 使用 NetworkPolicy 限制访问
5. **定期备份**: 备份队列定义和消息

### 创建应用用户

```bash
# 创建只读用户
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl add_user reader readpass
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl set_permissions -p / reader "" "" ".*"

# 创建生产者用户
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl add_user producer prodpass
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl set_permissions -p / producer ".*" "" ""

# 创建消费者用户
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl add_user consumer conspass
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl set_permissions -p / consumer "" ".*" ""
```

## 高可用配置

### 镜像队列（已弃用）

RabbitMQ 3.8+ 推荐使用 Quorum 队列：

```javascript
// 创建 Quorum 队列
channel.assertQueue('quorum-queue', {
  durable: true,
  arguments: {
    'x-queue-type': 'quorum'
  }
});
```

### 集群配置

```bash
# 查看集群健康状态
kubectl exec -it rabbitmq-0 -n infra -- rabbitmq-diagnostics check_running

# 执行健康检查
kubectl exec -it rabbitmq-0 -n infra -- rabbitmq-diagnostics check_local_alarms
```

## 升级指南

```bash
# 导出配置
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl export_definitions /tmp/backup.json

# 更新版本
# 修改 variables.tf 中的 rabbitmq_version

# 应用更新
terraform apply -target=module.rabbitmq

# 验证版本
kubectl exec -it rabbitmq-0 -n infra -- rabbitmqctl version
```

## 相关文档

- [RabbitMQ 官方文档](https://www.rabbitmq.com/documentation.html)
- [RabbitMQ 管理指南](https://www.rabbitmq.com/admin-guide.html)
- [Bitnami RabbitMQ Chart](https://github.com/bitnami/charts/tree/main/bitnami/rabbitmq)
- [RabbitMQ 最佳实践](https://www.rabbitmq.com/production-checklist.html)