job "prometheus" {
  datacenters = ["dc1"]
  type = "service"

  group "prometheus" {
    count = 1
    ephemeral_disk {
      size = 3000
    }

    task "prometheus" {
      template {
        change_mode = "noop"
        destination = "local/prometheus.yml"
        data = <<EOH
---
global:
  scrape_interval:     5s
  evaluation_interval: 5s

scrape_configs:

  - job_name: 'prometheus'
    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus" }}:8500'
      services: ['prometheus']

  - job_name: 'node_exporter'
    metrics_path: /metrics
    scheme: http
    consul_sd_configs:
      - server: '{{ env "NOMAD_IP_prometheus" }}:8500'
        services: ['node-exporter']
    relabel_configs:
        - source_labels: ['__meta_consul_service']
          regex:         '(.*)'
          target_label:  'job'
          replacement:   '$1'
        - source_labels: ['__meta_consul_service_address']
          regex:         '(.*)'
          target_label:  'instance'
          replacement:   '$1'
        - source_labels: ['__meta_consul_service_port']
          regex:         '(.*)'
          target_label:  'port'
          replacement:   '$1'
        - source_labels: ['__meta_consul_service_address', '__meta_consul_service_port']
          regex:         '(.*);(.*)'
          target_label:  '__address__'
          replacement:   '$1:$2'

        - source_labels: ['__meta_consul_tags']
          regex:         ',(production|canary),'
          target_label:  'group'
          replacement: '$1'

        - source_labels: [__meta_consul_tags]
          regex: ',(?:[^,]+,){0}label-([[:alnum:]]+)-([^,]+),.*'
          replacement: '${2}'
          target_label: '${1}'
        - source_labels: [__meta_consul_tags]
          regex: ',(?:[^,]+,){1}label-([[:alnum:]]+)-([^,]+),.*'
          replacement: '${2}'
          target_label: '${1}'
        - source_labels: [__meta_consul_tags]
          regex: ',(?:[^,]+,){2}label-([[:alnum:]]+)-([^,]+),.*'
          replacement: '${2}'
          target_label: '${1}'
        - source_labels: [__meta_consul_tags]
          regex: ',(?:^,]+,){3}-(label-[[:alnum:]]+)-([^,]+),.*'
          replacement: '${2}'
          target_label: '${1}'

  - job_name: 'cadvisor'
    metrics_path: /metrics
    scheme: http
    consul_sd_configs:
      - server: '{{ env "NOMAD_IP_prometheus" }}:8500'
        services: ['cadvisor']
    relabel_configs:
        - source_labels: ['__meta_consul_service']
          regex:         '(.*)'
          target_label:  'job'
          replacement:   '$1'
        - source_labels: ['__meta_consul_service_address']
          regex:         '(.*)'
          target_label:  'instance'
          replacement:   '$1'
        - source_labels: ['__meta_consul_service_address', '__meta_consul_service_port']
          regex:         '(.*);(.*)'
          target_label:  '__address__'
          replacement:   '$1:$2'

        - source_labels: [__meta_consul_tags]
          regex: ',(?:[^,]+,){0}label-([[:alnum:]]+)-([^,]+),.*'
          replacement: 'group'
          target_label: '${1}'

        - source_labels: [__meta_consul_tags]
          regex: ',(?:[^,]+,){1}label-([[:alnum:]]+)-([^,]+),.*'
          replacement: '${2}'
          target_label: '${1}'
        - source_labels: [__meta_consul_tags]
          regex: ',(?:[^,]+,){2}label-([[:alnum:]]+)-([^,]+),.*'
          replacement: '${2}'
          target_label: '${1}'
        - source_labels: [__meta_consul_tags]
          regex: ',(?:^,]+,){3}-(label-[[:alnum:]]+)-([^,]+),.*'
          replacement: '${2}'
          target_label: '${1}'

EOH
      }
      driver = "docker"
      config {
        image = "prom/prometheus:latest"
        dns_servers = ["${attr.unique.network.ip-address}"]
        hostname="prometheus"
        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml"
        ]
        port_map {
          prometheus = 9090
        }
      }
      resources {
        network {
          mbits = 1
          port "prometheus" {
            static = 9090
          }
        }
      }
      service {
        name = "prometheus"
        port = "prometheus"


        tags = [
          "prometheus",
          "traefik.enable=true",
          "traefik.tags=service",
          "traefik.frontend.rule=Host:metrics.prpl.one"
        ]

        check {
          name     = "prometheus-alive"
          port     = "prometheus"
          type     = "http"
          interval = "10s"
          timeout  = "2s"
          path     = "/"
        }
      }
    }
  }
}