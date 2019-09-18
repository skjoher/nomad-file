job "grafana" {
  datacenters = ["dc1"]
  type = "service"
  migrate {
    max_parallel = 1
    health_check = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "5m"
  }
  group "monitor" {
    count = 1
    restart {
      attempts = 2
      interval = "3m"
      delay = "15s"
      mode = "fail"
    }

    ephemeral_disk {
      sticky = true
      migrate = true
      size = 2000
    }

    task "grafana" {
      driver = "docker"
      user="root"
      config {
        image = "grafana/grafana"
        volumes =[
           "grafana_data:/var/lib/grafana",
           "provisioning:/etc/grafana/provisioning"
        ]
        port_map {
            grafanahttp = 3000
        }
        dns_servers = ["${attr.unique.network.ip-address}"]
      }
      env {
        GF_LOG_LEVEL = "DEBUG"
        GF_LOG_MODE = "console"
        PROMETHEUS_HOST = "prometheus.service.consul"
        PROMETHEUS_PORT = "9090"
        GF_PATHS_PROVISIONING = "/etc/grafana/provisioning"
      }
      artifact {
      source= "git::https://github.com/skjoher/conf-metrics"
      destination = "provisioning"
      }

      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB
        network {
          mbits = 1
          port "grafanahttp" {
            static = 3000
          }
        }
      }

      service {
        name = "grafana"
        address_mode = "host"
        port = "grafanahttp"
        tags = [
           "grafana",
           "traefik.enable=true",
           "traefik.tags=service",
           "traefik.frontend.rule=Host:monitor.0x7f.me"
        ]
        check {
          type = "http"
          path = "/api/health"
          interval = "30s"
          timeout = "2s"
        }
      }

    }
  } 
} 
