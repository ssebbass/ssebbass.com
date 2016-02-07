---
layout: post
title: Minecraft Server and Dockerfile
comments: true
---


## Introduction

Well... I believe that everybody already knows [Minecraft](https://minecraft.net/), I'm not a really great fun of it, but my son really loves it, so I start to ask myself how to get a server up and running so we can play together, and of course we love Docker, so we are going to play with [Dockerfiles](https://docs.docker.com/engine/reference/builder/) and get our personal server image.
First step, was to do some research on [Minecraft servers](https://minecraft.net/download), and get some inspiration from [Docker Hub](https://hub.docker.com/), here you can find lots of [Minecraft server](https://hub.docker.com/search/?isAutomated=0&isOfficial=0&page=1&pullCount=0&q=minecraft&starCount=0) options, but also I was interested to do it by myself.


## Let's Do it!

So basically a Dockerfile it's the instructions set needed by docker to build an image, an image it's a set if files packed in layers, so for instance over a layer of Ubuntu, you can put a layer with Java, and over the layer of Java you can put a layer with Minecraft. 
Layer?, you may think this is to complicated, don't worry, this one of the greatest parts of Docker.

First let's take a look to my [Dockerfile](https://github.com/ssebbass/docker-minecraft/blob/master/Dockerfile):

{% highlight sh %}
{% github_sample /ssebbass/docker-minecraft/blob/master/Dockerfile %}
{% endhighlight %}

Lets take a deeper look over the sections:

- **FROM:** This is the very first layer of our image, over this layer we are going to build what we want.
- **MAINTAINER:** This is the responsable to mainteint this Dockerfile.
- **EXPOSE:** This is the service port we are going to expose outside the Docker conteiner.
- **RUN:** This command runs a set of instructions inside the layer, and in consecuence creates a new layer with the resoult (some sort of diff), in this case, we just want to make sure we are running and updated version of the base img.
- **COPY:** Here we are adding files to the container, this files have some instructions to run wen we start the container.
- **VOLUME:** This is the non volatil porcion of the container, please refer to docker doc to get a better understaning of this concept.
- **WORKDIR:** Where are we going to be working from now on.
- **CMD:** The command to run when we start the container.


### [run.sh](https://github.com/ssebbass/docker-minecraft/blob/master/run.sh)

In this file I will create the service user and launch the script that does all the magic.

{% highlight sh %}
{% github_sample /ssebbass/docker-minecraft/blob/master/run.sh %}
{% endhighlight %}


### [minecraft.sh](https://github.com/ssebbass/docker-minecraft/blob/master/minecraft.sh)

{% highlight sh %}
{% github_sample /ssebbass/docker-minecraft/blob/master/minecraft.sh %}
{% endhighlight %}

In this script I will try to:

1. Download Minecraft & Forge
2. Set the server.properties file
3. Take some env variables to populate service options
4. Install Minecraft & Forge
5. Start the service


## Put all this together

This is how your Dockerfile work directory should look:

```
.
├── Dockerfile
├── minecraft.sh
├── run.sh
└── server.properties
```

### Lets build the image:

```sh
$ docker build -t ssebbass/docker-minecraft .
```

Few seconds later you should get a working Minecraft Server Docker image:

```sh
$ docker images
REPOSITORY                  TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
ssebbass/docker-minecraft   latest              b96e10b6f2d2        8 seconds ago       329.6 MB
java                        jre                 5b5803cfdd21        5 days ago          310.5 MB

```

You may note that we have two images, one it's ours and the other it's the base image where we build our docker.


## Lets play minecraft

For some details on how to launch docker please refer to [RUN](https://docs.docker.com/engine/reference/run/), for some more details on how to use this image, please refer to my Docker Hub [REPO](https://hub.docker.com/r/ssebbass/docker-minecraft/).

```sh
docker run \
  -d \
  -p 25565:25565 \
  -v /home/ubuntu/minecraft:/srv \
  -e DIFFICULTY=2 \
  -e GRAVATAR="youmail@yourdomain.com" \
  -e OPS="admin1,admin2" \
  -e MOTD="Docker Minecraft!" \
  -e MAP="Some map file" \
  --name minecraft \
  -e EULA=true \
  -e MODE=false \
  --restart=always \
  ssebbass/docker-minecraft
```

Here you can see the log from the container:

```sh
docker logs \
  -f minecraft
```

You should see something like this:

```sh
$ docker ps
CONTAINER ID        IMAGE                       COMMAND             CREATED             STATUS              PORTS                      NAMES
b2b100fb6cb7        ssebbass/docker-minecraft   "/run.sh"           4 seconds ago       Up 2 seconds        0.0.0.0:25565->25565/tcp   minecraft
```

## HAVE FUN!

<script type="text/javascript" src="https://asciinema.org/a/35790.js" id="asciicast-35790" async></script>

