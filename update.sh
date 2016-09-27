#!/bin/bash

# Update gravatar
echo downloading gravatar img...
./gravatar.sh ssebbass@gmail.com

# Build & Publish
jekyll build && ipfs name publish $(ipfs add -rq _site/ | tail -1 ) | tee publish
