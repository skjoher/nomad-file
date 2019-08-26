job "whoami" {
  datacenters = ["dc1"]
  type = "service"
  group "whoami" {
    count = 1
    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    task "whoami" {
      driver = "docker"

      config {
        image = "emilevauge/whoami"
        port_map {
         http = 80
        }
        dns_servers = ["${attr.unique.network.ip-address}"]
      }

      resources {
        cpu = 100
        memory = 50
        network {
          mbits = 1
          port "http" {}
        }
      }

      service {
        name = "whoami"
        tags = [
          "traefik.enable=true",
          "traefik.tags=service",
          "traefik.frontend.rule=Host:whoami.0x7f.me",
          "whoami"
        ]
        port = "http"
      }
    }
  }
}