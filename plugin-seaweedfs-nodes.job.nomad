job "plugin-seaweedfs-nodes" {
  datacenters = ["dc1"]

  type = "system"

  group "nodes" {
    task "plugin" {
      driver = "docker"

      config {
        image = "chrislusf/seaweedfs-csi-driver:latest"

        args = [
          "--endpoint=unix://csi/csi.sock",
          "--filer=seaweedfs-filer.service.consul:3333",
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