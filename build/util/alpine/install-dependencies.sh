#!/bin/sh
set -e
apk update && apk add curl bash unzip jq && rm -f /var/cache/apk/*