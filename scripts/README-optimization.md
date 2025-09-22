# 系统优化参数说明

本文档解释 `prepare-system.sh` 脚本中的优化参数及其作用。

## 📊 参数分类

### 1. K8s/K3s 必需参数（保留）

```bash
# 网络桥接 - 必须保留
net.bridge.bridge-nf-call-iptables = 1   # IPv4 流量经过 iptables
net.bridge.bridge-nf-call-ip6tables = 1  # IPv6 流量经过 iptables
net.ipv4.ip_forward = 1                  # 启用 IP 转发
```

### 2. 内存优化参数（针对 4C8G）

```bash
# 内存管理优化
vm.swappiness = 0                    # 禁用 swap 倾向
vm.overcommit_memory = 1             # 允许内存超分配（容器需要）
vm.panic_on_oom = 0                  # OOM 时不 panic
vm.min_free_kbytes = 65536           # 保留最小空闲内存 64MB

# 脏页写回优化（减少 I/O 压力）
vm.dirty_background_ratio = 5        # 脏页达到 5% 时后台写入
vm.dirty_ratio = 10                  # 脏页达到 10% 时强制写入
vm.dirty_expire_centisecs = 12000    # 脏页过期时间 120 秒
```

### 3. CPU 调度优化

```bash
# CPU 调度器优化
kernel.sched_migration_cost_ns = 5000000      # 进程迁移成本（5ms）
kernel.sched_autogroup_enabled = 1            # 自动分组调度
kernel.sched_min_granularity_ns = 10000000    # 最小调度粒度（10ms）
kernel.sched_wakeup_granularity_ns = 15000000 # 唤醒粒度（15ms）
```

## 🔥 已移除的网络参数

以下参数对单节点 K3s 意义不大，已移除：

```bash
# 移除的 TCP 优化（过度优化）
net.core.somaxconn                           # 监听队列
net.ipv4.tcp_max_syn_backlog                 # SYN 队列
net.ipv4.tcp_fin_timeout                     # FIN 超时
net.ipv4.tcp_keepalive_*                     # TCP 保活
net.ipv4.tcp_tw_reuse                        # TIME_WAIT 重用

# 移除的连接跟踪（单节点不需要百万级）
net.netfilter.nf_conntrack_max               # 连接跟踪数
net.netfilter.nf_conntrack_tcp_timeout_*     # 连接超时
```

## 📈 优化效果

### 内存优化效果

| 参数 | 作用 | 效果 |
|------|------|------|
| `vm.dirty_background_ratio = 5` | 减少内存积压 | 避免突发大量 I/O |
| `vm.dirty_ratio = 10` | 控制脏页上限 | 防止内存耗尽 |
| `vm.min_free_kbytes = 65536` | 保留应急内存 | 避免 OOM |
| `vm.overcommit_memory = 1` | 容器内存灵活 | 提高容器密度 |

### CPU 优化效果

| 参数 | 作用 | 效果 |
|------|------|------|
| `sched_autogroup_enabled = 1` | 自动分组 | 提升交互性能 |
| `sched_min_granularity_ns` | 调度粒度 | 减少上下文切换 |
| `sched_migration_cost_ns` | 迁移成本 | 减少不必要的 CPU 迁移 |

## 🎯 针对 4C8G 的优化建议

### 内存分配建议

```
总内存: 8GB
├── 系统和 K3s: 1.5GB
├── 应用容器: 6GB
│   ├── MongoDB: 1.5GB
│   ├── Redis: 1GB
│   ├── RabbitMQ: 1.5GB
│   ├── 监控栈: 1.5GB
│   └── 其他: 0.5GB
└── 缓冲区: 0.5GB
```

### CPU 分配建议

```
总 CPU: 4 核
├── 系统和 K3s: 0.5 核
├── 应用容器: 3 核
│   ├── 数据库: 1.5 核
│   ├── 监控: 1 核
│   └── 其他: 0.5 核
└── 预留: 0.5 核
```

## 🔍 监控建议

部署后监控以下指标验证优化效果：

```bash
# 查看内存使用
free -h
cat /proc/meminfo | grep -E "Dirty|Writeback"

# 查看 CPU 调度
cat /proc/sched_debug | head -20

# 查看系统负载
uptime
vmstat 1 5

# 查看 OOM 记录
dmesg | grep -i "killed process"
```

## ⚠️ 注意事项

1. **内存超分配**：`vm.overcommit_memory = 1` 允许容器申请超过实际内存，需要监控 OOM
2. **脏页控制**：降低 `dirty_ratio` 会增加 I/O 频率，但减少内存压力
3. **CPU 调度**：调度参数可能需要根据实际负载调整

## 🔧 调优命令

```bash
# 临时调整参数（测试用）
sudo sysctl -w vm.dirty_ratio=15

# 查看当前值
sysctl vm.dirty_ratio

# 监控脏页
watch -n 1 'cat /proc/meminfo | grep -E "Dirty|Writeback"'

# 查看 OOM 分数
cat /proc/[PID]/oom_score_adj
```