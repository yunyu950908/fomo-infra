# Portainer 模块

Portainer Business Edition 容器管理平台，提供直观的 Web UI 管理 Kubernetes 集群。

## 特性

- **版本**: Portainer BE 2.19.4
- **界面**: 企业版功能全开
- **存储**: 2Gi 持久化存储
- **外部访问**: NodePort 30777
- **Edge 端口**: NodePort 30776
- **认证**: 内置用户管理系统

## 配置参数

| 参数 | 默认值 | 说明 |
|-----|--------|------|
| `namespace` | infra | 部署命名空间 |
| `release_name` | portainer | Helm 发布名称 |
| `image_tag` | 2.19.4 | Portainer 版本 |
| `http_node_port` | 30777 | Web UI NodePort |
| `edge_node_port` | 30776 | Edge Agent NodePort |
| `storage_size` | 2Gi | 存储大小 |
| `log_level` | INFO | 日志级别 |

### 资源配置

| 资源 | 请求 | 限制 |
|------|------|------|
| CPU | 50m | 200m |
| 内存 | 32Mi | 128Mi |

## 使用方法

### 基础使用

```hcl
module "portainer" {
  source = "./modules/portainer"
}
```

### 自定义配置

```hcl
module "portainer" {
  source = "./modules/portainer"

  namespace     = "management"
  image_tag     = "2.19.4"

  http_node_port = 30888
  edge_node_port = 30889

  storage_size = "5Gi"

  resources = {
    requests = {
      memory = "64Mi"
      cpu    = "100m"
    }
    limits = {
      memory = "256Mi"
      cpu    = "500m"
    }
  }

  log_level = "DEBUG"
}
```

## 访问方式

### Web 界面

```bash
# 外部访问
http://<NODE_IP>:30777

# 端口转发（本地访问）
kubectl port-forward -n infra svc/portainer 9000:9000
```

### 初始化设置

首次访问时需要：

1. 创建管理员账户
2. 选择环境类型（选择 Kubernetes）
3. 连接到本地 Kubernetes 集群

### API 访问

```bash
# 获取 JWT Token
TOKEN=$(curl -X POST http://<NODE_IP>:30777/api/auth \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"your-password"}' \
  | jq -r .jwt)

# 使用 Token 访问 API
curl -H "Authorization: Bearer $TOKEN" \
  http://<NODE_IP>:30777/api/endpoints

# 获取堆栈列表
curl -H "Authorization: Bearer $TOKEN" \
  http://<NODE_IP>:30777/api/stacks
```

## 功能特性

### 集群管理

- **节点管理**: 查看和管理 K8s 节点
- **命名空间**: 创建和管理命名空间
- **资源配额**: 设置资源限制
- **RBAC**: 角色和权限管理

### 应用管理

- **应用模板**: 一键部署常用应用
- **Helm 支持**: 管理 Helm Charts
- **堆栈管理**: Docker Compose 格式部署
- **配置管理**: ConfigMap 和 Secret 管理

### 容器管理

- **容器列表**: 查看所有容器
- **日志查看**: 实时日志流
- **终端访问**: Web 终端
- **资源监控**: CPU/内存使用情况

### 镜像管理

- **镜像仓库**: 连接多个镜像仓库
- **镜像构建**: 支持在线构建
- **镜像扫描**: 安全漏洞扫描
- **镜像推送**: 推送到私有仓库

## 用户管理

### 创建用户

1. 设置 → 用户 → 添加用户
2. 填写用户信息
3. 分配角色和权限
4. 设置资源访问权限

### 角色类型

- **管理员**: 完全控制权限
- **操作员**: 管理容器和服务
- **用户**: 只读权限
- **自定义**: 自定义权限组合

### 团队管理

```bash
# 通过 API 创建团队
curl -X POST http://<NODE_IP>:30777/api/teams \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "Name": "DevOps Team",
    "Description": "DevOps team members"
  }'
```

## Edge Agent

### 部署 Edge Agent

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: portainer
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: portainer-edge-agent
  namespace: portainer
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: portainer-edge-agent
  namespace: portainer
