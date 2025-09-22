#!/bin/bash

# FOMO Infrastructure 系统准备脚本
# 用于准备 Ubuntu 系统以部署 K3s
# 支持 Ubuntu 20.04/22.04/24.04
# 优化版本：精简网络参数，增强 CPU 和内存优化

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
SCRIPT_VERSION="1.0.0"
LOG_FILE="/tmp/prepare-system-$(date +%Y%m%d-%H%M%S).log"

# 记录日志
log() {
    echo -e "$1" | tee -a $LOG_FILE
}

# 打印标题
print_header() {
    log "${BLUE}=========================================="
    log "$1"
    log "==========================================${NC}"
}

# 检查是否为 root 或有 sudo 权限
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        if ! sudo -n true 2>/dev/null; then
            log "${RED}错误: 此脚本需要 root 权限或 sudo 权限${NC}"
            log "请使用: sudo $0"
            exit 1
        fi
    fi
}

# 检查系统版本
check_system() {
    print_header "检查系统环境"

    # 检查是否为 Ubuntu
    if ! grep -q "Ubuntu" /etc/os-release; then
        log "${RED}警告: 此脚本专为 Ubuntu 设计，其他系统可能不兼容${NC}"
        read -p "是否继续? (y/N): " confirm
        if [[ "$confirm" != "y" ]]; then
            exit 1
        fi
    fi

    # 获取系统信息
    OS_VERSION=$(lsb_release -rs)
    OS_CODENAME=$(lsb_release -cs)
    KERNEL_VERSION=$(uname -r)
    ARCH=$(uname -m)

    log "${GREEN}✓${NC} 操作系统: Ubuntu $OS_VERSION ($OS_CODENAME)"
    log "${GREEN}✓${NC} 内核版本: $KERNEL_VERSION"
    log "${GREEN}✓${NC} 系统架构: $ARCH"

    # 检查系统资源
    TOTAL_MEM=$(free -m | awk 'NR==2{print $2}')
    TOTAL_CPU=$(nproc)
    TOTAL_DISK=$(df -h / | awk 'NR==2{print $2}')

    log ""
    log "系统资源:"
    log "  CPU 核心: $TOTAL_CPU"
    log "  内存大小: ${TOTAL_MEM}MB"
    log "  根分区大小: $TOTAL_DISK"

    # 检查最小要求（4C8G）
    if [[ $TOTAL_CPU -lt 4 ]] || [[ $TOTAL_MEM -lt 7500 ]]; then
        log "${YELLOW}警告: 系统资源低于推荐配置 (4C8G)${NC}"
        log "当前配置: ${TOTAL_CPU}C${TOTAL_MEM}MB"
        read -p "是否继续? (y/N): " confirm
        if [[ "$confirm" != "y" ]]; then
            exit 1
        fi
    fi

    echo ""
}

# 更新系统包
update_system() {
    print_header "更新系统包"

    log "更新软件包列表..."
    sudo apt update

    log "升级已安装的软件包..."
    sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y

    log "${GREEN}✓${NC} 系统更新完成"
    echo ""
}

# 安装基础依赖
install_dependencies() {
    print_header "安装基础依赖"

    local packages=(
        curl
        wget
        git
        vim
        net-tools
        software-properties-common
        apt-transport-https
        ca-certificates
        gnupg
        lsb-release
        htop
        jq
        unzip
    )

    for package in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii.*$package"; then
            log "${GREEN}✓${NC} $package 已安装"
        else
            log "安装 $package..."
            sudo DEBIAN_FRONTEND=noninteractive apt install -y $package
            log "${GREEN}✓${NC} $package 安装完成"
        fi
    done

    echo ""
}

