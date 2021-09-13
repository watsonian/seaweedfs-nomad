job "seaweedfs-filer" {
  datacenters = ["dc1"]
  type = "service"

  group "filer" {
    network {
      mode = "host"

      port "http" {}

      port "grpc" {}
    }

    volume "seaweedfs-filer" {
        type      = "host"
        read_only = false
        source    = "seaweedfs-filer"
    }

    service {
      tags = ["seaweedfs", "filer", "http"]
      name = "seaweedfs-filer"
      port = "http"
    }

    service {
      tags = ["seaweedfs", "filer", "grpc"]
      name = "seaweedfs-filer"
      port = "grpc"
    }

    task "filer" {
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

      config {
        image = "chrislusf/seaweedfs"

        args = [
          "-logtostderr",
          "filer",
          "-ip=${NOMAD_IP_http}",
          "-ip.bind=0.0.0.0",
          "-master=${SEAWEEDFS_MASTER_IP_http}:${SEAWEEDFS_MASTER_PORT_http}.${SEAWEEDFS_MASTER_PORT_grpc}",
          "-port=${NOMAD_PORT_http}",
          "-port.grpc=${NOMAD_PORT_grpc}"
        ]

        ports = ["http", "grpc"]
      }
    }
  }
}
