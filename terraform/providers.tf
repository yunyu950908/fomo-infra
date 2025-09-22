# FOMO Infrastructure Provider 配置

# Kubernetes Provider
provider "kubernetes" {
  config_path    = "/etc/rancher/k3s/k3s.yaml"
  config_context = "default"
}

# Helm Provider
provider "helm" {
  kubernetes {
    config_path    = "/etc/rancher/k3s/k3s.yaml"
    config_context = "default"
  }

  # 设置 Helm 配置
  repository_config_path = "~/.config/helm/repositories.yaml"
  repository_cache       = "~/.cache/helm/repository"
}