===========================================
Redis 连接信息
===========================================

外部连接：
--------------------
主机: NODE_IP
端口: ${redis_port}
密码: ${password}

Redis CLI 连接：
redis-cli -h NODE_IP -p ${redis_port} -a ${password}

连接 URL：
redis://:${password}@NODE_IP:${redis_port}

集群内部连接：
-------------------------------------
服务: ${release_name}.${namespace}.svc.cluster.local
端口: 6379

内部连接 URL：
redis://:${password}@${release_name}.${namespace}.svc.cluster.local:6379

应用程序配置示例：
-----------------------------------

Node.js (ioredis):
------------------
const Redis = require('ioredis');

// 外部连接
const redis = new Redis({
  host: 'NODE_IP',
  port: ${redis_port},
  password: '${password}'
});

// 内部连接
const redis = new Redis({
  host: '${release_name}.${namespace}.svc.cluster.local',
  port: 6379,
  password: '${password}'
});

Python (redis-py):
-----------------
import redis

# 外部连接
r = redis.Redis(
  host='NODE_IP',
  port=${redis_port},
  password='${password}',
  decode_responses=True
)

# 内部连接
r = redis.Redis(
  host='${release_name}.${namespace}.svc.cluster.local',
  port=6379,
  password='${password}',
  decode_responses=True
)

Go (go-redis):
------------------
import "github.com/go-redis/redis/v8"

// 外部连接
rdb := redis.NewClient(&redis.Options{
    Addr:     "NODE_IP:${redis_port}",
    Password: "${password}",
    DB:       0,
})

// 内部连接
rdb := redis.NewClient(&redis.Options{
    Addr:     "${release_name}.${namespace}.svc.cluster.local:6379",
    Password: "${password}",
    DB:       0,
})

Java (Jedis):
-------------------
import redis.clients.jedis.Jedis;

// 外部连接
Jedis jedis = new Jedis("NODE_IP", ${redis_port});
jedis.auth("${password}");

// 内部连接
Jedis jedis = new Jedis("${release_name}.${namespace}.svc.cluster.local", 6379);
jedis.auth("${password}");

Spring Boot:
-------------------
# application.yml
spring:
  redis:
    host: ${release_name}.${namespace}.svc.cluster.local
    port: 6379
    password: ${password}
    timeout: 2000ms
    lettuce:
      pool:
        max-active: 8
        max-idle: 8
        min-idle: 0

CLI 访问：
-----------
# 端口转发进行本地访问：
kubectl port-forward -n ${namespace} svc/${release_name} 6379:6379

# 连接 redis-cli：
redis-cli -h localhost -p 6379 -a ${password}

# 直接执行命令：
kubectl exec -it ${release_name}-0 -n ${namespace} -- redis-cli -a ${password} INFO

# 实时监控：
kubectl exec -it ${release_name}-0 -n ${namespace} -- redis-cli -a ${password} --stat

常用 Redis 命令：
-----------
# 查看信息
INFO

# 查看内存使用
INFO memory

# 查看连接的客户端
CLIENT LIST

# 查看所有键
KEYS *

# 查看数据库大小
DBSIZE

# 清空当前数据库
FLUSHDB

# 清空所有数据库
FLUSHALL

# 查看配置
CONFIG GET *

性能优化建议：
-----------
架构: ${architecture}
内存策略: allkeys-lru（内存不足时删除最近最少使用的键）
持久化: AOF 模式（更安全）
连接池: 建议使用连接池避免频繁连接创建

监控指标：
-----------
# 查看内存使用情况
kubectl exec -it ${release_name}-0 -n ${namespace} -- redis-cli -a ${password} INFO memory

# 查看命中率
kubectl exec -it ${release_name}-0 -n ${namespace} -- redis-cli -a ${password} INFO stats