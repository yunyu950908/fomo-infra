# MongoDB 模块

基于 Bitnami Helm Chart 的 MongoDB 7.0 部署，针对单节点 4C8G 环境优化。

## 特性

- **版本**: MongoDB 7.0
- **架构**: 单节点（可切换副本集）
- **存储**: 20Gi 持久化存储
- **认证**: 启用安全认证
- **外部访问**: NodePort 30017

## 配置参数

| 参数 | 默认值 | 说明 |
|-----|--------|------|
| `namespace` | infra | 部署命名空间 |
| `release_name` | mongodb | Helm 发布名称 |
| `mongodb_version` | 7.0 | MongoDB 版本 |
| `architecture` | standalone | 架构模式 |
| `replica_count` | 1 | 副本数量 |
| `external_port` | 30017 | NodePort 端口 |
| `storage.size` | 20Gi | 存储大小 |

### 认证配置

| 参数 | 默认值 | 说明 |
|-----|--------|------|
| `auth.root_user` | admin | 管理员用户名 |
| `auth.root_password` | MongoAdmin2024! | 管理员密码 |
| `auth.usernames` | ["appuser"] | 应用用户名列表 |
| `auth.passwords` | ["AppUser2024!"] | 应用密码列表 |
| `auth.databases` | ["app_database"] | 数据库列表 |

### 资源配置

| 资源 | 请求 | 限制 |
|------|------|------|
| CPU | 250m | 1000m |
| 内存 | 512Mi | 2Gi |

## 使用方法

### 基础使用

```hcl
module "mongodb" {
  source = "./modules/mongodb"
}
```

### 自定义配置

```hcl
module "mongodb" {
  source = "./modules/mongodb"

  namespace     = "databases"
  mongodb_version = "7.0"

  # 启用副本集
  architecture = "replicaset"
  replica_count = 3

  auth = {
    root_user     = "admin"
    root_password = var.mongodb_password
    usernames     = ["app1", "app2"]
    passwords     = [var.app1_password, var.app2_password]
    databases     = ["db1", "db2"]
  }

  storage = {
    class = "fast-ssd"
    size  = "50Gi"
  }

  resources = {
    requests = {
      memory = "1Gi"
      cpu    = "500m"
    }
    limits = {
      memory = "4Gi"
      cpu    = "2000m"
    }
  }
}
```

## 连接信息

### 外部连接

```bash
# MongoDB URI
mongodb://admin:MongoAdmin2024!@<NODE_IP>:30017

# MongoDB Shell
mongosh --host <NODE_IP> --port 30017 -u admin -p MongoAdmin2024! --authenticationDatabase admin
```

### 内部连接

```bash
# Kubernetes 内部 URI
mongodb://admin:MongoAdmin2024!@mongodb.infra.svc.cluster.local:27017

# 应用连接字符串
mongodb://appuser:AppUser2024!@mongodb.infra.svc.cluster.local:27017/app_database
```

### 编程语言示例

#### Node.js

```javascript
const { MongoClient } = require('mongodb');

// 外部连接
const uri = 'mongodb://admin:MongoAdmin2024!@<NODE_IP>:30017';

// 内部连接
const uri = 'mongodb://appuser:AppUser2024!@mongodb.infra.svc.cluster.local:27017/app_database';

const client = new MongoClient(uri);
```

#### Python

```python
from pymongo import MongoClient

# 外部连接
client = MongoClient('mongodb://admin:MongoAdmin2024!@<NODE_IP>:30017')

# 内部连接
client = MongoClient('mongodb://appuser:AppUser2024!@mongodb.infra.svc.cluster.local:27017/app_database')
```

#### Go

```go
import "go.mongodb.org/mongo-driver/mongo"

// 外部连接
uri := "mongodb://admin:MongoAdmin2024!@<NODE_IP>:30017"

// 内部连接
uri := "mongodb://appuser:AppUser2024!@mongodb.infra.svc.cluster.local:27017/app_database"
```

## 运维管理

### 查看状态

