# Some-crazy-docker-play-around

In this test we are going to try to put all this pieces together **ceph + ocfs2 + etcd + docker + swarm + registry**

## Why ceph?

Why not?.
Basically I was trying to find some hi availability solution to support the registry service, the idea was to alocate the container file into some sort of distributed storage without using external storages.

## Why OCFS2?

The idea was to provide a clustered file system to support ceph, and OCFS it really ease to setup.

## Hosts

```
192.168.122.105     test01
192.168.122.177     test02
192.168.122.106     test03
```

## CEPH Cluster

### Install ceph-deploy tool

```sh
cephadmin@test01:~/ceph$ apt install ceph-deploy
```

### Set new cluster with initial mon nodes

```sh
cephadmin@test01:~/ceph$ ceph-deploy new test01 test02
```

### ceph.conf

```
[global]
fsid = 25343005-d497-472c-9646-e6e2e99efe68
mon_initial_members = test01, test02
mon_host = 192.168.122.105,192.168.122.177
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
filestore_xattr_use_omap = true
# Initial pool size
osd pool default size = 2
# Set network
public network = 192.168.122.0/24
```

### Install ceph packages

```sh
cephadmin@test01:~/ceph$ ceph-deploy install test01 test02 test03
```

### Install initial mons

```sh
cephadmin@test01:~/ceph$ ceph-deploy mon create
```

### Gather keys

```sh
cephadmin@test01:~/ceph$ ceph-deploy gatherkeys test01
cephadmin@test02:~/ceph$ ceph-deploy gatherkeys test01
cephadmin@test03:~/ceph$ ceph-deploy gatherkeys test01
```

### Prepare admin hosts

```sh
cephadmin@test01:~/ceph$ ceph-deploy admin test01 test02 test03
```

### Config pull

```sh
cephadmin@test02:~/ceph$ ceph-deploy config pull test01
cephadmin@test03:~/ceph$ ceph-deploy config pull test01
```

### Prepare OSD

```sh
cephadmin@test01:~/ceph$ ceph-deploy osd prepare test01:/mnt/ceph test02:/mnt/ceph
cephadmin@test01:~/ceph$ ceph-deploy osd activate test01:/mnt/ceph test02:/mnt/ceph
```

## Expand Cluster

### Expand mons

```sh
cephadmin@test01:~/ceph$ ceph-deploy mon add test03
```

### Expand OSD

```sh
cephadmin@test01:~/ceph$ ceph-deploy osd prepare test03:/mnt/ceph
cephadmin@test01:~/ceph$ ceph-deploy osd activate test03:/mnt/ceph
```

### Cluster Status

```sh
cephadmin@test01:~/ceph$ sudo ceph status
    cluster 25343005-d497-472c-9646-e6e2e99efe68
     health HEALTH_OK
     monmap e2: 3 mons at {test01=192.168.122.105:6789/0,test02=192.168.122.177:6789/0,test03=192.168.122.106:6789/0}, election epoch 8, quorum 0,1,2 test01,test03,test02
     osdmap e13: 3 osds: 3 up, 3 in
      pgmap v80: 192 pgs, 3 pools, 0 bytes data, 0 objects
            15463 MB used, 45943 MB / 61407 MB avail
                 192 active+clean
```

### Metadata server

```sh
cephadmin@test01:~/ceph$ ceph-deploy mds create test01 test02 test03
```

## Block Device

### Configure Block device

```sh
cephadmin@test01:~/ceph$ rbd create registry --size 20480 -m test01 -k ./ceph.client.admin.keyring
```

### Map ceph block device

```sh
cephadmin@test01:~/ceph$ sudo rbd map registry --name client.admin -m test01
cephadmin@test02:~/ceph$ sudo rbd map registry --name client.admin -m test01
cephadmin@test03:~/ceph$ sudo rbd map registry --name client.admin -m test01
```

### OCFS2

#### Install OCFS2

Install ocfs2 and minimal X components on all nodes

```sh
sudo apt install ocfs2-tools ocfs2console x11-apps
```

Create FS on ceph block device

```sh
cephadmin@test01:~/ceph$ sudo mkfs.ocfs2 /dev/rbd/rbd/registry
```

Enable OCFS2 services on boot

```sh
/etc/init.d/o2cb enable
```

#### OCFS2 Cluster Conf

**/etc/ocfs2/cluster.conf**

```
cluster:
    node_count = 3
    name = docker-registry
node:
    ip_port = 7777
    ip_address = 192.168.122.105
    number = 1
    name = test01
    cluster = docker-registry
node:
    ip_port = 7777
    ip_address = 192.168.122.177
    number = 2
    name = test02
    cluster = docker-registry
node:
    ip_port = 7777
    ip_address = 192.168.122.106
    number = 3
    name = test03
    cluster = docker-registry
```

Replicate conf and copy `/etc/ocfs2/cluster.conf` to all nodes, and run:

#### Config & Start Services

```sh
cephadmin@test01:~$ sudo dpkg-reconfigure ocfs2-tools
cephadmin@test01:~$ sudo /etc/init.d/o2cb restart
cephadmin@test01:~$ sudo /etc/init.d/ocfs2 start
```

#### Mount OCFS

```sh
sudo mkdir -p /mnt/registry
echo "/dev/rbd/rbd/registry   /mnt/registry   ocfs2   noauto,_netdev,defaults   0 0" | \
sudo tee -a /etc/fstab
sudo mount -a
```

## Docker Swarm & ETCD discovery

### Install Docker

