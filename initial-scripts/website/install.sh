#!/bin/bash -xe
source /function.sh
TAGS=$1

docker login study4.azurecr.io -u study4 -p 5rSF1GXrle4v61EgV=FGjLfO70jEDZKS

ENV=`echo $TAGS | jq -r '.[] | select(.name == "env").value'`
SERVICE=`echo $TAGS | jq -r '.[] | select(.name == "service").value'`
VERSION=`echo $TAGS | jq -r '.[] | select(.name == "version").value'`
export VERSION=$VERSION

docker run -d --name website -p 80:80 -e ENV=$ENV -e VERSION=$VERSION study4.azurecr.io/$SERVICE:$VERSION