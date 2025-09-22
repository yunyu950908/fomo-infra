# 模块解耦设计方案

## 当前耦合问题

### 1. 模块依赖链
```
K3s
 ├── Portainer (depends_on k3s)
 ├── Traefik (depends_on k3s)
 ├── MongoDB (depends_on k3s)
 ├── Redis (depends_on k3s)
 ├── RabbitMQ (depends_on k3s)
 ├── Prometheus (depends_on k3s)
 │    └── Grafana (depends_on prometheus)
 └── Alertmanager (depends_on k3s, prometheus)
```

### 2. 硬编码的服务发现
- Prometheus 硬编码 Alertmanager 地址
- Grafana 硬编码 Prometheus 地址
- 都假设在 `infra` 命名空间

## 解耦方案

### 方案 1：移除所有 depends_on（推荐）

**main.tf 修改**：
```hcl
# 移除 depends_on，让 Terraform 自行管理依赖
module "portainer" {
  source = "./modules/portainer"

  namespace      = var.portainer_namespace
  release_name   = var.portainer_release_name
  # 不再有 depends_on = [module.k3s]
}
```

**优点**：
- 模块完全独立
- 可以单独部署任何模块
- 便于测试和维护

**缺点**：
- 需要确保 K3s 先部署
- 用户需要了解部署顺序

### 方案 2：使用变量传递服务地址

**variables.tf**：
```hcl
variable "prometheus_endpoint" {
  description = "Prometheus 服务端点"
  type        = string
  default     = ""  # 空值表示不配置
}

variable "alertmanager_endpoint" {
  description = "Alertmanager 服务端点"
  type        = string
  default     = ""  # 空值表示不配置
}
```

**main.tf**：
```hcl
module "grafana" {
  source = "./modules/grafana"

  # 通过变量传递，而不是硬编码
  prometheus_url = var.prometheus_endpoint != "" ? var.prometheus_endpoint : ""
}

module "prometheus" {
  source = "./modules/prometheus"

  # 可选的 alertmanager 配置
  alertmanager_url = var.alertmanager_endpoint
}
```

### 方案 3：使用 Kubernetes Provider 检查集群状态

**modules/base/main.tf**：
```hcl
# 基础模块，检查 K8s 是否可用
data "kubernetes_namespace" "kube_system" {
  metadata {
    name = "kube-system"
  }
}

output "cluster_ready" {
  value = data.kubernetes_namespace.kube_system.id != ""
}
```

**其他模块**：
```hcl
# 检查集群是否就绪
data "terraform_remote_state" "base" {
  backend = "local"
  config = {
    path = "../base/terraform.tfstate"
  }
}

resource "helm_release" "app" {
  count = data.terraform_remote_state.base.outputs.cluster_ready ? 1 : 0
  # ...
}
```

### 方案 4：分层部署（推荐）

创建独立的部署层：

```
terraform/
├── layer-0-k3s/           # 基础设施层
│   └── main.tf            # 只有 K3s
├── layer-1-core/          # 核心服务层
│   ├── main.tf            # Portainer, Traefik
│   └── terraform.tfvars
├── layer-2-data/          # 数据层
│   ├── main.tf            # MongoDB, Redis, RabbitMQ
│   └── terraform.tfvars
└── layer-3-monitoring/    # 监控层
    ├── main.tf            # Prometheus, Grafana, Alertmanager
    └── terraform.tfvars
```

每层独立部署：
```bash
# 按顺序部署
cd layer-0-k3s && terraform apply
cd ../layer-1-core && terraform apply
cd ../layer-2-data && terraform apply
cd ../layer-3-monitoring && terraform apply
```

## 最佳实践建议

### 1. 使用 ConfigMap 进行服务发现
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: service-discovery
  namespace: infra
data:
  prometheus.url: "http://prometheus:9090"
  alertmanager.url: "http://alertmanager:9093"
```

### 2. 使用 Kubernetes DNS
- 依赖 Kubernetes 内部 DNS 而不是硬编码
- 格式：`<service>.<namespace>.svc.cluster.local`

### 3. 使用环境变量注入
```hcl
env {
  name = "PROMETHEUS_URL"
  value = var.prometheus_url != "" ? var.prometheus_url : "http://prometheus:9090"
}
```

### 4. 条件部署
```hcl
variable "enable_monitoring" {
  type    = bool
  default = false
}

module "grafana" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/grafana"
}
```

## 推荐的最终架构

1. **完全独立的模块**
   - 每个模块不依赖其他模块
   - 通过变量传递必要的配置

2. **可选的集成**
   - 使用变量控制是否启用集成
   - 默认值允许独立运行

3. **清晰的部署顺序文档**
   - README 中说明推荐的部署顺序
   - 但不强制依赖

4. **示例配置**
   ```hcl
   # 独立部署 Prometheus
   module "prometheus" {
     source = "./modules/prometheus"
     namespace = "monitoring"
   }

   # 独立部署 Grafana
   module "grafana" {
     source = "./modules/grafana"
     namespace = "monitoring"
     # prometheus_url 是可选的
     prometheus_url = ""  # 后续手动配置
   }

   # 或集成部署
   module "grafana_integrated" {
     source = "./modules/grafana"
     namespace = "monitoring"
     prometheus_url = "http://prometheus.monitoring:9090"
   }
   ```

## 执行步骤

1. 移除所有 `depends_on`
2. 将硬编码的 URL 改为变量
3. 提供合理的默认值
4. 更新文档说明部署顺序
5. 添加环境变量或 ConfigMap 支持