# 配置系统时间
configure_time() {
    print_header "配置系统时间"

    # 设置时区
    log "设置时区为 Asia/Shanghai..."
    sudo timedatectl set-timezone Asia/Shanghai

    # 使用 systemd-timesyncd（更轻量）
    log "启用时间同步服务..."
    sudo systemctl enable systemd-timesyncd
    sudo systemctl restart systemd-timesyncd

    # 同步时间
    log "同步系统时间..."
    sudo timedatectl set-ntp true

    log "${GREEN}✓${NC} 当前时间: $(date)"
    echo ""
}

# 禁用 Swap
disable_swap() {
    print_header "禁用 Swap"

    # 检查当前 swap 状态
    SWAP_TOTAL=$(free -m | grep Swap | awk '{print $2}')

    if [[ $SWAP_TOTAL -eq 0 ]]; then
        log "${GREEN}✓${NC} Swap 已经禁用"
    else
        log "关闭 Swap..."
        sudo swapoff -a

        log "修改 /etc/fstab..."
        sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

        log "${GREEN}✓${NC} Swap 已禁用"
    fi

    # 验证
    free -h | grep Swap
    echo ""
}

# 配置内核模块
configure_kernel_modules() {
    print_header "配置内核模块"

    log "配置需要加载的内核模块..."
    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
# 容器运行时需要的模块
overlay
br_netfilter

# 可选的性能优化模块
nf_conntrack
EOF

    # 立即加载模块
    local modules=(overlay br_netfilter nf_conntrack)
    for module in "${modules[@]}"; do
        if lsmod | grep -q "^$module"; then
            log "${GREEN}✓${NC} 模块 $module 已加载"
        else
            log "加载模块 $module..."
            sudo modprobe $module
            log "${GREEN}✓${NC} 模块 $module 已加载"
        fi
    done

    echo ""
}

# 配置系统参数
configure_sysctl() {
    print_header "配置系统参数"

    log "配置 K3s 必需参数和性能优化..."
    cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes.conf
# Kubernetes 必需的网络参数
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1

# 文件系统
fs.file-max = 1000000
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 8192

# 内存优化（适合 4C8G 配置）
vm.max_map_count = 262144
vm.swappiness = 0
vm.overcommit_memory = 1
vm.panic_on_oom = 0
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.dirty_expire_centisecs = 12000
vm.min_free_kbytes = 65536

# CPU 调度优化
kernel.sched_migration_cost_ns = 5000000
kernel.sched_autogroup_enabled = 1
kernel.sched_min_granularity_ns = 10000000
kernel.sched_wakeup_granularity_ns = 15000000

# 进程管理
kernel.pid_max = 4194303
kernel.threads-max = 100000
EOF

    # 应用系统参数
    log "应用系统参数..."
    sudo sysctl --system

    log "${GREEN}✓${NC} 系统参数配置完成"
    echo ""
}

# 配置文件描述符限制
configure_limits() {
    print_header "配置系统限制"

    log "配置文件描述符限制..."
    cat <<EOF | sudo tee /etc/security/limits.d/99-kubernetes.conf
# 为所有用户设置限制
*    soft    nofile    65535
*    hard    nofile    131072
*    soft    nproc     65535
*    hard    nproc     131072
*    soft    memlock   unlimited
*    hard    memlock   unlimited

# 为 root 用户设置更高限制
root    soft    nofile    131072
root    hard    nofile    262144
root    soft    nproc     131072
root    hard    nproc     262144
EOF

    # 配置 systemd 限制
    log "配置 systemd 限制..."
    sudo mkdir -p /etc/systemd/system.conf.d/
    cat <<EOF | sudo tee /etc/systemd/system.conf.d/99-kubernetes.conf
[Manager]
DefaultLimitNOFILE=131072
DefaultLimitNPROC=131072
DefaultLimitMEMLOCK=infinity
DefaultTasksMax=infinity
EOF

    # 重新加载 systemd
    sudo systemctl daemon-reload

    log "${GREEN}✓${NC} 系统限制配置完成"
    echo ""
}

