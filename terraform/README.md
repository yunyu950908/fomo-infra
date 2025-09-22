# Terraform 基础设施配置

使用 Terraform 管理的完整 Kubernetes 基础设施，基于 K3s 和 Bitnami Helm Charts。

## 📋 目录

- [环境要求](#环境要求)
- [快速部署](#快速部署)
- [配置说明](#配置说明)
- [模块列表](#模块列表)
- [自定义配置](#自定义配置)
- [运维管理](#运维管理)
- [故障排查](#故障排查)

## 环境要求

### 硬件配置
- **CPU**: 4 核心
- **内存**: 8GB RAM
- **存储**: 100GB 可用空间
- **网络**: 稳定的互联网连接

### 软件依赖
- **Terraform**: >= 1.0
- **kubectl**: 与 K3s 版本兼容
- **Helm**: >= 3.0（可选）
- **操作系统**: Ubuntu 22.04 LTS / Debian 11+

## 快速部署

### 1. 初始化 Terraform

```bash
# 初始化 Terraform 提供者和模块
terraform init

# 验证配置语法
terraform validate
```

### 2. 分步部署（推荐）

#### Step 1: 部署 K3s

```bash
# 先部署 K3s 基础环境
terraform apply -target=module.k3s

# 验证 K3s 状态
kubectl get nodes
kubectl get pods -n kube-system
```

#### Step 2: 部署核心组件（可选）

```bash
# 部署容器管理平台
terraform apply -target=module.portainer

# 部署路由器
terraform apply -target=module.traefik
```

#### Step 3: 部署数据库（可选）

```bash
# 逐个部署数据库
terraform apply -target=module.mongodb
terraform apply -target=module.redis
terraform apply -target=module.rabbitmq
```

#### Step 4: 部署监控（可选）

```bash
# 部署监控栈
terraform apply -target=module.prometheus
terraform apply -target=module.grafana
terraform apply -target=module.alertmanager
```

### 3. 一键部署（可选）

```bash
# 部署所有资源
terraform apply

# 自动批准部署（谨慎使用）
terraform apply -auto-approve
```

### 4. 查看输出

```bash
# 查看所有输出
terraform output

# 查看特定输出
terraform output monitoring_urls
terraform output database_urls
```

## 配置说明

### 文件结构

```
terraform/
├── main.tf           # 主配置文件，定义所有模块
├── variables.tf      # 变量定义
├── outputs.tf        # 输出定义
├── providers.tf      # Provider 配置
├── terraform.tfvars  # 变量值（需创建）
└── modules/          # 各组件模块
    ├── k3s/         # K3s 集群
    ├── portainer/   # Portainer BE
    ├── traefik/     # Traefik 3.0
    ├── mongodb/     # MongoDB 7.0
    ├── redis/       # Redis 7.2
    ├── rabbitmq/    # RabbitMQ 3.13
    ├── prometheus/  # Prometheus 监控
    ├── grafana/     # Grafana 可视化
    └── alertmanager/# 告警管理
```

### 默认配置

所有服务部署在统一的 `infra` 命名空间中，主要配置包括：

| 服务 | CPU 请求 | 内存请求 | 存储 | 外部端口 |
|-----|---------|---------|------|----------|
| MongoDB | 250m | 512Mi | 20Gi | 30017 |
| Redis | 100m | 256Mi | 5Gi | 30379 |
| RabbitMQ | 200m | 512Mi | 8Gi | 30672/31672 |
| Prometheus | 100m | 256Mi | 15Gi | 30090 |
| Grafana | 50m | 128Mi | 5Gi | 30030 |
| Alertmanager | 25m | 64Mi | 2Gi | 30093 |

## 模块列表

### 基础设施

#### K3s 集群
- 轻量级 Kubernetes v1.32
- 禁用 traefik、servicelb、metrics-server
- 本地路径存储器
- [详细文档](modules/k3s/README.md)

#### Portainer BE
- 容器管理界面
- 企业版功能
- [详细文档](modules/portainer/README.md)

#### Traefik 3.0
- 现代化边缘路由器
- 自动 HTTPS
- [详细文档](modules/traefik/README.md)

### 数据库服务

#### MongoDB 7.0
- 单节点模式（可切换副本集）
- 自动备份脚本
- [详细文档](modules/mongodb/README.md)

#### Redis 7.2
- 单节点模式（可启用主从）
- 内存优化配置
- [详细文档](modules/redis/README.md)

#### RabbitMQ 3.13
- 单节点模式（可启用集群）
- 管理界面
- [详细文档](modules/rabbitmq/README.md)

### 监控系统

#### Prometheus
- 指标采集和存储
- 告警规则配置
- [详细文档](modules/prometheus/README.md)

#### Grafana
- 数据可视化
- 预置仪表板
- [详细文档](modules/grafana/README.md)

#### Alertmanager
- 告警路由和通知
- 多渠道支持
- [详细文档](modules/alertmanager/README.md)

## 自定义配置

### 1. 创建变量文件

创建 `terraform.tfvars` 文件：

```hcl
# K3s 配置
k3s_version = "v1.32.0+k3s1"
memory_threshold = "200Mi"

# 监控系统
monitoring_namespace = "infra"
prometheus_retention = "30d"
grafana_admin_password = "YourSecurePassword"

# 数据库配置
mongodb_root_password = "YourMongoPassword"
redis_auth_password = "YourRedisPassword"
rabbitmq_password = "YourRabbitPassword"

# 告警配置
alertmanager_smtp_enabled = true
alertmanager_smtp_smarthost = "smtp.gmail.com:587"
alertmanager_smtp_from = "alerts@yourdomain.com"
alertmanager_smtp_username = "your-email@gmail.com"
alertmanager_smtp_password = "your-app-password"
```

### 2. 环境特定配置

为不同环境创建配置：

```bash
# 开发环境
terraform workspace new dev
terraform apply -var-file="dev.tfvars"

# 生产环境
terraform workspace new prod
terraform apply -var-file="prod.tfvars"
```

### 3. 模块配置覆盖

在 `main.tf` 中覆盖模块默认值：

```hcl
module "mongodb" {
  source = "./modules/mongodb"

  # 覆盖默认配置
  architecture = "replicaset"
  replica_count = 3

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
      memory = "2Gi"
      cpu    = "1000m"
    }
  }
}
```

## 运维管理

### 状态管理

```bash
# 查看当前状态
terraform show

# 刷新状态
terraform refresh

# 导入现有资源
terraform import module.mongodb.helm_release.mongodb mongodb/mongodb
```

### 资源操作

```bash
# 销毁特定模块
terraform destroy -target=module.mongodb

# 重建资源
terraform apply -replace=module.redis.helm_release.redis

# 计划特定模块更新
terraform plan -target=module.grafana
```

### 访问服务

```bash
# 获取节点 IP
kubectl get nodes -o wide

# 端口转发（本地访问）
kubectl port-forward -n infra svc/prometheus 9090:9090
kubectl port-forward -n infra svc/grafana 3000:3000

# 查看服务状态
kubectl get pods -n infra
kubectl get svc -n infra
```

### 备份和恢复

```bash
# 备份 Terraform 状态
terraform state pull > terraform.tfstate.backup

# 备份数据库
kubectl exec -it mongodb-0 -n infra -- mongodump
kubectl exec -it redis-master-0 -n infra -- redis-cli BGSAVE

# 恢复状态
terraform state push terraform.tfstate.backup
```

## 故障排查

### 常见问题

#### 1. K3s 无法启动
```bash
# 检查 K3s 服务
sudo systemctl status k3s
sudo journalctl -u k3s -f

# 重启 K3s
sudo systemctl restart k3s
```

#### 2. Pod 无法启动
```bash
# 查看 Pod 事件
kubectl describe pod <pod-name> -n infra

# 查看日志
kubectl logs <pod-name> -n infra

# 检查资源使用
kubectl top nodes
kubectl top pods -n infra
```

#### 3. 存储问题
```bash
# 检查 PVC 状态
kubectl get pvc -n infra

# 检查存储类
kubectl get storageclass

# 查看本地路径
ls -la /opt/local-path-provisioner/
```

#### 4. 网络连接问题
```bash
# 测试服务连接
kubectl exec -it <pod-name> -n infra -- nslookup mongodb.infra.svc.cluster.local

# 检查服务端点
kubectl get endpoints -n infra

# 查看网络策略
kubectl get networkpolicy -n infra
```

### 日志收集

```bash
# 收集所有 Pod 日志
for pod in $(kubectl get pods -n infra -o name); do
  kubectl logs $pod -n infra > ${pod##*/}.log
done

# 查看 Terraform 日志
TF_LOG=DEBUG terraform apply
```

### 性能调优

1. **资源调整**: 编辑 `variables.tf` 中的资源请求和限制
2. **存储优化**: 考虑使用 SSD 存储类
3. **网络优化**: 调整 K3s 的网络插件配置
4. **监控阈值**: 调整 Prometheus 的告警规则

## 生产环境建议

1. **状态存储**: 使用远程后端（如 S3、Consul）
2. **密钥管理**: 使用 Vault 或 Kubernetes Secrets
3. **高可用**: 部署多节点 K3s 集群
4. **备份策略**: 定期自动备份
5. **监控告警**: 配置完整的告警通知
6. **安全加固**: 启用 RBAC、网络策略、TLS

## 升级指南

```bash
# 1. 备份当前状态
terraform state pull > backup.tfstate

# 2. 更新模块版本
# 编辑 variables.tf 中的版本号

# 3. 查看变更
terraform plan

# 4. 执行升级
terraform apply

# 5. 验证服务
kubectl get pods -n infra
```

## 卸载清理

```bash
# 销毁所有资源
terraform destroy

# 清理本地文件
rm -rf .terraform/
rm terraform.tfstate*
rm -rf modules/*/generated/

# 卸载 K3s（如果需要）
/usr/local/bin/k3s-uninstall.sh
```

## 相关链接

- [Terraform 文档](https://www.terraform.io/docs)
- [K3s 文档](https://docs.k3s.io/)
- [Bitnami Helm Charts](https://github.com/bitnami/charts)
- [Kubernetes 文档](https://kubernetes.io/docs/)

---

*如有问题，请查看各模块的 README 文档或提交 Issue*