spec:
  replicas: 1
  selector:
    matchLabels:
      app: portainer-edge-agent
  template:
    metadata:
      labels:
        app: portainer-edge-agent
    spec:
      serviceAccountName: portainer-edge-agent
      containers:
      - name: edge-agent
        image: portainer/agent:2.19.4
        env:
        - name: EDGE
          value: "1"
        - name: EDGE_ID
          value: "your-edge-id"
        - name: EDGE_KEY
          value: "your-edge-key"
        - name: EDGE_INSECURE_POLL
          value: "1"
        - name: AGENT_CLUSTER_ADDR
          value: "portainer-edge-agent"
        ports:
        - containerPort: 9001
          name: agent
        - containerPort: 80
          name: edge
```

### 连接远程集群

1. 环境 → 添加环境
2. 选择 "Edge Agent"
3. 复制生成的部署命令
4. 在远程集群执行

## 应用部署

### 使用应用模板

1. 应用模板 → 选择模板
2. 配置参数
3. 选择命名空间
4. 部署应用

### 部署 Helm Chart

```bash
# 添加 Helm 仓库
1. Helm → 仓库 → 添加仓库
2. 输入仓库 URL

# 部署 Chart
1. Helm → Charts → 选择 Chart
2. 配置 values
3. 部署
```

### 部署堆栈

```yaml
# docker-compose.yml 格式
version: '3'
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - web-data:/usr/share/nginx/html

volumes:
  web-data:
```

## 运维管理

### 查看状态

```bash
# 查看 Pod 状态
kubectl get pods -n infra -l app=portainer

# 查看日志
kubectl logs -f deployment/portainer -n infra

# 查看事件
kubectl get events -n infra --field-selector involvedObject.name=portainer
```

### 备份与恢复

#### 备份

```bash
# 备份数据
kubectl exec -it deployment/portainer -n infra -- tar czf /tmp/portainer-backup.tar.gz /data

# 复制到本地
kubectl cp infra/$(kubectl get pod -n infra -l app=portainer -o jsonpath='{.items[0].metadata.name}'):/tmp/portainer-backup.tar.gz ./portainer-backup.tar.gz
```

#### 恢复

```bash
# 复制备份文件
kubectl cp ./portainer-backup.tar.gz infra/$(kubectl get pod -n infra -l app=portainer -o jsonpath='{.items[0].metadata.name}'):/tmp/

# 恢复数据
kubectl exec -it deployment/portainer -n infra -- tar xzf /tmp/portainer-backup.tar.gz -C /

# 重启 Portainer
kubectl rollout restart deployment/portainer -n infra
```

### 配置持久化

Portainer 的配置存储在 `/data` 目录：

- `/data/portainer.db`: 主数据库
- `/data/tls/`: TLS 证书
- `/data/compose/`: 堆栈文件
- `/data/custom_templates/`: 自定义模板

## 集成配置

### LDAP/AD 集成

1. 设置 → 认证 → LDAP
2. 配置 LDAP 服务器信息
3. 设置用户和组映射
4. 测试连接

### OAuth 集成

```json
{
  "AuthenticationMethod": 3,
  "OAuth": {
    "ClientID": "your-client-id",
    "ClientSecret": "your-client-secret",
    "AuthorizationURL": "https://oauth.provider.com/authorize",
    "AccessTokenURL": "https://oauth.provider.com/token",
    "ResourceURL": "https://oauth.provider.com/user",
    "RedirectURL": "http://<NODE_IP>:30777/",
    "UserIdentifier": "email",
    "Scopes": "openid profile email"
  }
}
```

### Webhook 通知

```bash
# 配置 Webhook
curl -X POST http://<NODE_IP>:30777/api/webhooks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "ResourceType": "container",
    "Events": ["start", "stop", "die"],
    "URL": "https://webhook.site/your-webhook",
    "Method": "POST"
  }'
```

## 安全配置

### TLS/SSL

```bash
# 生成自签名证书
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

# 创建 Secret
kubectl create secret tls portainer-tls \
  --cert=cert.pem \
  --key=key.pem \
  -n infra

# 配置 Portainer 使用 TLS
kubectl set env deployment/portainer -n infra \
  SSL_CERT=/certs/tls.crt \
  SSL_KEY=/certs/tls.key
