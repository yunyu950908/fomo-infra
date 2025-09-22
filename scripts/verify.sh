#!/bin/bash

# FOMO Infrastructure 部署验证脚本
# 用于验证所有组件的部署状态和连接性

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 获取节点 IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
if [ -z "$NODE_IP" ]; then
    NODE_IP="localhost"
fi

echo "=========================================="
echo "FOMO Infrastructure 部署验证"
echo "节点 IP: $NODE_IP"
echo "=========================================="
echo ""

# 检查命名空间
check_namespace() {
    echo "检查命名空间 infra..."
    if kubectl get namespace infra &>/dev/null; then
        echo -e "${GREEN}✓${NC} 命名空间 infra 存在"
    else
        echo -e "${RED}✗${NC} 命名空间 infra 不存在"
        exit 1
    fi
    echo ""
}

# 检查服务状态
check_service() {
    local service_name=$1
    local namespace=$2
    local port=$3
    local check_url=$4

    echo "检查服务: $service_name"

    # 检查 Pod 状态
    pod_status=$(kubectl get pods -n $namespace -l app.kubernetes.io/name=$service_name -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")

    if [ "$pod_status" = "Running" ]; then
        echo -e "  ${GREEN}✓${NC} Pod 运行中"
    else
        echo -e "  ${RED}✗${NC} Pod 状态: $pod_status"
    fi

    # 检查服务端口
    if [ ! -z "$port" ]; then
        if nc -z $NODE_IP $port 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} 端口 $port 可访问"

            # 测试 HTTP 端点
            if [ ! -z "$check_url" ]; then
                if curl -s -o /dev/null -w "%{http_code}" http://$NODE_IP:$port$check_url | grep -q "200\|301\|302"; then
                    echo -e "  ${GREEN}✓${NC} HTTP 端点响应正常"
                else
                    echo -e "  ${YELLOW}⚠${NC} HTTP 端点响应异常"
                fi
            fi
        else
            echo -e "  ${YELLOW}⚠${NC} 端口 $port 无法访问"
        fi
    fi

    echo ""
}

# 检查存储
check_storage() {
    echo "检查持久化存储..."
    pvc_count=$(kubectl get pvc -n infra --no-headers 2>/dev/null | wc -l)
    bound_count=$(kubectl get pvc -n infra --no-headers 2>/dev/null | grep Bound | wc -l)

    if [ $pvc_count -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} 发现 $pvc_count 个 PVC"
        echo -e "  ${GREEN}✓${NC} $bound_count 个 PVC 已绑定"

        # 列出 PVC 状态
        kubectl get pvc -n infra | tail -n +2 | while read line; do
            pvc_name=$(echo $line | awk '{print $1}')
            status=$(echo $line | awk '{print $2}')
            if [ "$status" = "Bound" ]; then
                echo -e "    ${GREEN}✓${NC} $pvc_name: $status"
            else
                echo -e "    ${YELLOW}⚠${NC} $pvc_name: $status"
            fi
        done
    else
        echo -e "  ${YELLOW}⚠${NC} 未发现 PVC"
    fi
    echo ""
}

# 主检查流程
main() {
    check_namespace

    echo "=========================================="
    echo "检查核心组件"
    echo "=========================================="
    echo ""

    # 检查 Portainer
    check_service "portainer" "infra" "30777" "/"

    # 检查 Traefik
    check_service "traefik" "infra" "30088" "/dashboard/"

    echo "=========================================="
    echo "检查数据库组件"
    echo "=========================================="
    echo ""

    # 检查 MongoDB
    check_service "mongodb" "infra" "30017" ""

    # 检查 Redis
    check_service "redis" "infra" "30379" ""

    # 检查 RabbitMQ
    check_service "rabbitmq" "infra" "31672" "/"

    echo "=========================================="
    echo "检查监控组件"
    echo "=========================================="
    echo ""

    # 检查 Prometheus
    check_service "prometheus" "infra" "30090" "/-/healthy"

    # 检查 Grafana
    check_service "grafana" "infra" "30030" "/api/health"

    # 检查 Alertmanager
    check_service "alertmanager" "infra" "30093" "/-/healthy"

    echo "=========================================="
    echo "检查存储状态"
    echo "=========================================="
    echo ""

    check_storage

    echo "=========================================="
    echo "服务访问地址"
    echo "=========================================="
    echo ""

    echo "Portainer:      http://$NODE_IP:30777"
    echo "Traefik:        http://$NODE_IP:30088/dashboard/"
    echo "MongoDB:        mongodb://$NODE_IP:30017"
    echo "Redis:          redis://$NODE_IP:30379"
    echo "RabbitMQ:       http://$NODE_IP:31672"
    echo "Prometheus:     http://$NODE_IP:30090"
    echo "Grafana:        http://$NODE_IP:30030"
    echo "Alertmanager:   http://$NODE_IP:30093"
    echo ""

    echo "=========================================="
    echo "验证完成"
    echo "=========================================="
}

# 执行主函数
main