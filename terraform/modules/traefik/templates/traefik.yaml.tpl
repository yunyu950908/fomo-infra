# Traefik 配置文件模板

global:
  checkNewVersion: false
  sendAnonymousUsage: false

api:
  dashboard: ${dashboard_enabled}
  debug: false
  insecure: true

entryPoints:
  web:
    address: ":80"
%{ if tls_enabled ~}
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
          permanent: true
%{ endif ~}
  websecure:
    address: ":443"
%{ if tls_enabled ~}
    http:
      tls:
        certResolver: default
%{ endif ~}
%{ if metrics_enabled ~}
  metrics:
    address: ":8082"
%{ endif ~}

providers:
  kubernetesCRD:
    allowCrossNamespace: true
    allowExternalNameServices: true
  kubernetesIngress:
    allowExternalNameServices: true
    publishedService:
      enabled: true

ping:
  entryPoint: web

log:
  level: ${log_level}
  format: json

%{ if access_log_enabled ~}
accessLog:
  format: json
  fields:
    defaultMode: keep
    headers:
      defaultMode: drop
%{ endif ~}

%{ if metrics_enabled ~}
metrics:
  prometheus:
    entryPoint: metrics
    addEntryPointsLabels: true
    addRoutersLabels: true
    addServicesLabels: true
%{ endif ~}