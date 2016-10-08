---
layout: post
title: IPFS Introduction.
comments: true
---

Hi, lets talk about IPFS.

# What is IPFS?

IPFS it's a decentralized peer-to-peer hypermedia protocol.
For details, I recommend you to take a look to [IPFS site](http://ipfs.io).

# What's good for?

Well, it's great to distribute content, actually almost any type of content.

# So, how can I use it?

I'll show you some basic use examples, from a simple file share to a little more complex site hosting example, all decentralized.

# Get the tool

First, we need the last ipfs build, for that, I recommend you to go to the IPFS [distribution site](https://dist.ipfs.io), or just:

```sh
VERSION="$(curl -s "https://dist.ipfs.io/go-ipfs/versions" | tail -1)"
curl -O "https://dist.ipfs.io/go-ipfs/${VERSION}/go-ipfs_${VERSION}_linux-amd64.tar.gz"
tar xvzf go-ipfs_${VERSION}_linux-amd64.tar.gz
cd go-ipfs && ./install.sh
```

# Initialize and start daemon

First we need to initialize our node, use:

```sh
ipfs init
```

Now start the daemon:

```sh
nohup ipfs daemon &
```

Now lets check if it's getting connected to the swarm?:

```sh
ipfs swarm peers
```

Nice, now you are on IPFS.

# Privacy

At the write time of this paper, there was no private swarm approach, so if you share anything, it's going to be world wide available.

# Lets share something.

```sh
ipfs add SOMEFILE
```

You will get something like this:

```
ipfs add 3759.mp4
added QmeqKnoyZu5UVpSrsPQNpNNveJHsiVFD3atiEhZx3ssoUC 3759.mp4
```

## How do I access the content?

Since we share a video file, would be nice if we try to play that file, well here are two ways (almost three) to play that file.

### Console

```sh
ipfs cat /ifs/QmeqKnoyZu5UVpSrsPQNpNNveJHsiVFD3atiEhZx3ssoUC | vlc -
```

### Local gateway

Point your browser to the [local gateway](http://localhost:8080/ipfs/QmeqKnoyZu5UVpSrsPQNpNNveJHsiVFD3atiEhZx3ssoUC).

### Third way

Why "almost"?, because it's the same from above, but using a public gateway like [ipfs.io](http://ipfs.io).
Simple point your browser to the public gateway like this [ipfs.io/ipfs/QmeqKnoyZu5UVpSrsPQNpNNveJHsiVFD3atiEhZx3ssoUC](http://ipfs.io/ipfs/QmeqKnoyZu5UVpSrsPQNpNNveJHsiVFD3atiEhZx3ssoUC).

## Lets share more!

Now what about sharing an entire directory structure?, sure, why not?!, let's share my site:

```sh
apt install git
git clone https://github.com/ssebbass/ssebbass.com.git
ipfs add -r ssebbass.com
```

Please, pay attention to the last line of the output log, that hash it's the one ho represents the root directory of our structure, so if we try to get that hash, what it's going to happen?.

```sh
ipfs get /ipfs/Qma4wUJKDeGXaw6iiFj5YtjZUWQCr7QUQuY9FpPzT97XAs
```

## Let's publish a site!

I guess, we have all we need to publish information to the internet, so if we generate an internet site structure, we should be able to get a website!.
For this I'm going to use [Jekyll](https://jekyllrb.com/), I love Jekyll, it's great to generate static sites.

```sh
cd ssebbass.com
apt install ruby ruby-dev build-essential zlib1g-dev
gem install bundler
bundle install
jekyll build
ipfs add -r _site
```

Point your browser to [LINK](http://ipfs.io/ipfs/QmYy4qocQutxLzZwfBFaP5PWVKGFBDNKY1xTA8kdWxAY7U). I know, it looks awful, that's because the broken links, but we will get there soon.

Very nice, but how can I publish a site, if I keep changing my address, that's where IPNS come handy.

## IPNS

Lets try this:

```sh
ipfs name publish /ipfs/QmYy4qocQutxLzZwfBFaP5PWVKGFBDNKY1xTA8kdWxAY7U
```

You would get an immutable IPNS address, let's try to load that address, try to open [LINK](http://ipfs.io/ipns/QmNcGS3cRfjrUkoUxdFRXLy5Q3Fok6cRfs8bFFHs1PtwCD)
The down side, about IPNS, it's that addresses has a live time, the default it's 24hs, after that the record goes dead.

## Using ipfs.io to publish a personal site.

[ipfs.io](http://ipfs.io) it's a IPFS gateway, so you would be able to get IPFS content through there, I'll show you a little trick to publish your personal static site.
For this example, I'll use my domain "ssebbass.com", first we need to know which IPs [ipfs.io](http://ipfs.io) it's using, for this:

```sh
dig ipfs.io +short
```

Then you have to create a record A that point to those IPs, like this:

```
dig www.ssebbass.com +short
104.236.76.40
104.236.176.52
104.236.151.122
104.236.179.241
162.243.248.213
128.199.219.111
178.62.61.185
178.62.158.247
```

And here come's the trick, lets create a TXT record that dnslink to an IPFS address, like this:

```
dig www.ssebbass.com TXT +short
"dnslink=/ipfs/QmYsUeSEQMvhna7SgoPeCVawFrkuZcZMJZwDMpNRyxj5g3"
```

That's all, now you can go to [www.ssebbass.com](http://www.ssebbass.com) and browse the content.
