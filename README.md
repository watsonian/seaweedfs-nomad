# Deploying SeaweedFS as a CSI Driver in Nomad

This set of jobs will deploy [SeaweedFS](https://github.com/chrislusf/seaweedfs)
in Nomad and then run the [SeaweedFS CSI Driver](https://github.com/seaweedfs/seaweedfs-csi-driver)
to allow for persistent volumes on tasks.

So far, this is a fairly basic setup, but will be expanded over time to get it
more production ready.

# Nomad Configuration

Before you begin, make sure your Nomad configuration files have the following:

## clients

A sample Nomad client configuration file is supplied for reference named
`nomad-client-config-example.hcl`. The important changes are listed below.

### Allow privileged docker containers

Enable `allow_privileged` in the docker plugin config:

```
plugin "docker" {
  config {
    allow_privileged = true
  }
}
```

### Setup for volume nodes

Make sure you add a `seaweedfs_volume` meta field set to `true` on any clients
you want to be used as SeaweedFS volume servers.

```
client {
  ...

  meta {
    seaweedfs_volume = true
  }
}
```

Any client with this set will have the `seaweedfs-volume` task run on it. All
clients running the `seaweedfs-volume` job requires a `host_volume` named
`seaweedfs-volume` to be setup:

```
client {
  ...

  host_volume "seaweedfs-volume" {
    path      = "/path/to/volume/directory"
    read_only = false
  }
}
```

### Setup for master and filer nodes

You'll want to setup exactly one client to have the following volumes (it can
be the same client or separate clients):

```
client {
  ...

  host_volume "seaweedfs-master" {
    path      = "/path/to/volume/directory"
    read_only = false
  }

  host_volume "seaweedfs-filer" {
    path      = "/path/to/volume/directory"
    read_only = false
  }
}
```

Which client has these volumes setup on them will dictate which client is used
to run the task for the filer and master.

# Deploying SeaweedFS

Before you can install and run the plugin, you need to deploy SeaweedFS itself.
To do that, simply run the following commands in the specified order:

```
nomad run seaweedfs-master.job.nomad
nomad run seaweedfs-filer.job.nomad
nomad run seaweedfs-volumes.job.nomad
```

At this point, you should have one `seaweed-master` task running, one `seaweed-filer`
task running, and a `seaweedfs-volume` task running for every client you set
`meta.seaweedfs_volume` for.

# Deploying the SeaweedFS CSI Driver

To deploy the CSI driver, run the following Nomad job:

```
nomad run seaweedfs-plugin.job.nomad
```

This will run a `seaweedfs-plugin` task on every Nomad node in your cluster.

# Deploying a test job

Now that the infrastructure that's required to support SeaweedFS CSI volumes is
setup, let's create a test job that uses a CSI volume.

## Create Nomad CSI Volume

To create a CSI volume, run the following command:

```
nomad volume create csi-volume-test-volume.hcl
```

If this was successful, you should be able to get details on the volume status
by running:

```
nomad volume status swfs1
```

## Deploy the test job

Now we simply need to deploy a job that makes use of the volume we just created.
To do that, run the following job:

```
nomad run csi-volume-test.job.nomad
```

This is just a modified version of the example job you get with `nomad job init -short`.
The main items of note are that you have to define a `volume` at the group level
for the CSI volume and then mount that volume with a `volume_mount` stanza at
the task level.

Once the task is running, exec into the task and run:

```
echo "hello there from $HOSTNAME!" > /seaweed/hello
```

Now disconnect and stop the task. A new one should get started automatically.
Exec into this new allocation and then run the following:

```
cat /seaweed/hello
echo $HOSTNAME
```

You should see the content you echo'd into the file from the previous allocation
in the file and can compare the allocation ID from the current host with the one
in the file.