# 配置防火墙
configure_firewall() {
    print_header "配置防火墙"

    log "检查防火墙状态..."

    # 检查并禁用 ufw
    if command -v ufw &> /dev/null; then
        if sudo ufw status | grep -q "Status: active"; then
            log "${YELLOW}检测到 UFW 防火墙已启用${NC}"
            log "公有云环境建议使用云服务商的安全组/防火墙"
            read -p "是否禁用系统防火墙 UFW? (Y/n): " disable_ufw

            if [[ "$disable_ufw" != "n" && "$disable_ufw" != "N" ]]; then
                log "禁用 UFW 防火墙..."
                sudo ufw disable
                log "${GREEN}✓${NC} UFW 防火墙已禁用"
            else
                log "${YELLOW}⚠${NC} 保留 UFW 防火墙，请确保已配置必要端口"
                log "K3s 需要的端口："
                log "  - 6443/tcp (Kubernetes API)"
                log "  - 10250/tcp (Kubelet)"
                log "  - 30000-32767/tcp (NodePort)"
            fi
        else
            log "${GREEN}✓${NC} UFW 防火墙未启用"
        fi
    else
        log "${GREEN}✓${NC} 未安装 UFW"
    fi

    # 检查并禁用 firewalld (CentOS/RHEL)
    if command -v firewall-cmd &> /dev/null; then
        if sudo systemctl is-active firewalld &> /dev/null; then
            log "${YELLOW}检测到 firewalld 已启用${NC}"
            read -p "是否禁用 firewalld? (Y/n): " disable_firewalld

            if [[ "$disable_firewalld" != "n" && "$disable_firewalld" != "N" ]]; then
                log "禁用 firewalld..."
                sudo systemctl stop firewalld
                sudo systemctl disable firewalld
                log "${GREEN}✓${NC} firewalld 已禁用"
            fi
        else
            log "${GREEN}✓${NC} firewalld 未启用"
        fi
    fi

    # 检查 iptables 规则
    log ""
    log "当前 iptables 规则数量："
    log "  Filter 表: $(sudo iptables -L -n | wc -l) 条规则"
    log "  NAT 表: $(sudo iptables -t nat -L -n | wc -l) 条规则"

    log ""
    log "${YELLOW}重要提醒：${NC}"
    log "请在云服务商控制台配置安全组规则，开放以下端口："
    log "  - 22/tcp (SSH)"
    log "  - 6443/tcp (K8s API)"
    log "  - 30000-32767/tcp (NodePort 服务)"
    log "  - 30777/tcp (Portainer)"
    log "  - 30088/tcp (Traefik Dashboard)"
    log "  - 30030/tcp (Grafana)"
    log "  - 30090/tcp (Prometheus)"
    log "  - 30093/tcp (Alertmanager)"
    log "  - 30017/tcp (MongoDB)"
    log "  - 30379/tcp (Redis)"
    log "  - 31672/tcp (RabbitMQ)"

    echo ""
}

# 容器工具说明
show_container_tools_info() {
    print_header "容器管理工具说明"

    log "K3s 自带 containerd 作为容器运行时"
    log ""
    log "${YELLOW}K3s 内置命令：${NC}"
    log "  sudo k3s crictl ps            # 查看运行的容器"
    log "  sudo k3s crictl images        # 查看镜像"
    log "  sudo k3s crictl logs <id>     # 查看容器日志"
    log "  sudo k3s crictl exec -it <id> sh  # 进入容器"
    log ""
    log "${YELLOW}可选工具：${NC}"
    log "如需 Docker 兼容命令，可安装 nerdctl："
    log "  wget https://github.com/containerd/nerdctl/releases/download/v1.7.2/nerdctl-1.7.2-linux-amd64.tar.gz"
    log "  sudo tar -C /usr/local/bin -xzf nerdctl-*.tar.gz"

    echo ""
}

# 安装 Terraform
install_terraform() {
    print_header "安装 Terraform"

    if command -v terraform &> /dev/null; then
        CURRENT_VERSION=$(terraform version | head -1 | cut -d' ' -f2)
        log "${GREEN}✓${NC} Terraform 已安装: $CURRENT_VERSION"
    else
        log "安装 Terraform..."
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install -y terraform

        log "${GREEN}✓${NC} Terraform 安装完成"
    fi

    echo ""
}

