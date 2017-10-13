#!/bin/bash
set -xe

# Update gravatar
echo downloading gravatar img...
./gravatar.sh ssebbass@gmail.com

# Build & Publish
bundle install
bundle exec jekyll build
PUBHASH=$(ipfs add -rq _site/ | tail -1 )
sed -i.bak 's/.*Value.*/\"Value\"\:\ \"\\"dnslink\=\/ipfs\/'$PUBHASH'\\"\"/' www.ssebbass.com-txt.json
ZONEID=$(aws route53 list-hosted-zones-by-name --dns-name ssebbass.com. --profile ssebbass | grep Id | tr -d \" | tr -d \, | awk -F \/ '{print $3}')
aws route53 change-resource-record-sets --hosted-zone-id $ZONEID --change-batch file://./www.ssebbass.com-txt.json --profile ssebbass