```sh
#!/bin/bash
set -e
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
sudo apt-get install -y linux-image-extra-$(uname -r) docker-engine
sudo sed -i '/GRUB_CMDLINE_LINUX\=\"\"/c\GRUB_CMDLINE_LINUX\=\"cgroup_enable\=memory swapaccount\=1\"' /etc/default/grub
sudo update-grub
echo 'DOCKER_OPTS="-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock"' | \
sudo tee -a /etc/default/docker
sudo shutdown -r now
```

### ETCD

#### test01 (node 1)

```sh
docker run -d -v /usr/share/ca-certificates/:/etc/ssl/certs -p 4001:4001 -p 2380:2380 -p 2379:2379 \
  --restart=always \
  --name etcd quay.io/coreos/etcd:v2.2.2 \
  -name test01 \
  -advertise-client-urls http://192.168.122.105:2379,http://192.168.122.105:4001 \
  -listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
  -initial-advertise-peer-urls http://192.168.122.105:2380 \
  -listen-peer-urls http://0.0.0.0:2380 \
  -initial-cluster-token etcd-cluster-1 \
  -initial-cluster test01=http://192.168.122.105:2380,test02=http://192.168.122.177:2380,test03=http://192.168.122.106:2380 \
  -initial-cluster-state new
```

#### test02 (node 2)

```sh
docker run -d -v /usr/share/ca-certificates/:/etc/ssl/certs -p 4001:4001 -p 2380:2380 -p 2379:2379 \
  --restart=always \
  --name etcd quay.io/coreos/etcd:v2.2.2 \
  -name test02 \
  -advertise-client-urls http://192.168.122.177:2379,http://192.168.122.177:4001 \
  -listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
  -initial-advertise-peer-urls http://192.168.122.177:2380 \
  -listen-peer-urls http://0.0.0.0:2380 \
  -initial-cluster-token etcd-cluster-1 \
  -initial-cluster test01=http://192.168.122.105:2380,test02=http://192.168.122.177:2380,test03=http://192.168.122.106:2380 \
  -initial-cluster-state new
```

#### test03 (node 3)

```sh
docker run -d -v /usr/share/ca-certificates/:/etc/ssl/certs -p 4001:4001 -p 2380:2380 -p 2379:2379 \
  --restart=always \
  --name etcd quay.io/coreos/etcd:v2.2.2 \
  -name test03 \
  -advertise-client-urls http://192.168.122.106:2379,http://192.168.122.106:4001 \
  -listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
  -initial-advertise-peer-urls http://192.168.122.106:2380 \
  -listen-peer-urls http://0.0.0.0:2380 \
  -initial-cluster-token etcd-cluster-1 \
  -initial-cluster test01=http://192.168.122.105:2380,test02=http://192.168.122.177:2380,test03=http://192.168.122.106:2380 \
  -initial-cluster-state new
```

#### Join node to existing cluster

Just change the "-initial-cluster-state" state to existing:
`-initial-cluster-state existing`

#### Test etcd cluster

```sh
docker exec etcd /etcdctl \
  -C http://192.168.122.105:2379,http://192.168.122.177:2379,http://192.168.122.106:2379 member list
```

### Swarm

#### Nodes

Run this on all swarm nodes

```sh
docker run -d --name swarmnode \
  --restart=always \
  swarm join \
  --addr=$(ip addr show dev eth0 | grep "inet " | awk '{ print $2 }' | awk -F \/ '{ print $1 }'):2375 \
  etcd://192.168.122.105:4001,192.168.122.177:4001,192.168.122.106:4001/swarm
```

#### Manage

```sh
docker run -p 2376:2375 -d \
  --restart=always \
  --name swarmmanage \
  swarm manage \
  -H tcp://0.0.0.0:2375 \
  etcd://192.168.122.105:4001,192.168.122.177:4001,192.168.122.106:4001/swarm
```

#### Docker Host env var

Informar al docker client como conectar al swarm, donde en el ejemplo test01 es en donde corrimos el master

```sh
export DOCKER_HOST='tcp://test01:2376'
```

#### test swarm

```sh
docker info
```

## Docker Registry

### Reference

https://docs.docker.com/registry/deploying/

### Some background information
Watch out for `DOCKER_HOST` env variable, this define on which manager will run the docker, for this test we want to run against to local docker not the swarm.
Unset env variable:

```sh
unset DOCKER_HOST
```

Set env variable, where test01 it's where our manager it's running

```sh
export DOCKER_HOST='tcp://test01:2376'
```

#### Work directories

Lab dir structure:

```
/mnt/registry
├── certs
├── docker-registry
```

### Registry run

#### Basic docker registry run

This command use a local dir (`/mnt/registry/docker-registry`) for the registry storage

```sh
docker run -d -p 5000:5000 --restart=always --name registry \
  -v /mnt/registry/docker-registry:/var/lib/registry \
  registry:2
```

#### Self signed registry certificates

Generate certs, don't forget use a FQDN domain, for this example will use `myregistry.mydomain`

```sh
cd /mnt/registry
mkdir -p certs && openssl req \
  -newkey rsa:4096 -nodes -sha256 -keyout certs/domain.key \
  -x509 -days 365 -out certs/domain.crt
```

##### Prepare docker to accept certs

Prepare docker to accept self signed sertificates

```sh
mkdir -p /etc/docker/certs.d/myregistry.mydomain:5000/
cp /mnt/registry/certs/domain.crt /etc/docker/certs.d/myregistry.mydomain\:5000/ca.crt
service docker restart
```

#### Docker registry with self signed certs

Start the docker registry container with the new self signed certs

```sh
docker run -d -p 5000:5000 --restart=always --name registry \
  -v /mnt/registry/certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:2
```

### Tag & Push images

We are goind to pull an image from HUB, tagit and then pushit to our local registry

```sh
docker pull ubuntu
docker tag ubuntu myregistry.mydomain:5000/ubuntu
docker push myregistry.mydomain:5000/ubuntu
```

