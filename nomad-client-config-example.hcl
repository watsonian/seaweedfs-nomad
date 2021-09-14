data_dir = "/tmp/data-nomad"

bind_addr = "0.0.0.0"

log_level = "trace"

advertise {
    http = "{{ GetInterfaceIP \"eth1\" }}"
    rpc  = "{{ GetInterfaceIP \"eth1\" }}"
    serf = "{{ GetInterfaceIP \"eth1\" }}"
}

server {
    enabled = false
}

client {
  enabled = true

  meta {
    seaweedfs_volume = true
  }

  host_volume "seaweedfs-master" {
    path      = "/vagrant/host_volumes/seaweedfs/master"
    read_only = false
  }

  host_volume "seaweedfs-filer" {
    path      = "/vagrant/host_volumes/seaweedfs/filer"
    read_only = false
  }

  host_volume "seaweedfs-volume" {
    path      = "/vagrant/host_volumes/seaweedfs/volume"
    read_only = false
  }
}

plugin "docker" {
  config {
    allow_privileged = true
  }
}

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics       = true
  prometheus_metrics         = true
}
