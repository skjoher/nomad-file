job "elasticsearch" {
  datacenters = ["dc1"]

  type = "service"

  group "elasticsearch" {
    count = 1

    task "elasticsearch" {
      driver = "docker"

      env {
        ES_JAVA_OPTS="-Xmx700m -Xms700m"
        http.host="0.0.0.0"
      }

      config {
        image = "docker.elastic.co/elasticsearch/elasticsearch-oss:6.7.1"
        dns_servers = ["${attr.unique.network.ip-address}"]
        port_map = {
          http=9200
        }
        hostname="elasticsearch"
      }

      resources {
        cpu    = 500
        memory = 750

        network {
          port "http" {}
        }
      }

      service {
        name = "elasticsearch"
        port = "http"

        tags =[
          "traefik.tags=service",
          "traefik.enable=true",
          "traefik.frontend.rule=PathPrefix:/es/"
        ]

        check {
          name     = "es-alive"
          port     = "http"
          type     = "http"
          address_mode="host"
          interval = "10s"
          timeout  = "2s"
          path     = "/"
        }
      }
    }
  }
}
