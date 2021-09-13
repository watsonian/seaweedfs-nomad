job "plugin-seaweedfs-nodes" {
  datacenters = ["dc1"]

  type = "system"

  group "nodes" {
    task "plugin" {
      driver = "docker"

      config {
        image = "chrislusf/seaweedfs-csi-driver:latest"

      template {
        destination = "config/.env"
        env = true
        data = <<-EOF
{{ range $i, $s := service "http.seaweedfs-master" }}
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

        args = [
          "--endpoint=unix://csi/csi.sock",
          "--filer=${SEAWEEDFS_FILER_IP_http}:${SEAWEEDFS_FILER_PORT_http}.${SEAWEEDFS_FILER_PORT_grpc}",
          "--nodeid=${node.unique.name}",
          "--cacheCapacityMB=1000",
          "--cacheDir=/tmp",
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