```

### 访问控制

1. **IP 白名单**: 限制访问 IP
2. **会话超时**: 设置自动登出时间
3. **密码策略**: 强制密码复杂度
4. **双因素认证**: 启用 2FA

### 审计日志

```bash
# 查看审计日志
kubectl exec -it deployment/portainer -n infra -- cat /data/portainer.log | grep AUDIT

# 导出审计日志
kubectl exec -it deployment/portainer -n infra -- cat /data/portainer.log > audit.log
```

## 性能优化

### 资源调优

```yaml
# 增加资源限制
resources:
  requests:
    memory: "128Mi"
    cpu: "200m"
  limits:
    memory: "512Mi"
    cpu: "1000m"
```

### 数据库优化

```bash
# 压缩数据库
kubectl exec -it deployment/portainer -n infra -- \
  sqlite3 /data/portainer.db "VACUUM;"

# 分析数据库
kubectl exec -it deployment/portainer -n infra -- \
  sqlite3 /data/portainer.db "ANALYZE;"
```

## 故障排查

### 无法访问

```bash
# 检查服务
kubectl get svc -n infra | grep portainer

# 检查端口
kubectl get svc portainer -n infra -o jsonpath='{.spec.ports[*].nodePort}'

# 测试连接
curl -I http://<NODE_IP>:30777
```

### 登录问题

```bash
# 重置管理员密码
kubectl exec -it deployment/portainer -n infra -- /portainer --reset-admin-password

# 查看认证日志
kubectl logs deployment/portainer -n infra | grep AUTH
```

### 性能问题

```bash
# 查看资源使用
kubectl top pod -n infra -l app=portainer

# 查看数据库大小
kubectl exec -it deployment/portainer -n infra -- ls -lh /data/portainer.db

# 清理旧数据
kubectl exec -it deployment/portainer -n infra -- find /data -name "*.log" -mtime +30 -delete
```

## API 使用示例

### 管理容器

```bash
# 列出容器
curl -H "Authorization: Bearer $TOKEN" \
  http://<NODE_IP>:30777/api/endpoints/1/docker/containers/json

# 启动容器
curl -X POST -H "Authorization: Bearer $TOKEN" \
  http://<NODE_IP>:30777/api/endpoints/1/docker/containers/{id}/start

# 停止容器
curl -X POST -H "Authorization: Bearer $TOKEN" \
  http://<NODE_IP>:30777/api/endpoints/1/docker/containers/{id}/stop
```

### 管理堆栈

```bash
# 创建堆栈
curl -X POST http://<NODE_IP>:30777/api/stacks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "Name": "my-app",
    "StackFileContent": "version: \"3\"\nservices:\n  web:\n    image: nginx:alpine\n    ports:\n      - \"8080:80\"",
    "EndpointId": 1
  }'

# 更新堆栈
curl -X PUT http://<NODE_IP>:30777/api/stacks/{id} \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "StackFileContent": "...",
    "Prune": false
  }'
```

## 最佳实践

1. **定期备份**: 每天备份数据库
2. **限制权限**: 使用最小权限原则
3. **启用 TLS**: 生产环境必须启用
4. **监控集成**: 集成到 Prometheus
5. **定期更新**: 及时更新版本

## 升级指南

```bash
# 备份数据
kubectl exec -it deployment/portainer -n infra -- tar czf /tmp/backup.tar.gz /data

# 更新镜像版本
kubectl set image deployment/portainer portainer=portainer/portainer-ee:2.19.5 -n infra

# 等待更新完成
kubectl rollout status deployment/portainer -n infra

# 验证版本
curl http://<NODE_IP>:30777/api/system/version
```

## 许可证管理

Portainer BE 需要许可证：

1. 设置 → 许可证
2. 上传许可证文件或输入密钥
3. 查看许可证状态和过期时间

免费版限制：
- 5 个节点
- 基础功能

企业版特性：
- 无限节点
- RBAC
- OAuth/LDAP
- 边缘计算
- 技术支持

## 相关文档

- [Portainer 官方文档](https://docs.portainer.io/)
- [Portainer API 文档](https://docs.portainer.io/api/overview)
- [Portainer 社区论坛](https://community.portainer.io/)
- [Portainer GitHub](https://github.com/portainer/portainer)