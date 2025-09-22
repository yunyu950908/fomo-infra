# Traefik 入口控制器模块
# 用于部署现代化反向代理和负载均衡器

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

# 获取 Traefik CRD
data "http" "traefik_crds" {
  url = "https://raw.githubusercontent.com/traefik/traefik/v${var.traefik_version}/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml"
}

# 应用 Traefik CRD
resource "kubernetes_manifest" "traefik_crds" {
  for_each = {
    for doc in split("---", data.http.traefik_crds.response_body) :
    yamldecode(doc).metadata.name => yamldecode(doc)
    if doc != "" && can(yamldecode(doc).metadata.name)
  }

  manifest = each.value

  depends_on = []
}

# 创建命名空间
resource "kubernetes_namespace" "traefik" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "traefik"
      "app.kubernetes.io/instance" = var.release_name
    }
  }
}

# 创建服务账户
resource "kubernetes_service_account" "traefik" {
  metadata {
    name      = var.release_name
    namespace = kubernetes_namespace.traefik.metadata[0].name
  }
}

# 创建集群角色
resource "kubernetes_cluster_role" "traefik" {
  metadata {
    name = var.release_name
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "secrets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses", "ingressclasses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses/status"]
    verbs      = ["update"]
  }

  rule {
    api_groups = ["traefik.io", "traefik.containo.us"]
    resources = [
      "middlewares", "middlewaretcps", "ingressroutes", "traefikservices",
      "ingressroutetcps", "ingressrouteudps", "tlsoptions", "tlsstores",
      "serverstransports", "serverstransporttcps"
    ]
    verbs = ["get", "list", "watch"]
  }
}

# 创建集群角色绑定
resource "kubernetes_cluster_role_binding" "traefik" {
  metadata {
    name = var.release_name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.traefik.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.traefik.metadata[0].name
    namespace = kubernetes_namespace.traefik.metadata[0].name
  }
}

# 创建配置映射
resource "kubernetes_config_map" "traefik_config" {
  metadata {
    name      = "${var.release_name}-config"
    namespace = kubernetes_namespace.traefik.metadata[0].name
  }

  data = {
    "traefik.yaml" = templatefile("${path.module}/templates/traefik.yaml.tpl", {
      log_level           = var.log_level
      access_log_enabled  = var.access_log_enabled
      dashboard_enabled   = var.dashboard_enabled
      metrics_enabled     = var.metrics_enabled
      tls_enabled         = var.tls_enabled
    })
  }
}

# 创建服务
resource "kubernetes_service" "traefik" {
  metadata {
    name      = var.release_name
    namespace = kubernetes_namespace.traefik.metadata[0].name
  }

  spec {
    type = "NodePort"

    selector = {
      app = var.release_name
    }

    port {
      name        = "web"
      port        = 80
      target_port = "web"
      node_port   = var.web_node_port
      protocol    = "TCP"
    }

    port {
      name        = "websecure"
      port        = 443
      target_port = "websecure"
      node_port   = var.websecure_node_port
      protocol    = "TCP"
    }

    port {
      name        = "dashboard"
      port        = 8080
      target_port = "dashboard"
      node_port   = var.dashboard_node_port
      protocol    = "TCP"
    }
  }
}

# 创建部署
resource "kubernetes_deployment" "traefik" {
  depends_on = [kubernetes_manifest.traefik_crds]

  metadata {
    name      = var.release_name
    namespace = kubernetes_namespace.traefik.metadata[0].name

    labels = {
      app = var.release_name
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.release_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.release_name
        }
      }

      spec {
        service_account_name = kubernetes_service_account.traefik.metadata[0].name

        container {
          name              = var.release_name
          image             = "${var.image_repository}:v${var.traefik_version}"
          image_pull_policy = "IfNotPresent"

          args = [
            "--configfile=/config/traefik.yaml"
          ]

          port {
            name           = "web"
            container_port = 80
            protocol       = "TCP"
          }

          port {
            name           = "websecure"
            container_port = 443
            protocol       = "TCP"
          }

          port {
            name           = "dashboard"
            container_port = 8080
            protocol       = "TCP"
          }

          port {
            name           = "metrics"
            container_port = 8082
            protocol       = "TCP"
          }

          volume_mount {
            name       = "config"
            mount_path = "/config"
            read_only  = true
          }

          resources {
            requests = {
              memory = var.resources.requests.memory
              cpu    = var.resources.requests.cpu
            }
            limits = {
              memory = var.resources.limits.memory
              cpu    = var.resources.limits.cpu
            }
          }

          liveness_probe {
            http_get {
              path = "/ping"
              port = "web"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/ping"
              port = "web"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }

          security_context {
            capabilities {
              drop = ["ALL"]
            }
            read_only_root_filesystem = true
            run_as_non_root           = true
            run_as_user               = 65532
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.traefik_config.metadata[0].name
          }
        }
      }
    }
  }
}

# 创建入口类
resource "kubernetes_ingress_class_v1" "traefik" {
  metadata {
    name = var.release_name
    annotations = {
      "ingressclass.kubernetes.io/is-default-class" = var.set_as_default_ingress_class ? "true" : "false"
    }
  }

  spec {
    controller = "traefik.io/ingress-controller"
  }
}