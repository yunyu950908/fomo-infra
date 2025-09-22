# K3s 模块

轻量级 Kubernetes 发行版，针对单节点 4C8G 环境优化。

## 特性

- **版本**: v1.32.0+k3s1
- **轻量级**: 移除不必要的组件（traefik, servicelb, metrics-server）
- **存储**: 内置 local-path-provisioner
- **网络**: Flannel VXLAN 后端
- **资源优化**: 针对 4C8G 环境调优

## 配置参数

| 参数 | 默认值 | 说明 |
|-----|--------|------|
| `k3s_version` | v1.32.0+k3s1 | K3s 版本 |
| `cluster_cidr` | 10.42.0.0/16 | Pod 网络 CIDR |
| `service_cidr` | 10.43.0.0/16 | Service 网络 CIDR |
| `cluster_dns` | 10.43.0.10 | 集群 DNS 地址 |
| `max_pods` | 110 | 单节点最大 Pod 数 |
| `memory_threshold` | 200Mi | 内存驱逐阈值 |
| `disk_threshold` | 10% | 磁盘驱逐阈值 |

## 使用方法

### 基础使用

```hcl
module "k3s" {
  source = "./modules/k3s"
}
```

### 自定义配置

```hcl
module "k3s" {
  source = "./modules/k3s"

  k3s_version      = "v1.32.0+k3s1"
  memory_threshold = "300Mi"
  max_pods         = 150
  storage_path     = "/data/local-path-provisioner"
}
```

## 输出值

| 输出 | 说明 |
|------|------|
| `kubeconfig_path` | kubeconfig 文件路径 |
| `cluster_info` | 集群配置信息 |

## 部署后操作

### 验证安装

```bash
# 检查节点状态
kubectl get nodes

# 查看系统 Pod
kubectl get pods -n kube-system

# 检查存储类
kubectl get storageclass
```

### 配置 kubeconfig

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

### 查看驱逐阈值

```bash
kubectl describe node | grep -A 5 "Allocated resources"
```

## 存储配置

本模块使用 local-path-provisioner 提供动态存储：

- **存储路径**: `/opt/local-path-provisioner`
- **存储类名**: `local-path` (默认)
- **访问模式**: ReadWriteOnce

### 创建 PVC 示例

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 1Gi
```

## 网络配置

### Flannel 配置
- **后端**: VXLAN
- **MTU**: 1450 (自动配置)
- **端口**: 8472/udp

### CoreDNS 配置
- **服务地址**: 10.43.0.10
- **域名**: cluster.local

## 资源管理

### 驱逐策略

当节点资源不足时，K3s 会根据以下阈值驱逐 Pod：

- **内存可用 < 200Mi**: 软驱逐
- **磁盘可用 < 10%**: 软驱逐
- **inode 可用 < 5%**: 软驱逐
- **镜像文件系统可用 < 15%**: 软驱逐

### 资源预留

K3s 为系统组件预留资源：
- **CPU**: 100m
- **内存**: 100Mi

## 故障排查

### K3s 无法启动

```bash
# 查看服务状态
sudo systemctl status k3s

# 查看日志
sudo journalctl -u k3s -f

# 重置 K3s
sudo k3s-killall.sh
sudo systemctl restart k3s
```

### 存储问题

```bash
# 检查存储路径权限
ls -la /opt/local-path-provisioner/

# 修复权限
sudo chown -R 1000:1000 /opt/local-path-provisioner/
```

### 网络问题

```bash
# 检查 Flannel
kubectl get pods -n kube-system | grep flannel

# 重启 Flannel
kubectl rollout restart daemonset/kube-flannel-ds -n kube-system

# 检查 iptables
sudo iptables -t nat -L -n
```

## 卸载

```bash
# 停止 K3s
sudo systemctl stop k3s

# 卸载 K3s
sudo /usr/local/bin/k3s-uninstall.sh

# 清理存储
sudo rm -rf /opt/local-path-provisioner/*
```

## 注意事项

1. **单节点部署**: 本配置针对单节点优化，生产环境建议多节点
2. **资源限制**: 确保节点至少有 4C8G 资源
3. **存储管理**: 定期清理未使用的 PV
4. **安全配置**: 生产环境建议启用 RBAC 和网络策略

## 相关文档

- [K3s 官方文档](https://docs.k3s.io/)
- [Local Path Provisioner](https://github.com/rancher/local-path-provisioner)
- [Flannel 文档](https://github.com/flannel-io/flannel)