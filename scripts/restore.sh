#!/bin/bash

# FOMO Infrastructure 恢复脚本
# 用于从备份恢复所有组件的数据和配置

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 恢复配置
NAMESPACE="infra"

# 检查参数
if [ $# -ne 1 ]; then
    echo -e "${RED}错误: 请指定备份文件路径${NC}"
    echo "用法: $0 <backup-archive.tar.gz>"
    exit 1
fi

BACKUP_ARCHIVE=$1

if [ ! -f "$BACKUP_ARCHIVE" ]; then
    echo -e "${RED}错误: 备份文件不存在: $BACKUP_ARCHIVE${NC}"
    exit 1
fi

echo "=========================================="
echo "FOMO Infrastructure 恢复"
echo "备份文件: $BACKUP_ARCHIVE"
echo "=========================================="
echo ""

# 解压备份
extract_backup() {
    echo "解压备份文件..."
    TEMP_DIR="/tmp/restore-$(date +%Y%m%d-%H%M%S)"
    mkdir -p $TEMP_DIR
    tar xzf $BACKUP_ARCHIVE -C $TEMP_DIR
    BACKUP_DIR=$(find $TEMP_DIR -maxdepth 1 -type d -name "fomo-backup-*" | head -1)

    if [ -z "$BACKUP_DIR" ]; then
        echo -e "${RED}错误: 无效的备份文件格式${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓${NC} 备份文件已解压到: $BACKUP_DIR"
    echo ""
}

# 恢复 MongoDB
restore_mongodb() {
    echo "恢复 MongoDB..."
    local pod=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=mongodb -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [ ! -z "$pod" ] && [ -f "$BACKUP_DIR/data/mongodb-backup.archive" ]; then
        # 复制备份文件到 Pod
        kubectl cp $BACKUP_DIR/data/mongodb-backup.archive $NAMESPACE/$pod:/tmp/
        # 恢复数据
        kubectl exec -n $NAMESPACE $pod -- mongorestore --archive=/tmp/mongodb-backup.archive --drop
        echo -e "${GREEN}✓${NC} MongoDB 数据已恢复"
    else
        echo -e "${YELLOW}⚠${NC} 跳过 MongoDB 恢复"
    fi
    echo ""
}

# 恢复 Redis
restore_redis() {
    echo "恢复 Redis..."
    local pod=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=redis -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [ ! -z "$pod" ] && [ -f "$BACKUP_DIR/data/redis-dump.rdb" ]; then
        # 停止 Redis
        kubectl exec -n $NAMESPACE $pod -- redis-cli -a RedisSecure2024! SHUTDOWN
        # 复制 RDB 文件
        kubectl cp $BACKUP_DIR/data/redis-dump.rdb $NAMESPACE/$pod:/bitnami/redis/data/dump.rdb
        # 重启 Pod
        kubectl delete pod -n $NAMESPACE $pod
        echo -e "${GREEN}✓${NC} Redis 数据已恢复（Pod 重启中）"
    else
        echo -e "${YELLOW}⚠${NC} 跳过 Redis 恢复"
    fi
    echo ""
}

# 恢复 RabbitMQ
restore_rabbitmq() {
    echo "恢复 RabbitMQ..."
    local pod=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=rabbitmq -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [ ! -z "$pod" ] && [ -f "$BACKUP_DIR/configs/rabbitmq-definitions.json" ]; then
        # 复制配置文件到 Pod
        kubectl cp $BACKUP_DIR/configs/rabbitmq-definitions.json $NAMESPACE/$pod:/tmp/
        # 导入定义
        kubectl exec -n $NAMESPACE $pod -- rabbitmqctl import_definitions /tmp/rabbitmq-definitions.json
        echo -e "${GREEN}✓${NC} RabbitMQ 配置已恢复"
    else
        echo -e "${YELLOW}⚠${NC} 跳过 RabbitMQ 恢复"
    fi
    echo ""
}

# 恢复 Grafana
restore_grafana() {
    echo "恢复 Grafana..."
    local pod=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [ ! -z "$pod" ] && [ -f "$BACKUP_DIR/data/grafana-backup.tar.gz" ]; then
        # 复制备份文件到 Pod
        kubectl cp $BACKUP_DIR/data/grafana-backup.tar.gz $NAMESPACE/$pod:/tmp/
        # 恢复数据
        kubectl exec -n $NAMESPACE $pod -- tar xzf /tmp/grafana-backup.tar.gz -C /
        # 重启 Pod
        kubectl delete pod -n $NAMESPACE $pod
        echo -e "${GREEN}✓${NC} Grafana 数据已恢复（Pod 重启中）"
    else
        echo -e "${YELLOW}⚠${NC} 跳过 Grafana 恢复"
    fi
    echo ""
}

# 恢复 Portainer
restore_portainer() {
    echo "恢复 Portainer..."
    local pod=$(kubectl get pods -n $NAMESPACE -l app=portainer -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [ ! -z "$pod" ] && [ -f "$BACKUP_DIR/data/portainer-backup.tar.gz" ]; then
        # 复制备份文件到 Pod
        kubectl cp $BACKUP_DIR/data/portainer-backup.tar.gz $NAMESPACE/$pod:/tmp/
        # 恢复数据
        kubectl exec -n $NAMESPACE $pod -- tar xzf /tmp/portainer-backup.tar.gz -C /
        # 重启 Pod
        kubectl delete pod -n $NAMESPACE $pod
        echo -e "${GREEN}✓${NC} Portainer 数据已恢复（Pod 重启中）"
    else
        echo -e "${YELLOW}⚠${NC} 跳过 Portainer 恢复"
    fi
    echo ""
}

# 等待 Pod 就绪
wait_for_pods() {
    echo "等待所有 Pod 就绪..."
    local timeout=300
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        not_ready=$(kubectl get pods -n $NAMESPACE --no-headers | grep -v "Running\|Completed" | wc -l)
        if [ $not_ready -eq 0 ]; then
            echo -e "${GREEN}✓${NC} 所有 Pod 已就绪"
            break
        fi
        echo "等待中... ($not_ready Pod 未就绪)"
        sleep 5
        elapsed=$((elapsed + 5))
    done
    echo ""
}

# 主恢复流程
main() {
    extract_backup

    echo "开始恢复..."
    echo ""

    # 询问确认
    echo -e "${YELLOW}警告: 恢复操作将覆盖现有数据${NC}"
    read -p "确定要继续吗? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "恢复已取消"
        exit 0
    fi
    echo ""

    restore_mongodb
    restore_redis
    restore_rabbitmq
    restore_grafana
    restore_portainer

    wait_for_pods

    # 清理临时文件
    rm -rf $TEMP_DIR

    echo "=========================================="
    echo "恢复完成"
    echo "=========================================="
    echo ""
    echo "请运行以下命令验证服务状态:"
    echo "./scripts/verify.sh"
}

# 执行主函数
main