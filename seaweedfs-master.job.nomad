job "seaweedfs-master" {
  datacenters = ["dc1"]
  type = "service"

  group "master" {
    network {
      mode = "host"

      port "http" {}

      port "grpc" {}
    }

    volume "seaweedfs-master" {
        type      = "host"
        read_only = false
        source    = "seaweedfs-master"
    }

    service {
      tags = ["${NOMAD_ALLOC_INDEX}", "seaweedfs", "master", "http"]
      name = "seaweedfs-master"
      port = "http"
    }

    service {
      tags = ["${NOMAD_ALLOC_INDEX}", "seaweedfs", "master", "grpc"]
      name = "seaweedfs-master"
      port = "grpc"
    }

    task "seaweed" {
      driver = "docker"

      volume_mount {
        volume      = "seaweedfs-master"
        destination = "/data"
        read_only   = false
      }

      config {
        image = "chrislusf/seaweedfs"

        args = [
          "-logtostderr",
          "master",
          "-ip=${NOMAD_IP_http}",
          "-ip.bind=0.0.0.0",
          "-mdir=/data",
          "-port=${NOMAD_PORT_http}",
          "-port.grpc=${NOMAD_PORT_grpc}"
        ]

        volumes = [
            "config:/config"
        ]

        ports = ["http", "grpc"]

        privileged = true
      }
    }
  }
}