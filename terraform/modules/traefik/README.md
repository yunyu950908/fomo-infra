# Traefik 模块

Traefik 3.0 现代化边缘路由器和负载均衡器，提供自动服务发现和 HTTPS 支持。

## 特性

- **版本**: Traefik 3.0.0
- **架构**: 单副本（可扩展）
- **仪表板**: 启用 Web UI
- **外部访问**: HTTP 30080, HTTPS 30443, Dashboard 30088
- **服务发现**: Kubernetes CRD 和 Ingress
- **中间件**: 安全头、限流、压缩

## 配置参数

| 参数 | 默认值 | 说明 |
|-----|--------|------|
| `namespace` | infra | 部署命名空间 |
| `release_name` | traefik | Helm 发布名称 |
| `traefik_version` | 3.0.0 | Traefik 版本 |
| `web_node_port` | 30080 | HTTP NodePort |
| `websecure_node_port` | 30443 | HTTPS NodePort |
| `dashboard_node_port` | 30088 | Dashboard NodePort |
| `log_level` | INFO | 日志级别 |
| `dashboard_enabled` | true | 启用仪表板 |
| `metrics_enabled` | true | 启用 Prometheus 指标 |

### 资源配置

| 资源 | 请求 | 限制 |
|------|------|------|
| CPU | 50m | 200m |
| 内存 | 32Mi | 100Mi |

## 使用方法

### 基础使用

```hcl
module "traefik" {
  source = "./modules/traefik"
}
```

### 自定义配置

```hcl
module "traefik" {
  source = "./modules/traefik"

  namespace = "ingress"
  traefik_version = "3.0.0"

  web_node_port = 31080
  websecure_node_port = 31443
  dashboard_node_port = 31088

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
  access_log_enabled = true
  tls_enabled = true

  replicas = 2
}
```

## 访问方式

### Dashboard

```bash
# Web 界面
http://<NODE_IP>:30088/dashboard/

# 注意：URL 必须以 /dashboard/ 结尾（包含斜杠）

# 端口转发（本地访问）
kubectl port-forward -n infra svc/traefik 8080:8080
```

### API 访问

```bash
# 获取路由器列表
curl http://<NODE_IP>:30088/api/http/routers

# 获取服务列表
curl http://<NODE_IP>:30088/api/http/services

# 获取中间件列表
curl http://<NODE_IP>:30088/api/http/middlewares

# 健康检查
curl http://<NODE_IP>:30088/ping
```

## 路由配置

### IngressRoute (推荐)

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: my-app
  namespace: default
spec:
  entryPoints:
    - web
    - websecure
  routes:
    - match: Host(`app.example.com`)
      kind: Rule
      services:
        - name: my-app-service
          port: 80
      middlewares:
        - name: my-middleware
```

### Kubernetes Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  namespace: default
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  ingressClassName: traefik
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app-service
                port:
                  number: 80
```

## 中间件配置

### 安全头中间件

```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: security-headers
  namespace: infra
spec:
  headers:
    frameDeny: true
    browserXssFilter: true
    contentTypeNosniff: true
    stsSeconds: 31536000
    stsIncludeSubdomains: true
    stsPreload: true
    customResponseHeaders:
      X-Custom-Header: "Custom Value"
```

### 限流中间件

```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: rate-limit
  namespace: infra
spec:
  rateLimit:
    average: 100
    burst: 200
    period: 1m
    sourceCriterion:
      ipStrategy:
        depth: 1
```

### 认证中间件

```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: basic-auth
  namespace: infra
spec:
  basicAuth:
    secret: authsecret
    realm: "Restricted Area"
    removeHeader: true
---
# 创建认证密钥
# htpasswd -nb admin password | base64
apiVersion: v1
kind: Secret
metadata:
  name: authsecret
  namespace: infra
data:
  users: YWRtaW46JGFwcjEkWVdYLkVDNDEkLjkxSTNVTkRWT2VGQXAva25TZGl5Lgo=
```

### 重定向中间件

```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: redirect-https
  namespace: infra
spec:
  redirectScheme:
    scheme: https
    permanent: true
```

### 压缩中间件

