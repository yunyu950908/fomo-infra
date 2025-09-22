# Grafana 仪表板配置

apiVersion: 1

providers:
  # 默认仪表板
  - name: 'default'
    orgId: 1
    folder: ''
    folderUid: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /opt/bitnami/grafana/dashboards/default

  # Kubernetes 相关仪表板
  - name: 'kubernetes'
    orgId: 1
    folder: 'Kubernetes'
    folderUid: 'kubernetes'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /opt/bitnami/grafana/dashboards/kubernetes

  # 数据库相关仪表板
  - name: 'database'
    orgId: 1
    folder: 'Database'
    folderUid: 'database'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /opt/bitnami/grafana/dashboards/database

  # 系统监控仪表板
  - name: 'system'
    orgId: 1
    folder: 'System'
    folderUid: 'system'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /opt/bitnami/grafana/dashboards/system