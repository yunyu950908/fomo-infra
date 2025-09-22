===========================================
RabbitMQ 连接信息
===========================================

管理控制台：
-------------------
URL: http://NODE_IP:${management_port}
用户名: ${username}
密码: ${password}

AMQP 连接（外部）：
---------------------------
主机: NODE_IP
端口: ${amqp_port}
虚拟主机: ${virtual_host}
用户名: ${username}
密码: ${password}

连接 URL：
amqp://${username}:${password}@NODE_IP:${amqp_port}${virtual_host}

集群内部连接：
-------------------------------------
服务: ${release_name}.${namespace}.svc.cluster.local
AMQP 端口: 5672
管理端口: 15672

内部连接 URL：
amqp://${username}:${password}@${release_name}.${namespace}.svc.cluster.local:5672${virtual_host}

应用程序配置示例：
-----------------------------------

Node.js (amqplib):
------------------
const amqp = require('amqplib');

// 外部连接
const connection = await amqp.connect('amqp://${username}:${password}@NODE_IP:${amqp_port}${virtual_host}');

// 内部连接
const connection = await amqp.connect('amqp://${username}:${password}@${release_name}.${namespace}.svc.cluster.local:5672${virtual_host}');

Python (pika):
-----------------
import pika

# 外部连接
credentials = pika.PlainCredentials('${username}', '${password}')
parameters = pika.ConnectionParameters('NODE_IP', ${amqp_port}, '${virtual_host}', credentials)
connection = pika.BlockingConnection(parameters)

# 内部连接
parameters = pika.ConnectionParameters('${release_name}.${namespace}.svc.cluster.local', 5672, '${virtual_host}', credentials)

Go (amqp091-go):
------------------
import "github.com/rabbitmq/amqp091-go"

// 外部连接
conn, err := amqp.Dial("amqp://${username}:${password}@NODE_IP:${amqp_port}${virtual_host}")

// 内部连接
conn, err := amqp.Dial("amqp://${username}:${password}@${release_name}.${namespace}.svc.cluster.local:5672${virtual_host}")

Java (Spring AMQP):
-------------------
# application.yml
spring:
  rabbitmq:
    host: ${release_name}.${namespace}.svc.cluster.local
    port: 5672
    username: ${username}
    password: ${password}
    virtual-host: ${virtual_host}

CLI 访问：
-----------
# 端口转发进行本地访问：
kubectl port-forward -n ${namespace} svc/${release_name} 5672:5672 15672:15672

# 执行 rabbitmqctl 命令：
kubectl exec -it ${release_name}-0 -n ${namespace} -- rabbitmqctl status

# 访问 RabbitMQ shell：
kubectl exec -it ${release_name}-0 -n ${namespace} -- bash

常用管理命令：
-----------
# 列出队列
kubectl exec -it ${release_name}-0 -n ${namespace} -- rabbitmqctl list_queues

# 列出交换器
kubectl exec -it ${release_name}-0 -n ${namespace} -- rabbitmqctl list_exchanges

# 列出绑定
kubectl exec -it ${release_name}-0 -n ${namespace} -- rabbitmqctl list_bindings

# 查看集群状态
kubectl exec -it ${release_name}-0 -n ${namespace} -- rabbitmqctl cluster_status