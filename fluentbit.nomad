job "fluentbit" {
  datacenters = ["dev"]

  type="system"

  group "fluentbit" {
    count = 1

    task "fluentbit" {
      template {
        change_mode = "noop"
        destination = "local/fluent-bit.conf"
        data = <<EOH
[SERVICE]

    Flush        5
    Daemon       Off
    Log_Level    info
#   Parsers_File parsers.conf
    HTTP_Server  on
    HTTP_Listen  0.0.0.0
    HTTP_Port    2020

# [INPUT]
#     Name cpu
#     Tag  cpu.local
#     # Interval Sec
#     # ====
#     # Read interval (sec) Default: 1
#     Interval_Sec 1

[INPUT]
    Name   forward
    Listen 0.0.0.0
    Port   24225

# [INPUT]
#     Name        tail
#     Path        /var/log/docker.log
#     Tag         docker

[INPUT]
    Name        tail
    Path        /var/log/*.log
    Tag         varlog

[OUTPUT]
    Name   stdout
    Match  *
#[OUTPUT]
#    Name          forward
#    Match         *
#    Host          192.168.100.200
#    Port          24224
[OUTPUT]
    Name  es
    Match *
    Host  192.168.100.200
    Port  9200
    Index dev_index
    Type  dev_type
EOH
      }
      driver = "raw_exec"

      config {
        command = "fluent-bit"
        args    = [
          "-c", "local/fluent-bit.conf",
        ]

      }
      artifact {
        source = "https://raw.githubusercontent.com/skjoher/conf-log/master/fluent-bit"
      }
      resources {
        cpu    = 200
        memory = 128
        network {
          mbits = 1
          port "fluentbit" { 
            static=24225
          }
          port "monitor" {}
        }
      }

      service {
        name = "fluentbit"
        port = "fluentbit"

        tags=[
           "fluentbit"
        ]

 #       check {
 #         name     = "fluentbit-api-alive"
 #         type     = "http"
 #         method    = "GET"
 #         path     = "/metrics"
 #         interval = "10s"
 #         timeout  = "2s"
 #         port     = "monitor"
 #         address_mode="host"
 #       }
      }
    }
  }
}

