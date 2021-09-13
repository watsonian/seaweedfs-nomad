job "seaweedfs-volumes" {
  datacenters = ["dc1"]
  type = "system"

    constraint {
        attribute = "${meta.seaweedfs_volume}"
        value = true
    }

  group "volumes" {
    network {
      mode = "host"

      port "http" {}

      port "grpc" {}
    }

    volume "seaweedfs-volume" {
        type      = "host"
        read_only = false
        source    = "seaweedfs-volume"
    }

    service {
      tags = ["seaweedfs", "volume", "http"]
      name = "seaweedfs-volume"
      port = "http"
    }

    service {
      tags = ["seaweedfs", "volume", "grpc"]
      name = "seaweedfs-volume"
      port = "grpc"
    }

    task "seaweed" {
      driver = "docker"

      template {
        destination = "config/.env"
        env = true
        data = <<-EOF
{{ range $i, $s := service "http.seaweedfs-master" }}
{{- if eq $i 0 -}}
SEAWEEDFS_MASTER_IP_http={{ .Address }}
SEAWEEDFS_MASTER_PORT_http={{ .Port }}
{{- end -}}
{{ end }}
{{ range $i, $s := service "grpc.seaweedfs-master" }}
{{- if eq $i 0 -}}
SEAWEEDFS_MASTER_IP_grpc={{ .Address }}
SEAWEEDFS_MASTER_PORT_grpc={{ .Port }}
{{- end -}}
{{ end }}
EOF
      }

      volume_mount {
        volume      = "seaweedfs-volume"
        destination = "/data"
        read_only   = false
      }

      config {
        image = "chrislusf/seaweedfs"

        args = [
          "-logtostderr",
          "volume",
          "-ip=${NOMAD_IP_http}",
          "-ip.bind=0.0.0.0",
          "-mserver=${SEAWEEDFS_MASTER_IP_http}:${SEAWEEDFS_MASTER_PORT_http}.${SEAWEEDFS_MASTER_PORT_grpc}",
          "-dir=/data/${node.unique.name}",
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