# 安装 kubectl
install_kubectl() {
    print_header "安装 kubectl"

    if command -v kubectl &> /dev/null; then
        CURRENT_VERSION=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3)
        log "${GREEN}✓${NC} kubectl 已安装: $CURRENT_VERSION"
    else
        log "安装 kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl

        log "${GREEN}✓${NC} kubectl 安装完成"
    fi

    # 配置 kubectl 自动补全
    log "配置 kubectl 自动补全..."
    kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null

    echo ""
}

# 安装 Helm
install_helm() {
    print_header "安装 Helm"

    if command -v helm &> /dev/null; then
        CURRENT_VERSION=$(helm version --short | cut -d':' -f2 | cut -d'+' -f1)
        log "${GREEN}✓${NC} Helm 已安装: $CURRENT_VERSION"
    else
        log "安装 Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

        log "${GREEN}✓${NC} Helm 安装完成"
    fi

    # 添加常用仓库
    log "添加 Helm 仓库..."
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add stable https://charts.helm.sh/stable
    helm repo update

    echo ""
}

# 生成系统报告
generate_report() {
    print_header "系统准备报告"

    log "系统信息:"
    log "  主机名: $(hostname)"
    log "  IP 地址: $(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)"
    log "  系统版本: Ubuntu $(lsb_release -rs)"
    log "  内核版本: $(uname -r)"
    log ""

    log "配置状态:"
    log "  ${GREEN}✓${NC} Swap 已禁用"
    log "  ${GREEN}✓${NC} 内核模块已加载"
    log "  ${GREEN}✓${NC} 系统参数已优化"
    log "  ${GREEN}✓${NC} 文件限制已设置"
    log ""

    log "已安装工具:"
    command -v terraform &> /dev/null && log "  ${GREEN}✓${NC} Terraform: $(terraform version | head -1 | cut -d' ' -f2)"
    command -v kubectl &> /dev/null && log "  ${GREEN}✓${NC} kubectl: $(kubectl version --client --short 2>/dev/null | cut -d' ' -f3)"
    command -v helm &> /dev/null && log "  ${GREEN}✓${NC} Helm: $(helm version --short | cut -d':' -f2 | cut -d'+' -f1)"
    log ""

    log "下一步操作:"
    log "  1. 重启系统使所有配置生效（可选）："
    log "     ${BLUE}sudo reboot${NC}"
    log ""
    log "  2. 部署 K3s："
    log "     ${BLUE}cd fomo-infra/terraform${NC}"
    log "     ${BLUE}terraform init${NC}"
    log "     ${BLUE}terraform apply -target=module.k3s${NC}"
    log ""
    log "日志文件保存在: $LOG_FILE"
}

# 主函数
main() {
    clear
    log "${BLUE}╔══════════════════════════════════════════╗"
    log "║     FOMO Infrastructure 系统准备脚本      ║"
    log "║            版本 $SCRIPT_VERSION              ║"
    log "╚══════════════════════════════════════════╝${NC}"
    log ""
    log "此脚本将准备系统以部署 K3s 和相关基础设施"
    log "建议在全新的 Ubuntu 20.04/22.04/24.04 系统上运行"
    log ""

    read -p "是否继续? (y/N): " confirm
    if [[ "$confirm" != "y" ]]; then
        exit 0
    fi

    # 执行准备步骤
    check_privileges
    check_system
    update_system
    install_dependencies
    configure_time
    disable_swap
    configure_kernel_modules
    configure_sysctl
    configure_limits
    configure_firewall
    install_terraform
    install_kubectl
    install_helm
    show_container_tools_info
    generate_report

    log ""
    log "${GREEN}=========================================="
    log "系统准备完成！"
    log "==========================================${NC}"
}

# 执行主函数
main "$@"