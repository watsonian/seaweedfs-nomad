job "plugin-seaweedfs-controller" {
  datacenters = ["dc1"]

  group "controller" {
    task "filer" {
      driver = "docker"

      template {
        destination = "config/.env"
        env = true
        data = <<-EOF
{{ range $i, $s := service "http.seaweedfs-filer" }}
{{- if eq $i 0 -}}
SEAWEEDFS_FILER_IP_http={{ .Address }}
SEAWEEDFS_FILER_PORT_http={{ .Port }}
{{- end -}}
{{ end }}
{{ range $i, $s := service "grpc.seaweedfs-filer" }}
{{- if eq $i 0 -}}
SEAWEEDFS_FILER_IP_grpc={{ .Address }}
SEAWEEDFS_FILER_PORT_grpc={{ .Port }}
{{- end -}}
{{ end }}
EOF
      }

      config {
        image = "chrislusf/seaweedfs-csi-driver:latest"

        args = [
          "--endpoint=unix://csi/csi.sock",
          "--filer=${SEAWEEDFS_FILER_IP_http}:${SEAWEEDFS_FILER_PORT_http}.${SEAWEEDFS_FILER_PORT_grpc}",
          "--nodeid=${node.unique.name}",
          "--cacheCapacityMB=1000",
          "--cacheDir=/tmp",
        ]

        volumes = [
            "config:/config"
        ]

        privileged = true
      }

      csi_plugin {
        id        = "seaweedfs"
        type      = "node"
        mount_dir = "/csi"
      }
    }
  }
}