```bash
# 查看 Pod 状态
kubectl get pods -n infra -l app.kubernetes.io/name=mongodb

# 查看日志
kubectl logs -f mongodb-0 -n infra

# 查看 PVC
kubectl get pvc -n infra -l app.kubernetes.io/name=mongodb
```

### 连接数据库

```bash
# 进入 MongoDB Pod
kubectl exec -it mongodb-0 -n infra -- bash

# 使用 mongosh 连接
kubectl exec -it mongodb-0 -n infra -- mongosh -u admin -p MongoAdmin2024! --authenticationDatabase admin
```

### 常用命令

```bash
# 查看数据库列表
show dbs

# 切换数据库
use app_database

# 查看集合
show collections

# 查看用户
db.getUsers()

# 查看服务器状态
db.serverStatus()

# 查看副本集状态（如果启用）
rs.status()
```

## 备份与恢复

### 备份

```bash
# 创建备份目录
kubectl exec -it mongodb-0 -n infra -- mkdir -p /tmp/backup

# 执行备份
kubectl exec -it mongodb-0 -n infra -- mongodump \
  --authenticationDatabase admin \
  -u admin -p MongoAdmin2024! \
  --out /tmp/backup

# 复制备份到本地
kubectl cp infra/mongodb-0:/tmp/backup ./mongodb-backup
```

### 恢复

```bash
# 复制备份到 Pod
kubectl cp ./mongodb-backup infra/mongodb-0:/tmp/restore

# 执行恢复
kubectl exec -it mongodb-0 -n infra -- mongorestore \
  --authenticationDatabase admin \
  -u admin -p MongoAdmin2024! \
  /tmp/restore
```

## 性能优化

### 索引管理

```javascript
// 创建索引
db.collection.createIndex({ field: 1 })

// 查看索引
db.collection.getIndexes()

// 分析查询
db.collection.explain("executionStats").find({ field: value })
```

### 监控指标

```bash
# 查看当前操作
db.currentOp()

# 查看连接数
db.serverStatus().connections

# 查看内存使用
db.serverStatus().mem

# 查看 WiredTiger 缓存
db.serverStatus().wiredTiger.cache
```

## 故障排查

### Pod 无法启动

```bash
# 查看 Pod 事件
kubectl describe pod mongodb-0 -n infra

# 检查 PVC 状态
kubectl get pvc -n infra

# 查看详细日志
kubectl logs mongodb-0 -n infra --previous
```

### 连接问题

```bash
# 测试网络连接
kubectl exec -it mongodb-0 -n infra -- nc -zv localhost 27017

# 检查服务
kubectl get svc -n infra | grep mongodb

# 测试 DNS 解析
kubectl exec -it mongodb-0 -n infra -- nslookup mongodb.infra.svc.cluster.local
```

### 性能问题

```bash
# 查看慢查询
db.setProfilingLevel(1, { slowms: 100 })
db.system.profile.find().limit(5).sort({ ts: -1 }).pretty()

# 查看锁状态
db.serverStatus().locks

# 清理缓存
db.adminCommand({ setParameter: 1, wiredTigerEngineRuntimeConfig: "cache_size=1G" })
```

## 安全建议

1. **更改默认密码**: 生产环境必须修改默认密码
2. **启用 TLS**: 配置 SSL/TLS 加密连接
3. **限制访问**: 使用网络策略限制访问
4. **定期备份**: 设置自动备份策略
5. **监控告警**: 集成 Prometheus 监控

## 升级指南

```bash
# 备份数据
kubectl exec -it mongodb-0 -n infra -- mongodump --out /tmp/backup

# 更新版本
# 修改 variables.tf 中的 mongodb_version

# 应用更新
terraform apply -target=module.mongodb

# 验证版本
kubectl exec -it mongodb-0 -n infra -- mongosh --version
```

## 相关文档

- [MongoDB 官方文档](https://docs.mongodb.com/)
- [Bitnami MongoDB Chart](https://github.com/bitnami/charts/tree/main/bitnami/mongodb)
- [MongoDB 最佳实践](https://docs.mongodb.com/manual/administration/production-notes/)