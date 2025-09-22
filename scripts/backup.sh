#!/bin/bash

# FOMO Infrastructure 备份脚本
# 用于备份所有组件的数据和配置

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 备份配置
BACKUP_DIR="/tmp/fomo-backup-$(date +%Y%m%d-%H%M%S)"
NAMESPACE="infra"

echo "=========================================="
echo "FOMO Infrastructure 备份"
echo "备份目录: $BACKUP_DIR"
echo "=========================================="
echo ""

# 创建备份目录
mkdir -p $BACKUP_DIR/{configs,data,terraform}

# 备份 Terraform 状态
backup_terraform() {
    echo "备份 Terraform 状态..."
    if [ -f "terraform/terraform.tfstate" ]; then
        cp terraform/terraform.tfstate $BACKUP_DIR/terraform/
        cp terraform/terraform.tfstate.backup $BACKUP_DIR/terraform/ 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Terraform 状态已备份"
    else
        echo -e "${YELLOW}⚠${NC} 未找到 Terraform 状态文件"
    fi
    echo ""
}

# 备份 MongoDB
backup_mongodb() {
    echo "备份 MongoDB..."
    local pod=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=mongodb -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [ ! -z "$pod" ]; then
        # 执行 mongodump
        kubectl exec -n $NAMESPACE $pod -- mongodump --archive=/tmp/mongodb-backup.archive
        # 复制到本地
        kubectl cp $NAMESPACE/$pod:/tmp/mongodb-backup.archive $BACKUP_DIR/data/mongodb-backup.archive
        echo -e "${GREEN}✓${NC} MongoDB 数据已备份"
    else
        echo -e "${YELLOW}⚠${NC} MongoDB Pod 未找到"
    fi
    echo ""
}

# 备份 Redis
backup_redis() {
    echo "备份 Redis..."
    local pod=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=redis -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [ ! -z "$pod" ]; then
        # 触发 Redis 持久化
        kubectl exec -n $NAMESPACE $pod -- redis-cli -a RedisSecure2024! BGSAVE
        sleep 5
        # 复制 RDB 文件
        kubectl cp $NAMESPACE/$pod:/bitnami/redis/data/dump.rdb $BACKUP_DIR/data/redis-dump.rdb
        echo -e "${GREEN}✓${NC} Redis 数据已备份"
    else
        echo -e "${YELLOW}⚠${NC} Redis Pod 未找到"
    fi
    echo ""
}

# 备份 RabbitMQ
backup_rabbitmq() {
    echo "备份 RabbitMQ..."
    local pod=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=rabbitmq -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [ ! -z "$pod" ]; then
        # 导出定义
        kubectl exec -n $NAMESPACE $pod -- rabbitmqctl export_definitions /tmp/rabbitmq-definitions.json
        # 复制到本地
        kubectl cp $NAMESPACE/$pod:/tmp/rabbitmq-definitions.json $BACKUP_DIR/configs/rabbitmq-definitions.json
        echo -e "${GREEN}✓${NC} RabbitMQ 配置已备份"
    else
        echo -e "${YELLOW}⚠${NC} RabbitMQ Pod 未找到"
    fi
    echo ""
}

# 备份 Grafana
backup_grafana() {
    echo "备份 Grafana..."
    local pod=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [ ! -z "$pod" ]; then
        # 备份 Grafana 数据
        kubectl exec -n $NAMESPACE $pod -- tar czf /tmp/grafana-backup.tar.gz /opt/bitnami/grafana/data
        # 复制到本地
        kubectl cp $NAMESPACE/$pod:/tmp/grafana-backup.tar.gz $BACKUP_DIR/data/grafana-backup.tar.gz
        echo -e "${GREEN}✓${NC} Grafana 数据已备份"
    else
        echo -e "${YELLOW}⚠${NC} Grafana Pod 未找到"
    fi
    echo ""
}

# 备份 Portainer
backup_portainer() {
    echo "备份 Portainer..."
    local pod=$(kubectl get pods -n $NAMESPACE -l app=portainer -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [ ! -z "$pod" ]; then
        # 备份 Portainer 数据
        kubectl exec -n $NAMESPACE $pod -- tar czf /tmp/portainer-backup.tar.gz /data
        # 复制到本地
        kubectl cp $NAMESPACE/$pod:/tmp/portainer-backup.tar.gz $BACKUP_DIR/data/portainer-backup.tar.gz
        echo -e "${GREEN}✓${NC} Portainer 数据已备份"
    else
        echo -e "${YELLOW}⚠${NC} Portainer Pod 未找到"
    fi
    echo ""
}

# 备份 Prometheus
backup_prometheus() {
    echo "备份 Prometheus 配置..."
    # 导出配置
    kubectl get configmap -n $NAMESPACE -l app.kubernetes.io/name=prometheus -o yaml > $BACKUP_DIR/configs/prometheus-configmaps.yaml
    echo -e "${GREEN}✓${NC} Prometheus 配置已备份"
    echo ""
}

# 备份 Alertmanager
backup_alertmanager() {
    echo "备份 Alertmanager 配置..."
    # 导出配置
    kubectl get configmap -n $NAMESPACE -l app.kubernetes.io/name=alertmanager -o yaml > $BACKUP_DIR/configs/alertmanager-configmaps.yaml
    kubectl get secret -n $NAMESPACE -l app.kubernetes.io/name=alertmanager -o yaml > $BACKUP_DIR/configs/alertmanager-secrets.yaml
    echo -e "${GREEN}✓${NC} Alertmanager 配置已备份"
    echo ""
}

# 创建备份归档
create_archive() {
    echo "创建备份归档..."
    cd /tmp
    tar czf fomo-backup-$(date +%Y%m%d-%H%M%S).tar.gz $(basename $BACKUP_DIR)
    local archive_path="/tmp/fomo-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    echo -e "${GREEN}✓${NC} 备份归档创建完成: $archive_path"
    echo ""

    # 计算归档大小
    local size=$(du -h $archive_path | cut -f1)
    echo "归档大小: $size"
    echo ""
}

# 主备份流程
main() {
    echo "开始备份..."
    echo ""

    backup_terraform
    backup_mongodb
    backup_redis
    backup_rabbitmq
    backup_grafana
    backup_portainer
    backup_prometheus
    backup_alertmanager

    create_archive

    echo "=========================================="
    echo "备份完成"
    echo "备份目录: $BACKUP_DIR"
    echo "=========================================="
}

# 执行主函数
main