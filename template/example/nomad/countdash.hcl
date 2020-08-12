job "countdash" {
  datacenters = ["dc1"]
  group "api" {
    network {
      mode = "bridge"
    }

    service {
      name = "count-api"
      port = "9001"

      connect {
        sidecar_service {}
      }
      check {
        expose   = true
        name     = "api-alive"
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "web" {
      driver = "docker"
      config {
        image = "hashicorpnomad/counter-api:v1"
      }
    }
  }

  group "dashboard" {
    network {
      mode ="bridge"
      port "http" {
        static = 9002
        to     = 9002
      }
    }

    service {
      name = "count-dashboard"
      port = "9002"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "count-api"
              local_bind_port = 8080
            }
          }
        }
      }
      check {
        expose   = true
        name     = "dashboard-alive"
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "dashboard" {
      driver = "docker"
      env {
        COUNTING_SERVICE_URL = "http://${NOMAD_UPSTREAM_ADDR_count_api}"
      }
      config {
        image = "hashicorpnomad/counter-dashboard:v1"
      }
    }
  }
}
