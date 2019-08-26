job "node-exporter" {
  datacenters = ["dc1"]

  type="system"


  group "monitor" {
    count = 1

    restart {
      attempts = 3
      delay    = "20s"
      mode     = "delay"
    }

    task "node-exporter" {
      driver = "docker"

      config {
        image = "prom/node-exporter:v0.17.0"
        force_pull = true
        volumes = [
          "/proc:/host/proc",
          "/sys:/host/sys",
          "/:/rootfs"
        ]
        #args = ["--collector.filesystem.ignored-mount-points","^/(sys|proc|dev|host|etc)($$|/)"]
        port_map {
          nodeexporter = 9100
          grpc = 9095
        }
#        logging {
#          type = "fluentd"
#          config {
#            fluentd-address = "${NOMAD_IP_nodeexporter}:24224"
#            tag = "docker.nodeexporter"
#          }
#        }

      }

      service {
        name = "node-exporter"
        tags = [
          "metrics"
        ]
        port = "nodeexporter"


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
          port "nodeexporter" { 
            static = "9100" 
          }
          port "grpc" {
            static = "9095"
          }
        }
      }
    }
  }
}