#!/bin/bash

# Update gravatar
echo downloading gravatar img...
./gravatar.sh ssebbass@gmail.com

# building site
echo building site...
jekyll build

# Push to s3
echo pushing to s3...
aws --profile ssebbass s3 sync ./_site/ s3://www.ssebbass.com --delete
