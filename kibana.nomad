job "kibana" {
  datacenters = ["dev"]

  type = "service"

  group "kibana" {
    count = 1

    task "kibana" {
      driver = "docker"

      env {
        ELASTICSEARCH_URL="http://elasticsearch.service.consul:9200"
      }

      config {
        image = "docker.elastic.co/kibana/kibana-oss:6.3.1"
        dns_servers = ["${attr.unique.network.ip-address}"]
        port_map {
          ui=5601
        }
      }

      resources {
        cpu    = 100
        memory = 256

        network {
          mbits = 1
          port "ui" {}
        }
      }

      service {
        name = "kibana"
        port = "ui"
        address_mode="driver"

        tags =[
           "traefik.enable=true",
           "traefik.tags=service",
           "traefik.frontend.rule=Host:kibana.0x7f.me"
        ]

        check {
          name     = "kibana-logs-alive"
          address_mode="host"
          port     = "ui"
          type     = "http"
          interval = "10s"
          timeout  = "2s"
          path     = "/"
        }
      }
    }
  }
}

