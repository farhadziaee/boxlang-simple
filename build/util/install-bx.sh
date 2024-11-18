#!/bin/bash

# Make sure errors (like curl failing, or unzip failing, or anything failing) fails the build
set -ex
printenv;

# Use our quick installer
cd /tmp
curl -fsSL https://downloads.ortussolutions.com/ortussolutions/boxlang/install-boxlang.sh -o install-boxlang.sh
chmod +x install-boxlang.sh
./install-boxlang.sh $BOXLANG_VERSION