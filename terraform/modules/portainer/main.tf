# Portainer 商业版模块
# 用于部署容器管理界面

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# 创建命名空间
resource "kubernetes_namespace" "portainer" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "portainer"
      "app.kubernetes.io/instance" = var.release_name
    }
  }
}

# 创建服务账户
resource "kubernetes_service_account" "portainer" {
  metadata {
    name      = "${var.release_name}-sa-clusteradmin"
    namespace = kubernetes_namespace.portainer.metadata[0].name
  }
}

# 创建集群角色绑定
resource "kubernetes_cluster_role_binding" "portainer" {
  metadata {
    name = "${var.release_name}-crb-clusteradmin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.portainer.metadata[0].name
    namespace = kubernetes_namespace.portainer.metadata[0].name
  }
}

# 创建持久卷声明
resource "kubernetes_persistent_volume_claim" "portainer" {
  metadata {
    name      = "${var.release_name}-pvc"
    namespace = kubernetes_namespace.portainer.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class

    resources {
      requests = {
        storage = var.storage_size
      }
    }
  }
}

# 创建服务
resource "kubernetes_service" "portainer" {
  metadata {
    name      = var.release_name
    namespace = kubernetes_namespace.portainer.metadata[0].name
  }

  spec {
    type = "NodePort"

    selector = {
      app = var.release_name
    }

    port {
      name        = "http"
      port        = 9000
      target_port = 9000
      node_port   = var.http_node_port
      protocol    = "TCP"
    }

    port {
      name        = "https"
      port        = 9443
      target_port = 9443
      protocol    = "TCP"
    }

    port {
      name        = "edge"
      port        = 8000
      target_port = 8000
      node_port   = var.edge_node_port
      protocol    = "TCP"
    }
  }
}

# 创建部署
resource "kubernetes_deployment" "portainer" {
  metadata {
    name      = var.release_name
    namespace = kubernetes_namespace.portainer.metadata[0].name

    labels = {
      app = var.release_name
    }
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

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
        service_account_name = kubernetes_service_account.portainer.metadata[0].name

        container {
          name              = var.release_name
          image             = "${var.image_repository}:${var.image_tag}"
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = 9000
            protocol       = "TCP"
          }

          port {
            name           = "https"
            container_port = 9443
            protocol       = "TCP"
          }

          port {
            name           = "tcp-edge"
            container_port = 8000
            protocol       = "TCP"
          }

          volume_mount {
            name       = "portainer-data"
            mount_path = "/data"
          }

          env {
            name  = "LOG_LEVEL"
            value = var.log_level
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
              path   = "/"
              port   = 9443
              scheme = "HTTPS"
            }
            initial_delay_seconds = 60
            period_seconds        = 30
          }

          readiness_probe {
            http_get {
              path   = "/"
              port   = 9443
              scheme = "HTTPS"
            }
            initial_delay_seconds = 15
            period_seconds        = 10
          }
        }

        volume {
          name = "portainer-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.portainer.metadata[0].name
          }
        }
      }
    }
  }
}