```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: compress
  namespace: infra
spec:
  compress:
    excludedContentTypes:
      - text/event-stream
```

## TLS 配置

### 自动 HTTPS (Let's Encrypt)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: traefik-config
  namespace: infra
data:
  traefik.yml: |
    certificatesResolvers:
      letsencrypt:
        acme:
          email: admin@example.com
          storage: /data/acme.json
          httpChallenge:
            entryPoint: web
          # 测试环境使用 staging
          # caServer: https://acme-staging-v02.api.letsencrypt.org/directory
```

### 自定义证书

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
  namespace: infra
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTi... # base64 编码的证书
  tls.key: LS0tLS1CRUdJTi... # base64 编码的私钥
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: secure-app
  namespace: infra
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`secure.example.com`)
      kind: Rule
      services:
        - name: app-service
          port: 80
  tls:
    secretName: tls-secret
```

## 负载均衡

### 配置策略

```yaml
apiVersion: traefik.io/v1alpha1
kind: TraefikService
metadata:
  name: weighted-service
  namespace: infra
spec:
  weighted:
    services:
      - name: app-v1
        port: 80
        weight: 80
      - name: app-v2
        port: 80
        weight: 20
```

### 会话亲和

```yaml
apiVersion: traefik.io/v1alpha1
kind: TraefikService
metadata:
  name: sticky-service
  namespace: infra
spec:
  weighted:
    services:
      - name: app-service
        port: 80
        sticky:
          cookie:
            name: server_id
            secure: true
            httpOnly: true
            sameSite: strict
```

### 健康检查

```yaml
apiVersion: traefik.io/v1alpha1
kind: TraefikService
metadata:
  name: health-checked-service
  namespace: infra
spec:
  weighted:
    services:
      - name: app-service
        port: 80
        healthCheck:
          path: /health
          interval: 10s
          timeout: 3s
          scheme: http
```

## 监控配置

### Prometheus 指标

```bash
# 指标端点
http://<NODE_IP>:30088/metrics

# 常用指标
traefik_service_requests_total          # 请求总数
traefik_service_request_duration_seconds # 请求延迟
traefik_service_open_connections        # 打开的连接数
traefik_entrypoint_requests_total       # 入口点请求数
traefik_entrypoint_request_duration_seconds # 入口点延迟
```

### Grafana 仪表板

推荐仪表板 ID：
- **Traefik 2**: 11462
- **Traefik Official**: 17346

### 访问日志

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: traefik-config
  namespace: infra
data:
  traefik.yml: |
    accessLog:
      filePath: /logs/access.log
      format: json
      filters:
        statusCodes:
          - "200-299"
          - "400-499"
          - "500-599"
      fields:
        defaultMode: keep
        headers:
          defaultMode: drop
          names:
            User-Agent: keep
            X-Real-Ip: keep
```

## 高级功能

### 链路追踪

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: traefik-config
  namespace: infra
data:
  traefik.yml: |
    tracing:
      serviceName: traefik
      spanNameLimit: 0
      jaeger:
        samplingServerURL: http://jaeger.infra:5778/sampling
        localAgentHostPort: jaeger.infra:6831
        gen128Bit: true
        propagation: jaeger
        traceContextHeaderName: uber-trace-id
```

### 插件系统

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: traefik-config
  namespace: infra
data:
  traefik.yml: |
    experimental:
      plugins:
        example:
          moduleName: github.com/traefik/plugin-example
          version: v0.1.0
```

### TCP/UDP 路由

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRouteTCP
metadata:
  name: tcp-route
  namespace: infra
spec:
  entryPoints:
    - tcp
  routes:
    - match: HostSNI(`*`)
      services:
        - name: tcp-service
          port: 3306
---
apiVersion: traefik.io/v1alpha1
kind: IngressRouteUDP
metadata:
  name: udp-route
  namespace: infra
spec:
  entryPoints:
    - udp
  routes:
    - services:
        - name: udp-service
          port: 53
```

## 运维管理

### 查看状态

```bash
# 查看 Pod 状态
kubectl get pods -n infra -l app.kubernetes.io/name=traefik

# 查看日志
kubectl logs -f deployment/traefik -n infra

# 查看配置
kubectl get configmap traefik-config -n infra -o yaml

# 查看路由
kubectl get ingressroute -A

# 查看中间件
kubectl get middleware -A
```

