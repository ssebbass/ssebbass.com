---
layout: post
title: Playing with docker and zabbix
comments: true
---

Where are going to play with zabbix running in a docker container, the idea it's to test some basic utilization.

## Install basic docker env
I prefer to play with Ubuntu Server, but feel free to use any distro you want, you can always refer to [docker docs](https://docs.docker.com/linux/step_one/>) to get some more information, the install instructions for Ubuntu are:

```sh
wget -qO- https://get.docker.com/ | sh
```

Check docker:

```sh
docker run hello-world
```

## Installing the basic db
Refer to:
<https://github.com/zabbix/zabbix-community-docker/tree/master/Dockerfile/zabbix-db-mariadb>

```sh
docker run \
  -d \
  --name zabbix-db \
  -p 3306:3306 \
  --env="MARIADB_USER=admin" \
  --env="MARIADB_PASS=password123" \
  --env="DB_innodb_buffer_pool_size=768M" \
  zabbix/zabbix-db-mariadb
```

Check if the container is running:

```sh
docker ps
```

You should see something like this:

```
$ docker ps
CONTAINER ID        IMAGE                      COMMAND             CREATED             STATUS              PORTS                    NAMES
8dbd73b6c50a        zabbix/zabbix-db-mariadb   "/run.sh"           37 minutes ago      Up 37 minutes       0.0.0.0:3306->3306/tcp   zabbix-db
```

## Start Zabbix

```sh
docker run \
  -d \
  --link zabbix-db:zabbix-db \
  --name zabbix \
  -p 80:80 \
  -p 10051:10051 \
  --env="ZS_DBHost=zabbix-db" \
  --env="ZS_DBUser=admin" \
  --env="ZS_DBPassword=password123" \
  zabbix/zabbix-2.4
```

## That's all folks...

Well, thats all you have to do to start a real basic Zabbix deploy, now you can login on: <http://localhost/>, and remember, for extra info [LINK](https://github.com/zabbix/zabbix-community-docker/tree/master/Dockerfile/zabbix-2.4)


## Compose
Finally, you may say, these are too many steps!, no problem, try docker-compose, with this great tools you can get an up and running environment in just one command!, but how?, simple:

Create a file docker-compose.yml with:

```yaml
zabbix-db-storage:
  image: busybox:latest
  volumes:
    - /var/lib/mysql

zabbix-db:
  image: zabbix/zabbix-db-mariadb
  volumes:
    - /backups:/backups
  volumes_from:
    - zabbix-db-storage
  environment:
    - MARIADB_USER=zabbix
    - MARIADB_PASS=my_password

zabbix-server:
  image: zabbix/zabbix-2.4
  ports:
    - "80:80"
    - "10051:10051"
  links:
    - zabbix-db:zabbix.db
  environment:
    - ZS_DBHost=zabbix.db
    - ZS_DBUser=zabbix
    - ZS_DBPassword=my_password
```

and:

```sh
docker-compose up -d
```
