# Redis 模块

基于 Bitnami Helm Chart 的 Redis 7.2 内存数据库，针对单节点 4C8G 环境优化。

## 特性

- **版本**: Redis 7.2
- **架构**: 单节点（可启用主从复制）
- **存储**: 5Gi 持久化存储
- **认证**: 密码保护
- **外部访问**: NodePort 30379
- **内存策略**: allkeys-lru

## 配置参数

| 参数 | 默认值 | 说明 |
|-----|--------|------|
| `namespace` | infra | 部署命名空间 |
| `release_name` | redis | Helm 发布名称 |
| `redis_version` | 7.2 | Redis 版本 |
| `architecture` | standalone | 架构模式 |
| `external_ports.redis` | 30379 | NodePort 端口 |
| `storage.size` | 5Gi | 存储大小 |
| `max_memory_policy` | allkeys-lru | 内存淘汰策略 |

### 认证配置

| 参数 | 默认值 | 说明 |
|-----|--------|------|
| `auth.enabled` | true | 启用认证 |
| `auth.password` | RedisSecure2024! | 认证密码 |

### 资源配置

| 资源 | 请求 | 限制 |
|------|------|------|
| CPU | 100m | 500m |
| 内存 | 256Mi | 1Gi |

## 使用方法

### 基础使用

```hcl
module "redis" {
  source = "./modules/redis"
}
```

### 自定义配置

```hcl
module "redis" {
  source = "./modules/redis"

  namespace = "databases"
  redis_version = "7.2"

  # 启用主从复制
  architecture = "replication"

  replica = {
    enabled = true
    count   = 2
  }

  # 启用哨兵
  sentinel = {
    enabled = true
  }

  auth = {
    enabled  = true
    password = var.redis_password
  }

  storage = {
    class = "fast-ssd"
    size  = "10Gi"
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
}
```

## 连接信息

### 外部连接

```bash
# Redis CLI
redis-cli -h <NODE_IP> -p 30379 -a RedisSecure2024!

# 连接 URL
redis://:RedisSecure2024!@<NODE_IP>:30379
```

### 内部连接

```bash
# Kubernetes 内部
redis-cli -h redis.infra.svc.cluster.local -p 6379 -a RedisSecure2024!

# 连接 URL
redis://:RedisSecure2024!@redis.infra.svc.cluster.local:6379
```

### 编程语言示例

#### Node.js (ioredis)

```javascript
const Redis = require('ioredis');

// 外部连接
const redis = new Redis({
  host: '<NODE_IP>',
  port: 30379,
  password: 'RedisSecure2024!'
});

// 内部连接
const redis = new Redis({
  host: 'redis.infra.svc.cluster.local',
  port: 6379,
  password: 'RedisSecure2024!'
});
```

#### Python (redis-py)

```python
import redis

# 外部连接
r = redis.Redis(
  host='<NODE_IP>',
  port=30379,
  password='RedisSecure2024!',
  decode_responses=True
)

# 内部连接
r = redis.Redis(
  host='redis.infra.svc.cluster.local',
  port=6379,
  password='RedisSecure2024!',
  decode_responses=True
)
```

#### Go (go-redis)

```go
import "github.com/go-redis/redis/v8"

// 外部连接
rdb := redis.NewClient(&redis.Options{
    Addr:     "<NODE_IP>:30379",
    Password: "RedisSecure2024!",
    DB:       0,
})

// 内部连接
rdb := redis.NewClient(&redis.Options{
    Addr:     "redis.infra.svc.cluster.local:6379",
    Password: "RedisSecure2024!",
    DB:       0,
})
```

#### Spring Boot

```yaml
spring:
  redis:
    host: redis.infra.svc.cluster.local
    port: 6379
    password: RedisSecure2024!
    timeout: 2000ms
    lettuce:
      pool:
        max-active: 8
        max-idle: 8
        min-idle: 0
```

## 常用命令

### 基础操作

```bash
# 连接 Redis
kubectl exec -it redis-master-0 -n infra -- redis-cli -a RedisSecure2024!

# 查看信息
INFO

# 查看所有键
KEYS *

# 查看内存使用
INFO memory

# 查看连接的客户端
CLIENT LIST

# 查看配置
CONFIG GET *

# 数据库大小
DBSIZE
```

### 性能监控

```bash
# 实时监控
kubectl exec -it redis-master-0 -n infra -- redis-cli -a RedisSecure2024! --stat

# 监控延迟
kubectl exec -it redis-master-0 -n infra -- redis-cli -a RedisSecure2024! --latency

# 查看慢查询
SLOWLOG GET 10

# 监控命令执行
MONITOR
```

### 数据操作

```bash
# 字符串操作
SET key value
GET key
INCR counter

# 列表操作
LPUSH list item
RPOP list
LRANGE list 0 -1

# 哈希操作
HSET hash field value
HGET hash field
HGETALL hash

# 集合操作
SADD set member
SMEMBERS set
SCARD set

# 有序集合
ZADD zset 1 member
ZRANGE zset 0 -1 WITHSCORES
```

## 运维管理

### 查看状态

```bash
# 查看 Pod 状态
kubectl get pods -n infra -l app.kubernetes.io/name=redis

# 查看日志
kubectl logs -f redis-master-0 -n infra

# 查看 PVC
kubectl get pvc -n infra -l app.kubernetes.io/name=redis
```