### 动态配置

```bash
# 实时重载配置
kubectl rollout restart deployment/traefik -n infra

# 查看配置变更
kubectl describe deployment/traefik -n infra
```

### 调试模式

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: traefik-config
  namespace: infra
data:
  traefik.yml: |
    log:
      level: DEBUG
    api:
      debug: true
```

## 故障排查

### 路由不工作

```bash
# 检查路由配置
kubectl get ingressroute <route-name> -n <namespace> -o yaml

# 查看 Traefik 日志
kubectl logs deployment/traefik -n infra | grep <route-name>

# 检查服务端点
kubectl get endpoints <service-name> -n <namespace>

# 测试服务连接
kubectl exec -it deployment/traefik -n infra -- curl service-name.namespace:port
```

### 证书问题

```bash
# 查看证书存储
kubectl exec -it deployment/traefik -n infra -- cat /data/acme.json

# 检查证书 Secret
kubectl get secret -n infra | grep tls

# 查看证书详情
kubectl get secret <tls-secret> -n infra -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text
```

### 性能问题

```bash
# 查看资源使用
kubectl top pod -n infra -l app.kubernetes.io/name=traefik

# 查看连接数
curl http://<NODE_IP>:30088/metrics | grep open_connections

# 查看请求延迟
curl http://<NODE_IP>:30088/metrics | grep request_duration
```

## 安全配置

### 限制 Dashboard 访问

```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: dashboard-auth
  namespace: infra
spec:
  basicAuth:
    secret: dashboard-auth-secret
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: traefik-dashboard
  namespace: infra
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`traefik.example.com`)
      kind: Rule
      services:
        - name: api@internal
          kind: TraefikService
      middlewares:
        - name: dashboard-auth
```

### IP 白名单

```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: ip-whitelist
  namespace: infra
spec:
  ipWhiteList:
    sourceRange:
      - 192.168.1.0/24
      - 10.0.0.0/8
    ipStrategy:
      depth: 2
```

### 安全头配置

```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: security-headers
  namespace: infra
spec:
  headers:
    frameDeny: true
    browserXssFilter: true
    contentTypeNosniff: true
    forceSTSHeader: true
    stsIncludeSubdomains: true
    stsPreload: true
    stsSeconds: 63072000
    customResponseHeaders:
      X-Frame-Options: "SAMEORIGIN"
      Content-Security-Policy: "default-src 'self'"
      X-Content-Type-Options: "nosniff"
      Referrer-Policy: "strict-origin-when-cross-origin"
```

## 最佳实践

1. **使用 IngressRoute**: 比传统 Ingress 更灵活
2. **启用访问日志**: 便于故障排查
3. **配置健康检查**: 确保服务可用性
4. **使用中间件**: 增强安全性和功能
5. **监控集成**: 接入 Prometheus 和 Grafana

## 性能优化

### 连接池配置

```yaml
serversTransport:
  insecureSkipVerify: false
  maxIdleConnsPerHost: 200
  forwardingTimeouts:
    dialTimeout: 30s
    responseHeaderTimeout: 30s
    idleConnTimeout: 90s
```

### 缓冲区配置

```yaml
entryPoints:
  web:
    address: ":80"
    transport:
      respondingTimeouts:
        readTimeout: 30s
        writeTimeout: 30s
        idleTimeout: 180s
```

## 升级指南

```bash
# 备份配置
kubectl get configmap -n infra -o yaml > traefik-backup.yaml

# 更新版本
# 修改 variables.tf 中的 traefik_version

# 应用更新
terraform apply -target=module.traefik

# 验证版本
kubectl exec -it deployment/traefik -n infra -- traefik version
```

## 相关文档

- [Traefik 官方文档](https://doc.traefik.io/traefik/)
- [Traefik CRD 参考](https://doc.traefik.io/traefik/reference/dynamic-configuration/kubernetes-crd/)
- [Traefik Helm Chart](https://github.com/traefik/traefik-helm-chart)
- [Traefik 插件目录](https://plugins.traefik.io/)