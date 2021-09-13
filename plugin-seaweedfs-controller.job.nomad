job "plugin-seaweedfs-controller" {
  datacenters = ["dc1"]

  group "controller" {
    task "filer" {
      driver = "docker"

      template {
        env = true
        data = <<-EOF
{{ range $i, $s := service "seaweedfs-master" }}
{{- if eq $i 0 -}}
SEAWEEDFS_FILER_PORT={{ .Port }}
{{- end -}}
{{ end }}
EOF
      }

      config {
        image = "chrislusf/seaweedfs-csi-driver:latest"

        args = [
          "--endpoint=unix://csi/csi.sock",
          "--filer=seaweedfs-filer.service.consul:${SEAWEEDFS_FILER_PORT}",
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