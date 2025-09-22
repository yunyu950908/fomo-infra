# 运维脚本

本目录包含 FOMO Infrastructure 的系统准备、部署和运维管理脚本。

## 脚本列表

| 脚本 | 功能 | 使用场景 |
|------|------|----------|
| `prepare-system.sh` | 系统准备 | 配置 Ubuntu 系统环境，安装依赖和优化参数 |
| `verify.sh` | 部署验证 | 检查所有服务状态和健康情况 |
| `backup.sh` | 数据备份 | 备份所有组件的数据和配置 |
| `restore.sh` | 数据恢复 | 从备份归档恢复数据 |

## 快速开始

### 完整部署流程

```bash
# 1. 准备系统环境（首次部署需要）
sudo ./scripts/prepare-system.sh

# 2. 使用 Terraform 部署 K3s 和基础设施
cd terraform
terraform init
terraform apply

# 3. 验证部署
cd ../scripts
./verify.sh
```

## 详细使用说明

### 系统准备

```bash
# 执行系统准备脚本
sudo ./scripts/prepare-system.sh
```

**功能特性**：
- ✅ 检查系统版本和资源
- ✅ 更新系统包
- ✅ 安装基础依赖（curl、wget、git、vim 等）
- ✅ 配置系统时间同步
- ✅ 禁用 Swap（K8s 要求）
- ✅ 加载内核模块（overlay、br_netfilter）
- ✅ 优化系统参数（CPU、内存优化）
- ✅ 配置文件描述符限制
- ✅ 禁用系统防火墙（使用云安全组）
- ✅ 安装 Terraform、kubectl、Helm

**系统要求**：
- Ubuntu 20.04/22.04/24.04
- 最小配置：4C8G
- 推荐配置：8C16G

### K3s 部署（通过 Terraform）

```bash
# 部署 K3s
cd terraform
terraform apply -target=module.k3s

# 查看 K3s 状态
kubectl get nodes
kubectl get pods -n kube-system
```

**Terraform K3s 模块特性**：
- ✅ 声明式配置管理
- ✅ 自动安装 K3s v1.32.0
- ✅ 禁用不需要的组件（traefik、servicelb、metrics-server）
- ✅ 配置本地存储路径
- ✅ 自动设置 kubeconfig
- ✅ 支持配置回滚

### 部署验证

```bash
# 执行验证脚本
./scripts/verify.sh
```

**功能特性**：
- ✅ 检查命名空间状态
- ✅ 验证所有 Pod 运行状态
- ✅ 测试服务端口可访问性
- ✅ 检查 HTTP 端点健康状态
- ✅ 验证存储卷绑定状态
- ✅ 显示服务访问地址

**输出示例**：
```
==========================================
FOMO Infrastructure 部署验证
节点 IP: 192.168.1.100
==========================================

检查命名空间 infra...
✓ 命名空间 infra 存在

检查服务: portainer
  ✓ Pod 运行中
  ✓ 端口 30777 可访问
  ✓ HTTP 端点响应正常
```

### 数据备份

```bash
# 执行备份脚本
./scripts/backup.sh
```

**备份内容**：
- 📁 **Terraform 状态**: `terraform.tfstate` 文件
- 🗄️ **MongoDB**: 完整数据库导出（mongodump）
- 💾 **Redis**: RDB 持久化快照
- 🐰 **RabbitMQ**: 队列、用户、权限定义
- 📊 **Grafana**: 仪表板、数据源、用户配置
- 🚢 **Portainer**: 环境配置、用户数据
- 📈 **Prometheus**: 告警规则、配置文件
- 🔔 **Alertmanager**: 路由规则、通知配置

**输出位置**：
```
/tmp/fomo-backup-YYYYMMDD-HHMMSS.tar.gz
```

### 数据恢复

```bash
# 从备份恢复
./scripts/restore.sh /tmp/fomo-backup-20240315-143022.tar.gz
```

**恢复流程**：
1. 解压备份归档
2. 确认恢复操作（会覆盖现有数据）
3. 恢复各组件数据
4. 重启相关 Pod
5. 等待服务就绪

**注意事项**：
- ⚠️ 恢复操作会覆盖现有数据
- ⚠️ 恢复过程中服务会短暂中断
- ⚠️ 建议在恢复前先执行备份

## 定时备份配置

### 使用 Cron 设置自动备份

```bash
# 编辑 crontab
crontab -e

# 每天凌晨 2 点执行备份
0 2 * * * /path/to/fomo-infra/scripts/backup.sh

# 每周日凌晨 3 点执行完整备份
0 3 * * 0 /path/to/fomo-infra/scripts/backup.sh
```

### 备份保留策略

建议的备份保留策略：
- **每日备份**: 保留 7 天
- **每周备份**: 保留 4 周
- **每月备份**: 保留 3 个月

清理脚本示例：
```bash
#!/bin/bash
# 清理超过 7 天的备份
find /backup/daily -name "fomo-backup-*.tar.gz" -mtime +7 -delete

# 清理超过 30 天的备份
find /backup/weekly -name "fomo-backup-*.tar.gz" -mtime +30 -delete
```

## 故障排查

### verify.sh 常见问题

**问题**: Pod 状态显示 NotFound
```bash
# 检查部署是否完成
kubectl get pods -n infra

# 查看部署状态
terraform -chdir=terraform show
```

**问题**: 端口无法访问
```bash
# 检查 NodePort 服务
kubectl get svc -n infra

# 检查防火墙规则
sudo iptables -L -n | grep 30
```

### backup.sh 常见问题

