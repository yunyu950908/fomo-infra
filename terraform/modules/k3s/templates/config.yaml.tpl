# K3s 服务器配置 - 最小化安装
# 版本: ${k3s_version}

# 禁用不需要的组件
disable:
%{ for addon in disabled_addons ~}
  - ${addon}
%{ endfor ~}

# 集群配置
cluster-init: true
write-kubeconfig-mode: "0644"

# 网络配置
cluster-cidr: "${cluster_cidr}"
service-cidr: "${service_cidr}"
cluster-dns: "${cluster_dns}"

# 禁用云提供商控制器
disable-cloud-controller: true

# Kubelet 配置
kubelet-arg:
  - "max-pods=${max_pods}"
  - "eviction-hard=memory.available<${memory_threshold},nodefs.available<${disk_threshold},nodefs.inodesFree<${inode_threshold},imagefs.available<${imagefs_threshold}"

# API Server 配置
kube-apiserver-arg:
  - "enable-admission-plugins=NodeRestriction,ResourceQuota"

# Flannel 网络后端
flannel-backend: "${flannel_backend}"