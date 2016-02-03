#!/bin/bash
set -e

# Grab email
EMAIL="$1"

# Size in pixels you want, must be less than 512
SIZE='256'
HASH=`echo -n $EMAIL | awk '{print tolower($0)}' | tr -d '\n ' | md5sum --text | tr -d '\- '`
URL="http://www.gravatar.com/avatar/$HASH?s=$SIZE&d=404"

# Alright, grab the file, store it.
curl -s $URL > gravatar.jpg

# Lets convert to png (use imagamagic pkg)
convert gravatar.jpg img/avatar-icon.png
rm -f gravatar.jpg