### 备份与恢复

#### 备份

```bash
# 触发 RDB 备份
kubectl exec -it redis-master-0 -n infra -- redis-cli -a RedisSecure2024! BGSAVE

# 检查备份状态
kubectl exec -it redis-master-0 -n infra -- redis-cli -a RedisSecure2024! LASTSAVE

# 复制备份文件
kubectl cp infra/redis-master-0:/data/dump.rdb ./redis-backup.rdb
```

#### 恢复

```bash
# 停止 Redis
kubectl scale statefulset redis-master -n infra --replicas=0

# 复制备份文件
kubectl cp ./redis-backup.rdb infra/redis-master-0:/data/dump.rdb

# 启动 Redis
kubectl scale statefulset redis-master -n infra --replicas=1
```

### 持久化配置

Redis 配置了两种持久化方式：

#### AOF (Append Only File)
- **启用**: `appendonly yes`
- **同步策略**: `appendfsync everysec`
- **更安全**，但占用更多磁盘

#### RDB (快照)
- **默认禁用**: `save ""`
- **可手动触发**: `BGSAVE`
- **更快速**，但可能丢失数据

## 性能优化

### 内存优化

```bash
# 查看内存统计
INFO memory

# 设置最大内存
CONFIG SET maxmemory 1gb

# 查看键的内存使用
MEMORY USAGE key

# 清理过期键
MEMORY PURGE
```

### 内存淘汰策略

当前配置: `allkeys-lru` (内存满时删除最近最少使用的键)

其他可选策略：
- `noeviction`: 不删除，返回错误
- `allkeys-lfu`: 删除最不经常使用的键
- `volatile-lru`: 只删除设置了过期时间的 LRU 键
- `volatile-ttl`: 删除即将过期的键

### 连接池优化

```bash
# 查看连接数
CLIENT LIST | wc -l

# 设置最大连接数
CONFIG SET maxclients 10000

# 设置超时
CONFIG SET timeout 300
```

## 故障排查

### 连接问题

```bash
# 测试网络连接
kubectl exec -it redis-master-0 -n infra -- nc -zv localhost 6379

# 检查服务
kubectl get svc -n infra | grep redis

# 测试认证
kubectl exec -it redis-master-0 -n infra -- redis-cli -a RedisSecure2024! PING
```

### 性能问题

```bash
# 查看慢查询
kubectl exec -it redis-master-0 -n infra -- redis-cli -a RedisSecure2024! SLOWLOG GET 10

# 查看命令统计
kubectl exec -it redis-master-0 -n infra -- redis-cli -a RedisSecure2024! INFO commandstats

# 查看客户端连接
kubectl exec -it redis-master-0 -n infra -- redis-cli -a RedisSecure2024! CLIENT LIST
```

### 内存问题

```bash
# 查看内存碎片率
kubectl exec -it redis-master-0 -n infra -- redis-cli -a RedisSecure2024! INFO memory | grep fragmentation

# 手动清理内存
kubectl exec -it redis-master-0 -n infra -- redis-cli -a RedisSecure2024! MEMORY DOCTOR

# 查看大键
kubectl exec -it redis-master-0 -n infra -- redis-cli -a RedisSecure2024! --bigkeys
```

## 监控指标

### Prometheus 指标

如果启用了 metrics，可以监控：

```promql
# 内存使用
redis_memory_used_bytes

# 连接数
redis_connected_clients

# 命令执行速率
rate(redis_commands_processed_total[5m])

# 键空间命中率
redis_keyspace_hits_total / (redis_keyspace_hits_total + redis_keyspace_misses_total)

# 过期键数量
redis_expired_keys_total
```

## 安全建议

1. **更改默认密码**: 生产环境必须修改默认密码
2. **限制命令**: 禁用危险命令如 FLUSHDB, FLUSHALL
3. **网络隔离**: 使用 NetworkPolicy 限制访问
4. **TLS 加密**: 生产环境启用 TLS
5. **定期备份**: 设置自动备份策略

### 禁用危险命令

```bash
# 在配置中添加
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command KEYS ""
rename-command CONFIG ""
```

## 高可用配置

### 主从复制

```bash
# 查看复制状态
INFO replication

# 查看从节点延迟
INFO replication | grep lag
```

### 哨兵模式

如果启用哨兵：

```bash
# 连接哨兵
redis-cli -h <NODE_IP> -p 26379

# 查看主节点
SENTINEL masters

# 查看从节点
SENTINEL slaves mymaster

# 手动故障转移
SENTINEL failover mymaster
```

## 升级指南

```bash
# 备份数据
kubectl exec -it redis-master-0 -n infra -- redis-cli -a RedisSecure2024! BGSAVE

# 更新版本
# 修改 variables.tf 中的 redis_version

# 应用更新
terraform apply -target=module.redis

# 验证版本
kubectl exec -it redis-master-0 -n infra -- redis-cli -a RedisSecure2024! INFO server | grep redis_version
```

## 相关文档

- [Redis 官方文档](https://redis.io/documentation)
- [Redis 命令参考](https://redis.io/commands)
- [Bitnami Redis Chart](https://github.com/bitnami/charts/tree/main/bitnami/redis)
- [Redis 最佳实践](https://redis.io/docs/management/)