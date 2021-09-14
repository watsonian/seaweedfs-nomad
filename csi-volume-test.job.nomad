job "csi-volume-test" {
  datacenters = ["dc1"]

  group "cache" {
    network {
      port "db" {
        to = 6379
      }
    }

    volume "csi-volume-test" {
      type      = "csi"
      read_only = false
      source    = "swfs1"
      access_mode = "single-node-writer"
      attachment_mode = "file-system"
    }

    task "redis" {
      driver = "docker"

      volume_mount {
        volume      = "csi-volume-test"
        destination = "/seaweed"
        read_only   = false
      }

      config {
        image = "redis:3.2"

        ports = ["db"]
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
