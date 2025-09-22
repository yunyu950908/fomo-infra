# Grafana 数据源配置

apiVersion: 1

datasources:
  # Prometheus 主数据源
  - name: Prometheus
    type: prometheus
    access: proxy
    url: ${prometheus_url}
    isDefault: true
    editable: true
    jsonData:
      httpMethod: POST
      queryTimeout: 30s
      timeInterval: 30s
      exemplarTraceIdDestinations:
        - name: trace_id
          datasourceUid: jaeger
      prometheusType: Prometheus
      prometheusVersion: 2.48.0
      cacheLevel: 'High'
    secureJsonData: {}

  # TestData 数据源（用于测试）
  - name: TestData
    type: testdata
    access: proxy
    isDefault: false
    editable: false