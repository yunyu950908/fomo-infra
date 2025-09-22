# FOMO Infrastructure

基于 K3s 的轻量级基础设施平台，针对 4C8G 单节点环境优化。

## 🚀 快速开始

```bash
# 1. 进入 Terraform 目录
cd terraform

# 2. 初始化并部署
terraform init
terraform apply -auto-approve
```

## 📁 项目结构

```
fomo-infra/
├── terraform/           # Terraform 基础设施配置
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
│   └── README.md      # [Terraform 详细文档](terraform/README.md)
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

- **硬件**: 4 核 CPU, 8GB 内存
- **存储**: 最少 100GB 可用空间
- **系统**: Ubuntu 22.04 LTS / Debian 11+

## 🎯 特性

✅ **单节点优化** - 针对 4C8G 资源精心调优
✅ **统一命名空间** - 所有服务部署在 `infra` 命名空间
✅ **完整监控** - Prometheus + Grafana + Alertmanager
✅ **模块化设计** - Terraform IaC 管理
✅ **中文文档** - 完整的中文注释和文档

## 📖 详细文档

- **[Terraform 配置指南](terraform/README.md)** - 完整的部署和配置说明
- **[部署文档](terraform/docs/deployment.md)** - 生产环境部署指南
- **[故障排查](terraform/docs/troubleshooting.md)** - 常见问题解决
- **[最佳实践](terraform/docs/best-practices.md)** - 使用建议

## 📝 许可证

MIT License

---

*使用 Terraform HCL 构建，为生产环境就绪*