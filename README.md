# FOMO Infrastructure

基于 K3s 的轻量级基础设施平台，针对 4C8G 单节点环境优化。

## 🚀 快速开始

### 方式一：分步部署（推荐）

```bash
# 1. 准备系统环境
sudo ./scripts/prepare-system.sh

# 2. 先部署 K3s
cd terraform
terraform init
terraform apply -target=module.k3s -auto-approve

# 3. 验证 K3s
kubectl get nodes
kubectl get pods -n kube-system

# 4. 部署其他组件（可选）
terraform apply -auto-approve
```

### 方式二：一键部署

```bash
# 准备环境并部署所有组件
sudo ./scripts/prepare-system.sh
cd terraform && terraform init && terraform apply -auto-approve
```

## 📁 项目结构

```
fomo-infra/
├── scripts/            # 运维管理脚本
│   ├── prepare-system.sh  # 系统环境准备
│   ├── verify.sh          # 部署验证
│   ├── backup.sh          # 数据备份
│   └── restore.sh         # 数据恢复
├── terraform/          # Terraform 基础设施配置
│   ├── modules/        # 各组件模块
│   │   ├── k3s/       # K3s 集群
│   │   ├── portainer/ # 容器管理平台
│   │   ├── traefik/   # 边缘路由器
│   │   ├── mongodb/   # MongoDB 数据库
│   │   ├── redis/     # Redis 缓存
│   │   ├── rabbitmq/  # 消息队列
│   │   ├── prometheus/# 监控系统
│   │   ├── grafana/   # 可视化平台
│   │   └── alertmanager/# 告警管理
│   └── README.md      # Terraform 详细文档
└── README.md          # 本文档
```

## 🔗 快速导航

| 组件 | 版本 | 端口 | 文档 |
|-----|------|------|------|
| **K3s** | v1.32.0 | - | [📖](terraform/modules/k3s/README.md) |
| **Portainer BE** | 2.19.4 | 30777 | [📖](terraform/modules/portainer/README.md) |
| **Traefik** | 3.0 | 30080 | [📖](terraform/modules/traefik/README.md) |
| **MongoDB** | 7.0 | 30017 | [📖](terraform/modules/mongodb/README.md) |
| **Redis** | 7.2 | 30379 | [📖](terraform/modules/redis/README.md) |
| **RabbitMQ** | 3.13 | 30672 | [📖](terraform/modules/rabbitmq/README.md) |
| **Prometheus** | 2.48 | 30090 | [📖](terraform/modules/prometheus/README.md) |
| **Grafana** | 10.2 | 30030 | [📖](terraform/modules/grafana/README.md) |
| **Alertmanager** | 0.26 | 30093 | [📖](terraform/modules/alertmanager/README.md) |

## 💻 系统要求

- **硬件**: 最小 4 核 CPU, 8GB 内存
- **存储**: 最少 100GB 可用空间
- **系统**: Ubuntu 20.04/22.04/24.04 LTS
- **网络**: 云安全组开放端口 22, 6443, 30000-32767

## 🎯 特性

✅ **Terraform IaC** - 全部使用 HCL 声明式配置
✅ **单节点优化** - 针对 4C8G 资源精心调优
✅ **统一命名空间** - 所有服务部署在 `infra` 命名空间
✅ **完整监控** - Prometheus + Grafana + Alertmanager
✅ **自动化运维** - 备份、恢复、验证脚本齐全
✅ **中文文档** - 完整的中文注释和文档

## 📖 详细文档

- **[系统准备指南](scripts/README.md)** - 系统环境配置和优化
- **[Terraform 配置指南](terraform/README.md)** - 完整的部署和配置说明
- **[系统优化说明](scripts/README-optimization.md)** - CPU和内存优化参数详解

## 📝 许可证

MIT License

---

*使用 Terraform HCL 构建，为生产环境就绪*