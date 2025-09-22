# K3s 集群模块
# 用于部署轻量级 Kubernetes 集群

terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# 创建 K3s 配置文件
resource "local_file" "k3s_config" {
  content = templatefile("${path.module}/templates/config.yaml.tpl", {
    k3s_version        = var.k3s_version
    cluster_cidr       = var.cluster_cidr
    service_cidr       = var.service_cidr
    cluster_dns        = var.cluster_dns
    disabled_addons    = var.disabled_addons
    flannel_backend    = var.flannel_backend
    max_pods           = var.max_pods
    memory_threshold   = var.memory_threshold
    disk_threshold     = var.disk_threshold
    inode_threshold    = var.inode_threshold
    imagefs_threshold  = var.imagefs_threshold
  })
  filename        = "/tmp/k3s-config.yaml"
  file_permission = "0644"
}

# 创建本地路径存储配置
resource "local_file" "local_path_config" {
  content = templatefile("${path.module}/templates/local-path-config.yaml.tpl", {
    storage_path = var.storage_path
  })
  filename        = "/tmp/local-path-config.yaml"
  file_permission = "0644"
}

# 创建存储目录
resource "null_resource" "create_storage_dir" {
  provisioner "local-exec" {
    command = "sudo mkdir -p ${var.storage_path} && sudo chmod 0777 ${var.storage_path}"
  }
}

# 检查 K3s 是否已安装
data "external" "k3s_check" {
  program = ["bash", "-c", "which k3s >/dev/null 2>&1 && echo '{\"installed\":\"true\"}' || echo '{\"installed\":\"false\"}'"]
}

# 卸载现有 K3s（如果存在）
resource "null_resource" "uninstall_existing_k3s" {
  count = data.external.k3s_check.result.installed == "true" ? 1 : 0

  provisioner "local-exec" {
    command = "sudo /usr/local/bin/k3s-uninstall.sh || true"
  }
}

# 复制 K3s 配置文件到系统目录
resource "null_resource" "copy_k3s_config" {
  depends_on = [
    local_file.k3s_config,
    null_resource.uninstall_existing_k3s
  ]

  provisioner "local-exec" {
    command = <<-EOT
      sudo mkdir -p /etc/rancher/k3s
      sudo cp ${local_file.k3s_config.filename} /etc/rancher/k3s/config.yaml
    EOT
  }

  # 当配置文件内容变化时重新触发
  triggers = {
    config_content = local_file.k3s_config.content
  }
}

# 安装 K3s
resource "null_resource" "install_k3s" {
  depends_on = [
    null_resource.copy_k3s_config,
    null_resource.create_storage_dir
  ]

  provisioner "local-exec" {
    command = <<-EOT
      curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${var.k3s_version}" INSTALL_K3S_EXEC="server" sh -
    EOT
  }

  # 等待 K3s 启动
  provisioner "local-exec" {
    command = <<-EOT
      echo "等待 K3s 启动..."
      for i in {1..30}; do
        if sudo k3s kubectl get nodes >/dev/null 2>&1; then
          echo "K3s 已就绪!"
          break
        fi
        echo "等待中... ($i/30)"
        sleep 2
      done
    EOT
  }
}

# 配置本地路径存储
resource "null_resource" "configure_storage" {
  depends_on = [
    null_resource.install_k3s,
    local_file.local_path_config,
    null_resource.setup_kubeconfig
  ]

  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
      sudo k3s kubectl apply -f ${local_file.local_path_config.filename}
      sudo k3s kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    EOT
  }
}

# 设置 kubeconfig 权限
resource "null_resource" "setup_kubeconfig" {
  depends_on = [null_resource.install_k3s]

  provisioner "local-exec" {
    command = <<-EOT
      if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
        sudo mkdir -p /home/$SUDO_USER/.kube
        sudo cp /etc/rancher/k3s/k3s.yaml /home/$SUDO_USER/.kube/config
        sudo chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.kube
      fi
    EOT
  }
}

# 获取集群信息
data "external" "cluster_info" {
  depends_on = [null_resource.install_k3s]

  program = ["bash", "-c", <<-EOT
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "")
    echo "{\"node_ip\":\"$NODE_IP\"}"
  EOT
  ]
}

# 创建卸载脚本
resource "local_file" "uninstall_script" {
  content = templatefile("${path.module}/templates/uninstall.sh.tpl", {
    storage_path = var.storage_path
  })
  filename        = "/tmp/k3s-fomo-uninstall.sh"
  file_permission = "0755"
}

# 复制卸载脚本到系统目录
resource "null_resource" "copy_uninstall_script" {
  depends_on = [local_file.uninstall_script]

  provisioner "local-exec" {
    command = "sudo cp ${local_file.uninstall_script.filename} /usr/local/bin/k3s-fomo-uninstall.sh && sudo chmod +x /usr/local/bin/k3s-fomo-uninstall.sh"
  }
}