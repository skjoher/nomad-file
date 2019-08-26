job "cadvisor" {
  region = "global"
  datacenters = ["dc1"]
  type = "system"

  group "monitor" {
    count = 1

    restart {
      attempts = 2
      delay    = "20s"
      mode     = "delay"
    }

    task "cadvisor" {
      driver = "docker"

      config {
        image = "google/cadvisor"
        force_pull = true
        volumes = [
          "/:/rootfs:ro",
          "/var/run:/var/run:rw",
          "/sys:/sys:ro",
          "/var/lib/docker/:/var/lib/docker:ro",
          "/cgroup:/cgroup:ro"
        ]
        port_map {
          cadvisor = 8080
        }
#        logging {
#          type = "fluentd"
#          config {
#            fluentd-address = "${NOMAD_IP_cadvisor}:24224"
#            tag = "docker.cadvisor"
#          }
#        }
      }

      service {
        name = "cadvisor"
        tags = [
          "metrics"
        ]
        port = "cadvisor"

        check {
          type = "http"
          path = "/metrics/"
          interval = "10s"
          timeout = "2s"
        }
      }

      resources {
        cpu    = 50
        memory = 100

        network {
          mbits = 1
          port "cadvisor" {
#              static = "8080"
          }
        }
      }
    }
  }
}

