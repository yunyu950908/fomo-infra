#!/bin/bash

# K3s Fomo 基础设施卸载脚本

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "$${YELLOW}=== K3s 卸载程序 ===$${NC}"

# 检查是否以 root 身份运行
if [[ $EUID -ne 0 ]]; then
   echo -e "$${RED}此脚本必须以 root 身份运行$${NC}"
   exit 1
fi

# 停止并禁用 K3s 服务
echo -e "$${YELLOW}停止 K3s 服务...$${NC}"
systemctl stop k3s 2>/dev/null || true
systemctl disable k3s 2>/dev/null || true

# 运行 K3s 卸载脚本（如果存在）
if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
    echo -e "$${YELLOW}运行 K3s 卸载脚本...$${NC}"
    /usr/local/bin/k3s-uninstall.sh
fi

# 清理存储目录
echo -e "$${YELLOW}清理存储目录...$${NC}"
rm -rf ${storage_path}

# 清理配置目录
rm -rf /etc/rancher/k3s

echo -e "$${GREEN}K3s 卸载完成$${NC}"