**问题**: 备份失败 - Pod 未找到
```bash
# 确认服务已部署
kubectl get pods -n infra

# 手动触发单个组件备份
kubectl exec -it mongodb-0 -n infra -- mongodump --archive=/tmp/backup.archive
```

**问题**: 备份文件过大
```bash
# 清理不必要的数据
kubectl exec -it prometheus-0 -n infra -- rm -rf /prometheus/wal

# 压缩旧的时序数据
kubectl exec -it prometheus-0 -n infra -- promtool tsdb compact /prometheus
```

### restore.sh 常见问题

**问题**: 恢复后服务无法启动
```bash
# 查看 Pod 事件
kubectl describe pod <pod-name> -n infra

# 查看日志
kubectl logs <pod-name> -n infra

# 强制重建 Pod
kubectl delete pod <pod-name> -n infra --force --grace-period=0
```

**问题**: 数据不一致
```bash
# 验证备份完整性
tar -tzf backup.tar.gz | head

# 检查恢复日志
kubectl logs <pod-name> -n infra | grep -i error
```

## 监控集成

### 配置告警

为运维脚本执行结果配置监控告警：

```yaml
# prometheus/alerts/backup.yaml
groups:
  - name: backup
    rules:
      - alert: BackupFailed
        expr: backup_last_success_timestamp < time() - 86400
        for: 1h
        annotations:
          summary: "备份超过24小时未成功执行"

      - alert: RestoreFailed
        expr: restore_success == 0
        for: 5m
        annotations:
          summary: "数据恢复失败"
```

### 脚本执行指标

可以通过以下方式收集脚本执行指标：

```bash
# 发送指标到 Prometheus Pushgateway
./scripts/backup.sh && \
  echo "backup_success 1" | curl --data-binary @- http://pushgateway:9091/metrics/job/backup

# 记录执行时间
time ./scripts/verify.sh 2>&1 | tee /var/log/verify.log
```

## 安全建议

1. **脚本权限**
```bash
# 设置适当的权限
chmod 750 scripts/*.sh
chown root:ops scripts/*.sh
```

2. **备份加密**
```bash
# 加密备份文件
./scripts/backup.sh
gpg --encrypt --recipient backup@example.com /tmp/fomo-backup-*.tar.gz
```

3. **异地备份**
```bash
# 上传到对象存储
aws s3 cp /tmp/fomo-backup-*.tar.gz s3://backup-bucket/fomo/

# 或使用 rsync 到远程服务器
rsync -avz /tmp/fomo-backup-*.tar.gz backup@remote:/backup/fomo/
```

## 性能优化

### 并行备份

对于大型数据集，可以修改脚本实现并行备份：

```bash
# 在 backup.sh 中使用后台任务
backup_mongodb &
backup_redis &
backup_rabbitmq &
wait  # 等待所有后台任务完成
```

### 增量备份

对于频繁变化的数据，考虑实现增量备份：

```bash
# MongoDB 增量备份（基于 oplog）
mongodump --archive=/tmp/incremental.archive \
  --oplogReplay \
  --oplogBaseTs="Timestamp(1616025600, 1)"
```

## 扩展功能

### 健康报告

生成详细的健康检查报告：

```bash
#!/bin/bash
./scripts/verify.sh > /tmp/health-report-$(date +%Y%m%d).txt
mail -s "Daily Health Report" ops@example.com < /tmp/health-report-*.txt
```

### 容量规划

监控存储使用趋势：

```bash
#!/bin/bash
# 收集存储使用数据
kubectl exec -it mongodb-0 -n infra -- du -sh /data
kubectl exec -it redis-0 -n infra -- du -sh /bitnami/redis/data
kubectl exec -it grafana-0 -n infra -- du -sh /opt/bitnami/grafana/data
```

## 系统配置详解

### 内核参数说明

脚本配置的关键内核参数及其作用：

#### 网络参数
- `net.bridge.bridge-nf-call-iptables = 1`: IPv4 桥接流量经过 iptables
- `net.ipv4.ip_forward = 1`: 启用 IP 包转发
- `net.core.somaxconn = 32768`: 增加监听队列大小
- `net.ipv4.tcp_max_syn_backlog = 8192`: 增加 SYN 请求队列

#### 文件系统
- `fs.file-max = 1000000`: 系统最大文件句柄数
- `fs.inotify.max_user_watches = 524288`: inotify 监控文件数

#### 内存管理
- `vm.max_map_count = 262144`: 最大内存映射区域数
- `vm.swappiness = 0`: 禁用 swap 倾向
- `vm.overcommit_memory = 1`: 允许内存超分配

### 故障排查指南

#### prepare-system.sh 问题

**问题**: 脚本执行权限不足
```bash
# 解决方案
chmod +x scripts/prepare-system.sh
sudo ./scripts/prepare-system.sh
```

**问题**: APT 源更新失败
```bash
# 更换为阿里云源
sudo sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list
sudo apt update
```

#### Terraform K3s 模块问题

**问题**: K3s 安装失败
```bash
# 查看 Terraform 日志
terraform apply -target=module.k3s -auto-approve

# 手动检查 K3s 服务
sudo systemctl status k3s
sudo journalctl -xeu k3s.service --no-pager
```

**问题**: kubeconfig 权限问题
```bash
# 修复 kubeconfig 权限
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
export KUBECONFIG=~/.kube/config
```

## 相关文档

- [K3s 官方文档](https://docs.k3s.io/)
- [Kubernetes 备份最佳实践](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [MongoDB 备份策略](https://docs.mongodb.com/manual/core/backups/)
- [Redis 持久化机制](https://redis.io/topics/persistence)
- [RabbitMQ 备份恢复](https://www.rabbitmq.com/backup.html)